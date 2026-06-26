import os
from pathlib import Path


TEST_DB = Path(__file__).parent / "ledgerops-test.db"
os.environ["DATABASE_URL"] = f"sqlite+pysqlite:///{TEST_DB.as_posix()}"
os.environ["REDIS_URL"] = "redis://localhost:6399/15"
os.environ["DEMO_ONLY"] = "true"
os.environ["PAYMENT_PROVIDER_MODE"] = "demo"
os.environ["JWT_SECRET"] = "test-secret-that-is-long-enough-for-tests"


def pytest_sessionfinish(session, exitstatus):
    if TEST_DB.exists():
        TEST_DB.unlink()
