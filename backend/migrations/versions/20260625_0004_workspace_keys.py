"""Add opaque workspace membership keys.

Revision ID: 20260625_0004
Revises: 20260625_0003
"""
import hashlib

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect, text


revision = "20260625_0004"
down_revision = "20260625_0003"
branch_labels = None
depends_on = None


def _workspace_key(account_type: str | None, workspace_name: str | None, user_id: int) -> str:
    if account_type == "company" and workspace_name:
        source = f"company:{workspace_name.strip().casefold()}"
    else:
        source = f"user:{user_id}"
    return hashlib.sha256(source.encode()).hexdigest()[:48]


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    columns = {column["name"] for column in inspector.get_columns("users")}
    added_column = "workspace_key" not in columns
    if added_column:
        op.add_column("users", sa.Column("workspace_key", sa.String(length=64), nullable=True))
    rows = bind.execute(text("SELECT id, account_type, workspace_name, workspace_key FROM users")).mappings()
    for row in rows:
        if not row["workspace_key"]:
            bind.execute(
                text("UPDATE users SET workspace_key = :workspace_key WHERE id = :user_id"),
                {"workspace_key": _workspace_key(row["account_type"], row["workspace_name"], row["id"]), "user_id": row["id"]},
            )
    indexes = {index["name"] for index in inspect(bind).get_indexes("users")}
    if added_column:
        with op.batch_alter_table("users") as batch:
            batch.alter_column("workspace_key", existing_type=sa.String(length=64), nullable=False)
    if "ix_users_workspace_key" not in indexes:
        op.create_index("ix_users_workspace_key", "users", ["workspace_key"], unique=False)


def downgrade() -> None:
    with op.batch_alter_table("users") as batch:
        batch.drop_index("ix_users_workspace_key")
        batch.drop_column("workspace_key")
