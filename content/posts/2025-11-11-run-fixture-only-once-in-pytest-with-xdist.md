---
layout: post
title: "Run a pytest fixture only once when running with xdist"
comments: True
date: "2025-11-11"
description: "A python decorator which turns any regular yielding pytest fixture which is executed only once when run via xdist"
---

If you run [pytest](https://docs.pytest.org/en/stable/) tests 
with [pytest-xdist](https://pytest-xdist.readthedocs.io) 
you might have run into the issue  
that all needed fixtures are executed on all workers.
In some cases this breaks your tests because e.g. a 
[testcontainers setup](https://github.com/testcontainers/testcontainers-python)
wants to bind to a specific port.

The [pytest-xdist docs have a recipe to prevent that and run a session fixture only once per overall run](https://pytest-xdist.readthedocs.io/en/stable/how-to.html#making-session-scoped-fixtures-execute-only-once)
but this needs to be applied to every such fixture.

This is a decorator which can be applied to any (non-async) yielding fixture which returns a pydantic class
(pydantic class to have an easy (de-)serialization interface).
It needed a few tricks (`wrapt` +  a special `adapter`) to get pytest to accept it as a generator fixture.

The usage is essentially:

```python
import pydantic
import pytest
from whatever import xdist_run_only_once
class Something(pydantic.BaseModel):
    ...

@pytest.fixture(scope="session", name="something")
# Needed to make saving the returned value to disk on the first worker 
# and reading it in and returning it on other workers possible
@xdist_run_only_once(return_type=Something) 
def fixture_something() -> Iterator[Something]:
    """Something fixture."""
    # ... setup e.g. a DockerCompose kafka + schema registry setup with fixed ports
    yield Something(...)
    # ... cleanup
```

And here is the code for the `xdist_run_only_once` decorator. 
It's lightly tested (as in "it works on my machine for my use case").
As you can see by the debug code I left in, I found it tricky to debug. :-(


```python
import contextlib
import inspect
import json
import logging
import os
import pathlib
import time
from collections.abc import Callable, Iterator
from typing import Any, TypeVar

import pytest
import wrapt
from filelock import FileLock
from pydantic import BaseModel
from wrapt import formatargspec
from wrapt.decorators import exec_


def _get_file_writing_debugging_logger() -> logging.Logger:
    # create file handler which logs every message to the disc
    filename = "logs/pytest.log"
    pathlib.Path(filename).parent.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter("%(asctime)s - %(message)s")
    file_log_handler = logging.FileHandler(filename)
    file_log_handler.setLevel(logging.DEBUG)
    file_log_handler.setFormatter(formatter)
    logger.addHandler(file_log_handler)
    return logger


# If you need debug logging of the logic in this madness, change this to True and look into "logs/pytest.log"
if False:
    _logger = _get_file_writing_debugging_logger()
else:
    _logger = logging.getLogger(__name__)

RT = TypeVar("RT", bound=BaseModel)


def _additional_fixtures_protocol(tmp_path_factory: pytest.TempPathFactory):  # type: ignore[no-untyped-def]  # noqa: ANN202
    """Protocol to get access to the tmp_path_factory arg spec."""


def combine_args_with_protocol_adapter_factory(wrapped: Callable[..., Any]) -> Callable[..., Any]:
    """Adjust the signature of the wrapped functions with additional arguments from the protocol."""
    # At this point, we know that the wrapped function is a fixture, so should only contain args.
    # We also know that the protocol only contains args

    argspec_wrapped = inspect.getfullargspec(wrapped)
    argspec_protocol = inspect.getfullargspec(_additional_fixtures_protocol)
    combined_args = argspec_wrapped.args[:] + argspec_protocol.args[:]

    adapter_spec = formatargspec(
        args=combined_args,
        varkw=argspec_wrapped.varkw,
        defaults=argspec_wrapped.defaults,
        kwonlyargs=argspec_wrapped.kwonlyargs,
        kwonlydefaults=argspec_wrapped.kwonlydefaults,
        varargs=argspec_wrapped.varargs,
        # No annotations, it would fail to compile
    )
    # the current wrapt produces a normal function, no yielding generator,
    # so we have to create one here ourselves with exec :-(
    # We need it because pytest uses inspect.isgeneratorfunction() to decide between generator
    # fixtures and fixtures with return and if we would have a return function, it would never get the
    # data out of the generator :-(
    ns: dict[str, Any] = {}
    exec_(f"def adapter{adapter_spec}: yield", ns, ns)
    adapter = ns["adapter"]
    # We prefer the annotations from the wrapped function, including the annotation for the return type
    annotations = argspec_protocol.annotations.copy()
    annotations.update(argspec_wrapped.annotations.copy())
    adapter.__annotations__ = annotations
    return adapter


# Decorator modeled after
# https://pytest-xdist.readthedocs.io/en/latest/how-to.html#making-session-scoped-fixtures-execute-only-once
def xdist_run_only_once(  # noqa: PLR0915
    *, return_type: type[RT]
) -> Callable[[Callable[..., Iterator[RT]]], Callable[[pytest.TempPathFactory, str], Iterator[RT]]]:
    """Call a fixture only once despite xdist."""
    worker_id = os.environ.get("PYTEST_XDIST_WORKER", "master")
    if worker_id == "master":
        # not executing with multiple workers or without xdist
        # -> just make the decorator return the original functions
        return lambda x: x

    @wrapt.decorator(adapter=wrapt.adapter_factory(combine_args_with_protocol_adapter_factory))
    def adapted(  # type: ignore[no-untyped-def]  # noqa: PLR0915
        wrapped: Callable[..., Iterator[RT]],
        instance,  # noqa: ANN001
        # One of these already contains the new arguments from the protocol
        args,  # noqa: ANN001
        kwargs,  # noqa: ANN001
    ) -> Iterator[RT]:
        """Inner fixture with the interface of the combined arguments of the original fixture + the protocol."""
        lock_name = f"{wrapped.__module__}.{wrapped.__name__}"

        def _d(msg: str, *args: Any) -> None:  # noqa: ANN401
            worker_id = os.environ["PYTEST_XDIST_WORKER"]
            fixture_name = f"{wrapped.__name__}"
            full_msg = "[%s, %s] " + msg
            _logger.debug(full_msg, worker_id, fixture_name, *args)

        # The _executer function is a shorter way to pull out the named arguments from args/kwargs
        # no matter if these are in args or kwargs
        def _executer(  # type: ignore[no-untyped-def] # noqa: PLR0915
            tmp_path_factory: pytest.TempPathFactory,
            *_args,  # noqa: ANN002
            **_kwargs,  # noqa: ANN003
        ) -> Iterator[RT]:
            running_fixture: Iterator[Any] | None = None
            # get the temp directory shared by all workers
            # getbasetemp() is a worker specific directory under xdist, so go one down to get the shared one
            root_tmp_dir = tmp_path_factory.getbasetemp().parent

            lock_file = root_tmp_dir / f"{lock_name}.lock"
            info_file = root_tmp_dir / f"{lock_name}.json"
            worker_file = root_tmp_dir / f"{lock_name}.workers"

            def _load_worker_list() -> list[str]:
                if not worker_file.is_file():
                    return []
                return sorted(json.loads(worker_file.read_text())["workers"])

            def _write_worker_list(workers: list[str]) -> None:
                worker_file.write_text(json.dumps({"workers": workers}))

            def _add_worker() -> None:
                worker_id = os.environ["PYTEST_XDIST_WORKER"]
                with FileLock(str(lock_file)):
                    workers = _load_worker_list()
                    _d("Adding myself to workers: %s", workers)
                    workers.append(worker_id)
                    _d("List of worker after adding myself to workers: %s", workers)
                    _write_worker_list(workers)

            def _remove_worker() -> None:
                worker_id = os.environ["PYTEST_XDIST_WORKER"]
                with FileLock(str(lock_file)):
                    workers = _load_worker_list()
                    _d("Removing myself from workers: %s", workers)
                    try:
                        workers.remove(worker_id)
                    except ValueError:
                        _d("Could not remove myself from workers: %s", workers)
                    _d("List of workers after removal: %s", workers)

                    _write_worker_list(workers)

            with FileLock(str(lock_file)):
                if info_file.is_file():
                    _d("Info is there, reading it")
                    data = return_type.model_validate_json(info_file.read_text())
                else:
                    # The first one actually creates it
                    running_fixture = wrapped(*_args, **_kwargs)
                    _d("[MAIN] Before executing actual fixture")
                    data = next(running_fixture)
                    _d("[MAIN] After executing actual fixture")
                    info_file.write_text(data.model_dump_json())
                    _d("[MAIN] After writing info")

            _add_worker()
            # Only yield when out of the locks!
            _d("Before yielding inner")
            yield data
            _d("After yielding inner")
            _remove_worker()

            # We have nothing to do anymore, shut down any resources, but only if
            # - we created them and
            # - only after we are the last worker

            if running_fixture is None:
                _d("Not the initial fixture executor, finishing a secondary worker")
                return

            start = time.monotonic()
            timeout = 20 * 60  # 20 min
            # Wait for workers to become empty as other worker shut down
            while start + timeout > time.monotonic():
                with FileLock(str(lock_file)):
                    workers = _load_worker_list()
                    _d("[MAIN] Got this during waiting: %s", workers)
                if len(workers) == 0:
                    break
                _d("[MAIN] Still waiting to drain the list of worker")
                time.sleep(1)
            # And now we are the last and can run the fixture clean up and then our own cleanup
            _d("[MAIN] List of workers are empty")
            with FileLock(str(lock_file)):
                # We expect that ends with a raised StopIteration
                # BUT we have to return normally as otherwise this gets turned into a RuntimeError
                with contextlib.suppress(StopIteration):
                    _d("[MAIN] Before running fixture cleanup")
                    next(running_fixture)
                    _d("[MAIN] After running fixture cleanup")
                _d("[MAIN] Removing worker file")
                worker_file.unlink(missing_ok=True)
                _d("[MAIN] Removing info file")
                info_file.unlink(missing_ok=True)
            _d("[MAIN] Finished fixture running worker")

        _d("Before outer fixture execution")
        yield from _executer(*args, **kwargs)
        _d("After outer fixture execution")

    return adapted
```

