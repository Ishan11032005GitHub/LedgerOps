from dataclasses import dataclass
from typing import Protocol
import httpx
from fastapi import HTTPException
from ..config import get_settings


@dataclass
class RefundResult:
    provider_ref: str
    status: str
    amount: float
    currency: str


class PaymentProcessor(Protocol):
    name: str

    async def refund(self, *, payment_ref: str, amount: float, currency: str, reason: str, idempotency_key: str) -> RefundResult:
        ...


class StripeProcessor:
    name = "stripe"

    async def refund(self, *, payment_ref: str, amount: float, currency: str, reason: str, idempotency_key: str) -> RefundResult:
        settings = get_settings()
        if settings.demo_only:
            return RefundResult(
                provider_ref=f"demo_refund_{idempotency_key[-12:]}",
                status="succeeded",
                amount=amount,
                currency=currency,
            )
        if not settings.stripe_secret_key.startswith(("sk_test_", "sk_live_")):
            raise HTTPException(status_code=503, detail="The configured card processor is unavailable")
        data = {
            "payment_intent": payment_ref,
            "amount": str(int(round(amount * 100))),
            "reason": reason if reason in {"duplicate", "fraudulent", "requested_by_customer"} else "requested_by_customer",
            "metadata[ledgerops_reason]": reason,
        }
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(
                "https://api.stripe.com/v1/refunds",
                data=data,
                auth=(settings.stripe_secret_key, ""),
                headers={"Idempotency-Key": idempotency_key},
            )
        if response.status_code >= 400:
            detail = response.json().get("error", {}).get("message", "Refund could not be created")
            raise HTTPException(status_code=502, detail=detail)
        payload = response.json()
        return RefundResult(
            provider_ref=payload["id"],
            status="succeeded" if payload.get("status") == "succeeded" else payload.get("status", "pending"),
            amount=(payload.get("amount") or int(round(amount * 100))) / 100,
            currency=(payload.get("currency") or currency).upper(),
        )


def get_processor() -> PaymentProcessor:
    processor = get_settings().payment_processor.strip().lower()
    if processor == "stripe":
        return StripeProcessor()
    raise HTTPException(status_code=503, detail=f"Payment processor '{processor}' is not installed")
