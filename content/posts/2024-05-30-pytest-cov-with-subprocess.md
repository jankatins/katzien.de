---
layout: post
title: "Measuring coverage of a python script run as subprocess"
comments: True
date: "2024-05-30"
description: "Lessons learned when trying to run a server process as a subprocess under coverage."
---

In a pytest I wanted to run a server process in a subprocess within a pytest fixture and then run tests against it. For
me that seemed the best way that nothing interferes with the server process. The setup worked nicely until I wanted to
measure coverage: my server script came out with no overage at all.

I use [pytest-cov](https://pytest-cov.readthedocs.io/en/latest/) for coverage collection. pytest-cov actually states
that it works with subprocess out of the box:

> pytest-cov supports subprocesses and multiprocessing, and works around these atexit limitations. However, there are a
> few pitfalls that need to be explained.

Measuring coverage of a subprocess via [coverage.py](https://coverage.readthedocs.io/en/latest/index.html) (what
pytest-cov uses under the hood) is actually not that easy: you somehow have to make
the [python process start up the coverage collection](https://coverage.readthedocs.io/en/latest/subprocess.html).
pytest-cov does that by installing
a [`pytest-cov.pth`](https://github.com/pytest-dev/pytest-cov/blob/master/src/pytest-cov.pth) file in the root
site-packages dir when the wheel is installed. That code will run on every python startup but will only start up the
coverage collection if the `COV_CORE_SOURCE` env var is set (and probably uses a few more env vars to set everything up
correctly).

In addition, you need to run it with `parallel=true` to get all process to write their coverage information into
separate files. You then have to combine them and run the report on that combined file. Thankfully, pytest-cov will do
that automatically for you.

## Make sure that you pass all `COV_*` env vars to the subprocess

I was starting the subprocess with

```python
process = subprocess.Popen(
    command,
    cwd=working_directory,
    text=False,
    env=get_command_env(),
)
```

And in my case, the `get_command_env()` was returning a dict with only the business logic relevant env vars and this
prevented the `pytest-cov` code to actually start the collector.

```python
env = dict(get_command_env())
for env_var, env_value in os.environ.items():
    if env_var.startswith("COV") and env_var not in env:
        _logger.info("Adding %s=%s to environ", env_var, env_value)
        env[env_var] = env_value

process = subprocess.Popen(
    command,
    cwd=working_directory,
    env=env,
)
```

## The collector must be able to write coverage information during shutdown

coverage.py and/or pytest-cov writes the collected coverage information into a file when the python process is shutting
down (usually via an atexit handler).

I was using `process.kill()` to shut down the server process at the end of the fixture. This sends `SIGKILL` and will
kill the process instantly without giving it time to write out the coverage information.

I ended up with something like this to give the collector a chance to write the information:

```python
# Needs to send SIGTERM first to enable writing coverage information
process.terminate()
try:
    process.wait(timeout=1.0)
except subprocess.TimeoutExpired:
    # Only kill if the child has not terminated by itself.
    process.kill()
```

## Configuring via pyproject.toml

It seems coverage.py and/or pytest-cov only install an atexit handler which does not get called when the python process
receives a `SIGTERM` (and you have installed another signal handler, which was the case due to external frameworks):

> The functions registered via this module are not called when the program is killed by a signal not handled by Python
> ([atexit docs](https://docs.python.org/3/library/atexit.html))

So if you kill your server process, you also need to add a signal handler:

```toml
# pyproject.toml
[tool.coverage.run]
# Needed to get coverage information from subprocesses;
sigterm = true
# parallel = true is also automatically set by pytest-cov when calling coverage.py
```

Without this, I didn't get coverage information from the subprocess. On the other hand, I would have expected that
pytest-cov would have set this if it was needed, same as `parallel=true` or actually install its own signal handler
the `pytest-cov.pth`. Not sure what's going on here, yet...

I also ended up passing the config file to the pytest call, as the default seems to `.coveragerc`:

```shell
pytest --cov=module_name --cov-config=pyproject.toml ... tests/
```

With this in place, I finally had my 95% coverage for the server process :-)

So to summ it up:

- pytest-cov relies on passing env vars to the subprocess to start the coverage collection (there is a `pytest-cov.pth`
  file installed via pytest-cov wheel which is run on every python start which inits the collector but ONLY when the env
  vars are present). So you have to make sure that these env vars are actually passed in to the subprocess, and not only
  the env vars your business logic relies on...
- A python process must be able to write the coverage results before ending (happens via an atexit/signal handler), so
  do not `SIGKILL` the process at the end of the fixture...
- You have to configure coverage.py to install a sigterm handler: `sigterm = true` (not sure why this is needed, I would
  have expected pytest-cov to take care of this)
- If you configure coverage.py via `pyproject.toml`, you actually have to pass that config file name as a pytest argument:
  `--cov-config=pyproject.toml`
