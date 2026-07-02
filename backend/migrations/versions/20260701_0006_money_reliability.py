"""Money movement reliability constraints.

Revision ID: 20260701_0006
Revises: 20260625_0005
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect, text


revision = "20260701_0006"
down_revision = "20260625_0005"
branch_labels = None
depends_on = None


def _constraint_exists(inspector, table: str, name: str) -> bool:
    return any(constraint.get("name") == name for constraint in inspector.get_unique_constraints(table))


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)

    event_columns = {column["name"] for column in inspector.get_columns("event_logs")}
    if "external_id" not in event_columns:
        op.add_column("event_logs", sa.Column("external_id", sa.String(length=160), nullable=True))
    bind.execute(
        text(
            """
            UPDATE event_logs
            SET external_id = payload ->> 'stripe_event_id'
            WHERE external_id IS NULL
              AND payload ? 'stripe_event_id'
              AND payload ->> 'stripe_event_id' IS NOT NULL
            """
        )
    )
    bind.execute(
        text(
            """
            WITH ranked AS (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY external_id ORDER BY id) AS rn
                FROM event_logs
                WHERE external_id IS NOT NULL
            )
            UPDATE event_logs
            SET external_id = NULL
            WHERE id IN (SELECT id FROM ranked WHERE rn > 1)
            """
        )
    )
    indexes = {index["name"] for index in inspect(bind).get_indexes("event_logs")}
    if "ix_event_logs_external_id" not in indexes:
        op.create_index("ix_event_logs_external_id", "event_logs", ["external_id"], unique=False)
    if not _constraint_exists(inspect(bind), "event_logs", "uq_event_logs_external_id"):
        op.create_unique_constraint("uq_event_logs_external_id", "event_logs", ["external_id"])

    # Keep only one non-null QuickLink per processor checkout session before adding the constraint.
    bind.execute(
        text(
            """
            UPDATE quick_links
            SET checkout_id = NULL
            WHERE id NOT IN (
                SELECT MIN(id)
                FROM quick_links
                WHERE checkout_id IS NOT NULL
                GROUP BY checkout_id
            )
            AND checkout_id IS NOT NULL
            """
        )
    )
    if not _constraint_exists(inspect(bind), "quick_links", "uq_quick_links_checkout_id"):
        op.create_unique_constraint("uq_quick_links_checkout_id", "quick_links", ["checkout_id"])


def downgrade() -> None:
    inspector = inspect(op.get_bind())
    if _constraint_exists(inspector, "quick_links", "uq_quick_links_checkout_id"):
        op.drop_constraint("uq_quick_links_checkout_id", "quick_links", type_="unique")
    if _constraint_exists(inspector, "event_logs", "uq_event_logs_external_id"):
        op.drop_constraint("uq_event_logs_external_id", "event_logs", type_="unique")
    indexes = {index["name"] for index in inspect(op.get_bind()).get_indexes("event_logs")}
    if "ix_event_logs_external_id" in indexes:
        op.drop_index("ix_event_logs_external_id", table_name="event_logs")
    columns = {column["name"] for column in inspect(op.get_bind()).get_columns("event_logs")}
    if "external_id" in columns:
        op.drop_column("event_logs", "external_id")
