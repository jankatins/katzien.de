---
layout: post
title: "Create missing (postgresql) schemas in alembic / sqlalchemy"
comments: True
date: "2023-11-16"
description: "Adding migrations for creating (and dropping) postgresql schemas."
---

At work, we generate a bunch of files with sqlalchemy classes in them. One of the problems is
that `alembic revision --autogenerate` does not generate schemas and therefore one needs to manually add schemas
for them. There are [workarounds](https://stackoverflow.com/a/70571077/1380673), but these always add the DDL to each
new migration and one either has to clean it up or live with the (unneeded) DDL code. This is a solutions which actually
looks at the already existing schemas and compares it with the schemas used in create table operations:

```python
import logging
from collections.abc import Iterable
from typing import Any

import alembic
import sqlalchemy.sql.base
from alembic.autogenerate.api import AutogenContext
from alembic.operations.ops import (
    CreateTableOp,
    ExecuteSQLOp,
    UpgradeOps,
)

_logger = logging.getLogger(f"alembic.{__name__}")


class ExecuteArbitraryDDLOp(ExecuteSQLOp):
    def __init__(
        self,
        ddl: sqlalchemy.sql.base.Executable | str,
        reverse_ddl: sqlalchemy.sql.base.Executable | str,
        *,
        execution_options: dict[str, Any] | None = None,
    ) -> None:
        """A DDL Operation with both upgrade and downgrade commands."""
        super().__init__(ddl, execution_options=execution_options)
        self.reverse_ddl = reverse_ddl

    def reverse(self) -> "ExecuteArbitraryDDLOp":
        """Return the reverse of this ArbitraryDDL operation (used for downgrades)."""
        return ExecuteArbitraryDDLOp(
            ddl=self.reverse_ddl, reverse_ddl=self.sqltext, execution_options=self.execution_options
        )


@alembic.autogenerate.comparators.dispatch_for("schema")
def create_missing_schemas(
    autogen_context: AutogenContext, upgrade_ops: UpgradeOps, schema_names: Iterable[str | None]
) -> None:
    """Creates missing schemas.

    This depends on sqla/alembic to give us all existing
    schemas in the schema_names argument.
    """
    used_schemas = set()
    for operations_group in upgrade_ops.ops:
        # We only care about Tables at the top level, so this is enough for us.
        if isinstance(operations_group, CreateTableOp) and operations_group.schema:
            used_schemas.add(operations_group.schema)

    existing_schemas = set(schema_names)
    missing_schemas = used_schemas - existing_schemas
    if missing_schemas:
        for schema in missing_schemas:
            _logger.info("Add migration ops for schema: %s", schema)
            upgrade_ops.ops.insert(
                0,
                ExecuteArbitraryDDLOp(
                    ddl=f"CREATE SCHEMA {schema}",
                    reverse_ddl=f"DROP SCHEMA {schema}",
                ),
            )
```

Here are the calls for a very simply test sqlalchemy model:

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, MappedAsDataclass, mapped_column
from sqlalchemy.sql.schema import MetaData
from sqlalchemy.sql.sqltypes import DateTime, Enum, Text


class Base(MappedAsDataclass, DeclarativeBase):
    metadata = MetaData(schema="whatever")


class Test(Base):
    """Test table."""

    __tablename__ = "test"

    test_id: Mapped[str] = mapped_column(
        Text,
        primary_key=True,
        comment="Primary key",
    )
```

The resulting `alembic` call:

```shell
λ  alembic revision --autogenerate -m "test"
INFO  [alembic] Using pure env
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.autogenerate.compare] Detected added table 'whatever.test'
INFO  [alembic] Add migration ops for schema: whatever
  Generating /Users/jankatins/projects/project_name/alembic/versions/0006_test.py ...  done

```

And the resulting migration file (with some comments and docstring removed):

```python
"""test."""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '0006'
down_revision = '0005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute('CREATE SCHEMA whatever')
    op.create_table('test',
                    sa.Column('test_id', sa.Text(), nullable=False, comment='Primary key'),
                    sa.PrimaryKeyConstraint('test_id'),
                    schema='whatever'
                    )


def downgrade() -> None:
    op.drop_table('test', schema='whatever')
    op.execute('DROP SCHEMA whatever')
```

Anything to improve here? Leave a comment!
