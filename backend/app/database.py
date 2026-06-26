from collections.abc import Generator
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from .config import get_settings


class Base(DeclarativeBase):
    pass


settings = get_settings()
engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


ACCOUNT_SCOPED_TABLES = [
    "customers",
    "invoices",
    "payments",
    "transactions",
    "alerts",
    "predictions",
    "compliance_checks",
    "event_logs",
    "quick_links",
    "refunds",
    "reconciliation_runs",
    "audit_logs",
]


def migrate_account_columns() -> None:
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    with engine.begin() as connection:
        if "users" in existing_tables:
            user_columns = {column["name"] for column in inspector.get_columns("users")}
            if "account_type" not in user_columns:
                connection.execute(text("ALTER TABLE users ADD COLUMN account_type VARCHAR(30) DEFAULT 'company'"))
            if "workspace_name" not in user_columns:
                connection.execute(text("ALTER TABLE users ADD COLUMN workspace_name VARCHAR(160)"))
            connection.execute(text("UPDATE users SET account_type = 'company' WHERE account_type IS NULL"))
            connection.execute(text("UPDATE users SET workspace_name = 'LedgerOps workspace' WHERE workspace_name IS NULL AND email LIKE '%@ledgerops.ai'"))

        for table in ACCOUNT_SCOPED_TABLES:
            if table not in existing_tables:
                continue
            columns = {column["name"] for column in inspector.get_columns(table)}
            if "user_id" not in columns:
                connection.execute(text(f"ALTER TABLE {table} ADD COLUMN user_id INTEGER"))

        admin_id = connection.execute(text("SELECT id FROM users WHERE email = 'admin@ledgerops.ai'")).scalar()
        if admin_id:
            for table in ACCOUNT_SCOPED_TABLES:
                if table in existing_tables:
                    connection.execute(text(f"UPDATE {table} SET user_id = :user_id WHERE user_id IS NULL"), {"user_id": admin_id})
