"""Scope invoice numbers to a workspace.

Revision ID: 20260625_0005
Revises: 20260625_0004
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect, text


revision = "20260625_0005"
down_revision = "20260625_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    columns = {column["name"] for column in inspector.get_columns("invoices")}
    if "workspace_key" not in columns:
        op.add_column("invoices", sa.Column("workspace_key", sa.String(length=64), nullable=True))
    bind.execute(
        text(
            """
            UPDATE invoices
            SET workspace_key = (
                SELECT users.workspace_key FROM users WHERE users.id = invoices.user_id
            )
            WHERE workspace_key IS NULL
            """
        )
    )
    bind.execute(text("UPDATE invoices SET workspace_key = 'legacy-unassigned' WHERE workspace_key IS NULL"))

    inspector = inspect(bind)
    unique_constraints = inspector.get_unique_constraints("invoices")
    target_exists = any(
        constraint.get("name") == "uq_invoices_workspace_number"
        for constraint in unique_constraints
    )
    with op.batch_alter_table("invoices") as batch:
        for constraint in unique_constraints:
            if constraint.get("name") and constraint.get("column_names") == ["invoice_number"]:
                batch.drop_constraint(constraint["name"], type_="unique")
        batch.alter_column("workspace_key", existing_type=sa.String(length=64), nullable=False)
        if not target_exists:
            batch.create_unique_constraint("uq_invoices_workspace_number", ["workspace_key", "invoice_number"])

    indexes = {index["name"] for index in inspect(bind).get_indexes("invoices")}
    if "ix_invoices_workspace_key" not in indexes:
        op.create_index("ix_invoices_workspace_key", "invoices", ["workspace_key"], unique=False)


def downgrade() -> None:
    with op.batch_alter_table("invoices") as batch:
        batch.drop_constraint("uq_invoices_workspace_number", type_="unique")
        batch.drop_index("ix_invoices_workspace_key")
        batch.drop_column("workspace_key")
