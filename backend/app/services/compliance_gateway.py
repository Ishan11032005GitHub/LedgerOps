from dataclasses import dataclass
import httpx
from fastapi import HTTPException
from ..config import get_settings


ALLOWED_PURPOSE_CODES = {
    "services",
    "goods",
    "software",
    "subscription",
    "education",
    "travel",
    "other",
}


@dataclass
class ScreeningResult:
    status: str
    provider: str
    reference: str | None = None
    requires_manual_review: bool = False


def preflight_collection(*, amount: float, currency: str, purpose_code: str, payer_name: str | None,
                         payer_email: str | None, payer_country: str | None, demo: bool) -> ScreeningResult:
    settings = get_settings()
    if purpose_code not in ALLOWED_PURPOSE_CODES:
        raise HTTPException(status_code=400, detail="Unsupported payment purpose code")
    if amount > settings.max_collection_amount:
        raise HTTPException(status_code=409, detail=f"Collection exceeds the configured {currency} transaction limit")
    if demo:
        return ScreeningResult(status="simulated_clear", provider="demo")
    if not payer_name or not payer_email or not payer_country:
        raise HTTPException(status_code=400, detail="Live international collection requires payer name, email, and country")
    if not settings.compliance_provider:
        raise HTTPException(status_code=503, detail="Live collection is blocked until a KYC/AML screening provider is configured")
    provider = settings.compliance_provider.strip().lower()
    if provider == "manual":
        return ScreeningResult(
            status="manual_review_required",
            provider="manual",
            reference=None,
            requires_manual_review=True,
        )
    if provider == "http":
        if not settings.compliance_provider_url:
            raise HTTPException(status_code=503, detail="The compliance screening endpoint is not configured")
        headers = {"Content-Type": "application/json"}
        if settings.compliance_provider_api_key:
            headers["Authorization"] = f"Bearer {settings.compliance_provider_api_key}"
        try:
            response = httpx.post(
                settings.compliance_provider_url,
                headers=headers,
                json={
                    "payer": {
                        "name": payer_name,
                        "email": payer_email,
                        "country": payer_country,
                    },
                    "payment": {
                        "amount": amount,
                        "currency": currency.upper(),
                        "purpose_code": purpose_code,
                    },
                },
                timeout=settings.compliance_provider_timeout_seconds,
            )
            response.raise_for_status()
            payload = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise HTTPException(status_code=503, detail="Compliance screening is temporarily unavailable") from exc
        provider_status = str(payload.get("status", "")).strip().lower()
        if provider_status not in {"clear", "approved"}:
            if provider_status in {"blocked", "rejected", "review"}:
                raise HTTPException(status_code=409, detail=f"Compliance screening returned {provider_status}")
            raise HTTPException(status_code=503, detail="Compliance screening returned an ambiguous result")
        return ScreeningResult(
            status="clear",
            provider="http",
            reference=str(payload.get("reference") or payload.get("id") or "") or None,
        )
    # Unknown providers remain fail-closed until an adapter is installed.
    raise HTTPException(status_code=503, detail=f"Compliance provider '{settings.compliance_provider}' adapter is not installed")
