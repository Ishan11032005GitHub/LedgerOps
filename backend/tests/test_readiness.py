from app.config import Settings
from app.services.readiness import deployment_readiness


class Inspector:
    def get_table_names(self):
        return ["alembic_version"]


def test_live_readiness_fails_closed_without_payment_and_compliance(monkeypatch):
    monkeypatch.setattr("app.services.readiness.inspect", lambda _engine: Inspector())
    settings = Settings(
        _env_file=None,
        environment="production",
        demo_only=False,
        database_url="postgresql+psycopg://example",
        jwt_secret="x" * 40,
        frontend_url="https://app.example.com",
        cors_origins="https://app.example.com",
        smtp_host="smtp.example.com",
        smtp_from_email="security@example.com",
        gemini_api_key="configured",
    )
    report = deployment_readiness(settings, object())
    assert report["ready"] is False
    assert {"processor_key", "signed_webhook", "compliance"}.issubset(
        {item["name"] for item in report["blocking"]}
    )


def test_demo_readiness_does_not_require_live_processor(monkeypatch):
    monkeypatch.setattr("app.services.readiness.inspect", lambda _engine: Inspector())
    settings = Settings(
        _env_file=None,
        environment="production",
        demo_only=True,
        database_url="postgresql+psycopg://example",
        jwt_secret="x" * 40,
        frontend_url="https://demo.example.com",
        cors_origins="https://demo.example.com",
    )
    report = deployment_readiness(settings, object())
    assert report["ready"] is True
