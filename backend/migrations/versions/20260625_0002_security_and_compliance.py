"""Security sessions and QuickLink payer country.

Revision ID: 20260625_0002
Revises: 20260625_0001
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
from app.database import Base
from app import models  # noqa: F401


revision = "20260625_0002"
down_revision = "20260625_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    existing = set(inspector.get_table_names())
    for name in {"auth_sessions", "refunds", "reconciliation_runs", "audit_logs"}:
        if name not in existing:
            Base.metadata.tables[name].create(bind=bind, checkfirst=True)
    if "quick_links" in existing:
        columns = {column["name"] for column in inspector.get_columns("quick_links")}
        if "payer_country" not in columns:
            op.add_column("quick_links", sa.Column("payer_country", sa.String(length=2), nullable=True))
    if "users" in existing:
        user_columns = {column["name"] for column in inspector.get_columns("users")}
        if "account_type" not in user_columns:
            op.add_column("users", sa.Column("account_type", sa.String(length=30), nullable=True, server_default="company"))
        if "workspace_name" not in user_columns:
            op.add_column("users", sa.Column("workspace_name", sa.String(length=160), nullable=True))
    for name in ["customers", "invoices", "payments", "transactions", "alerts", "predictions", "compliance_checks", "event_logs"]:
        if name in existing:
            columns = {column["name"] for column in inspector.get_columns(name)}
            if "user_id" not in columns:
                op.add_column(name, sa.Column("user_id", sa.Integer(), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    if "quick_links" in inspector.get_table_names():
        columns = {column["name"] for column in inspector.get_columns("quick_links")}
        if "payer_country" in columns:
            op.drop_column("quick_links", "payer_country")
    for name in ["audit_logs", "reconciliation_runs", "refunds", "auth_sessions"]:
        Base.metadata.tables[name].drop(bind=bind, checkfirst=True)
