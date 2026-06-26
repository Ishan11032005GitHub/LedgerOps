from dataclasses import dataclass
from urllib.parse import urlparse

from sqlalchemy import inspect

from ..config import Settings


@dataclass
class ReadinessCheck:
    name: str
    ok: bool
    detail: str
    required_for: str

    def as_dict(self) -> dict:
        return {
            "name": self.name,
            "ok": self.ok,
            "detail": self.detail,
            "required_for": self.required_for,
        }


def _https(url: str) -> bool:
    return urlparse(url).scheme == "https"


def deployment_readiness(settings: Settings, engine) -> dict:
    checks = [
        ReadinessCheck(
            "database",
            settings.database_url.startswith(("postgresql://", "postgresql+psycopg://")),
            "Managed PostgreSQL configured" if settings.database_url.startswith(("postgresql://", "postgresql+psycopg://")) else "Use PostgreSQL outside tests",
            "staging",
        ),
        ReadinessCheck(
            "jwt_secret",
            len(settings.jwt_secret) >= 32 and settings.jwt_secret not in {"dev-secret", "local-dev-change-me", "change-me-in-production"},
            "Strong JWT signing secret configured" if len(settings.jwt_secret) >= 32 else "JWT_SECRET must be at least 32 characters",
            "staging",
        ),
        ReadinessCheck(
            "frontend_https",
            settings.environment != "production" or _https(settings.frontend_url),
            "HTTPS frontend configured" if _https(settings.frontend_url) else "Production FRONTEND_URL must use HTTPS",
            "production",
        ),
        ReadinessCheck(
            "cors",
            settings.environment != "production" or all(_https(origin) for origin in settings.origins),
            "Explicit HTTPS origins configured" if settings.origins and all(_https(origin) for origin in settings.origins) else "Production CORS origins must be explicit HTTPS URLs",
            "production",
        ),
        ReadinessCheck(
            "password_reset",
            settings.demo_only or bool(settings.smtp_host and settings.smtp_from_email),
            "Recovery email configured" if settings.smtp_host and settings.smtp_from_email else "SMTP is required for non-demo accounts",
            "production",
        ),
        ReadinessCheck(
            "gemini",
            settings.demo_only or bool(settings.active_gemini_key),
            "Gemini key configured" if settings.active_gemini_key else "GEMINI_API_KEY is required for the live Copilot",
            "production",
        ),
    ]

    if not settings.demo_only:
        checks.extend(
            [
                ReadinessCheck(
                    "processor_key",
                    settings.stripe_secret_key.startswith("sk_live_"),
                    "Live processor key configured" if settings.stripe_secret_key.startswith("sk_live_") else "A live processor key is required",
                    "live_money",
                ),
                ReadinessCheck(
                    "signed_webhook",
                    settings.stripe_webhook_secret.startswith("whsec_"),
                    "Signed webhook configured" if settings.stripe_webhook_secret.startswith("whsec_") else "A signed webhook secret is required",
                    "live_money",
                ),
                ReadinessCheck(
                    "compliance",
                    settings.compliance_provider == "http" and bool(settings.compliance_provider_url),
                    "Compliance screening adapter configured" if settings.compliance_provider == "http" and settings.compliance_provider_url else "Configure the HTTP KYC/AML screening adapter",
                    "live_money",
                ),
            ]
        )

    try:
        tables = set(inspect(engine).get_table_names())
        migration_ok = "alembic_version" in tables
    except Exception:
        migration_ok = False
    checks.append(
        ReadinessCheck(
            "migrations",
            migration_ok,
            "Alembic schema version is present" if migration_ok else "Run alembic upgrade head",
            "staging",
        )
    )
    blocking = [check.as_dict() for check in checks if not check.ok]
    return {
        "mode": "demo" if settings.demo_only else "live",
        "ready": not blocking,
        "checks": [check.as_dict() for check in checks],
        "blocking": blocking,
    }
