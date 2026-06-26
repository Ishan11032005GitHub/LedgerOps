"""Email verification and MFA.

Revision ID: 20260625_0003
Revises: 20260625_0002
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
from app.database import Base
from app import models  # noqa: F401


revision = "20260625_0003"
down_revision = "20260625_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    existing = set(inspector.get_table_names())
    if "email_verification_tokens" not in existing:
        Base.metadata.tables["email_verification_tokens"].create(bind=bind, checkfirst=True)
    columns = {column["name"] for column in inspector.get_columns("users")}
    if "email_verified" not in columns:
        op.add_column("users", sa.Column("email_verified", sa.Boolean(), nullable=False, server_default=sa.false()))
    if "mfa_enabled" not in columns:
        op.add_column("users", sa.Column("mfa_enabled", sa.Boolean(), nullable=False, server_default=sa.false()))
    if "mfa_secret" not in columns:
        op.add_column("users", sa.Column("mfa_secret", sa.String(length=64), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "mfa_secret")
    op.drop_column("users", "mfa_enabled")
    op.drop_column("users", "email_verified")
    Base.metadata.tables["email_verification_tokens"].drop(bind=op.get_bind(), checkfirst=True)
