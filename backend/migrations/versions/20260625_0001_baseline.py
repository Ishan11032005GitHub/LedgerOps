"""LedgerOps production schema baseline.

Revision ID: 20260625_0001
Revises:
Create Date: 2026-06-25
"""
from alembic import op
from sqlalchemy import inspect
from app.database import Base
from app import models  # noqa: F401


revision = "20260625_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())
    for table in Base.metadata.sorted_tables:
        if table.name not in existing:
            table.create(bind=bind, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    for table in reversed(Base.metadata.sorted_tables):
        table.drop(bind=bind, checkfirst=True)
