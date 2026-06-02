import hashlib
import hmac
import json
import time
from dataclasses import dataclass
import httpx
from fastapi import HTTPException, Request
from ..config import get_settings
from ..models import Customer, Invoice, User


@dataclass
class CheckoutLink:
    provider: str
    mode: str
    checkout_id: str
    checkout_url: str
    raw: dict


def provider_status() -> dict:
    settings = get_settings()
    stripe_enabled = bool(settings.stripe_secret_key)
    return {
        "provider": "Stripe" if stripe_enabled else "Demo wallet provider",
        "mode": "stripe_test" if stripe_enabled else settings.payment_provider_mode,
        "connected": stripe_enabled,
    }


async def create_checkout_link(invoice: Invoice, customer: Customer | None, customer_email: str | None = None, success_url: str | None = None) -> CheckoutLink:
    settings = get_settings()
    if not settings.stripe_secret_key:
        checkout_id = f"ig_chk_{invoice.id}_{int(time.time())}"
        return CheckoutLink(
            provider="Demo wallet provider",
            mode="demo",
            checkout_id=checkout_id,
            checkout_url=f"{settings.frontend_url}/payment-app?checkout={checkout_id}",
            raw={"demo": True},
        )

    currency = invoice.currency.lower()
    amount_minor = int(round(invoice.amount * 100))
    final_success_url = success_url or f"{settings.frontend_url}/payment-app?checkout=success&invoice={invoice.id}"
    cancel_url = f"{settings.frontend_url}/payment-app?checkout=cancelled&invoice={invoice.id}"
    data = {
        "mode": "payment",
        "success_url": final_success_url,
        "cancel_url": cancel_url,
        "client_reference_id": invoice.invoice_number,
        "metadata[invoice_id]": str(invoice.id),
        "metadata[invoice_number]": invoice.invoice_number,
        "line_items[0][quantity]": "1",
        "line_items[0][price_data][currency]": currency,
        "line_items[0][price_data][unit_amount]": str(amount_minor),
        "line_items[0][price_data][product_data][name]": f"Invoice {invoice.invoice_number}",
    }
    if customer_email:
        data["customer_email"] = customer_email
    elif customer:
        data["metadata[customer_name]"] = customer.name

    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            "https://api.stripe.com/v1/checkout/sessions",
            data=data,
            auth=(settings.stripe_secret_key, ""),
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "Stripe checkout session failed")
        raise HTTPException(status_code=502, detail=detail)
    payload = response.json()
    return CheckoutLink(
        provider="Stripe",
        mode="stripe_test",
        checkout_id=payload["id"],
        checkout_url=payload["url"],
        raw=payload,
    )


async def retrieve_checkout_session(checkout_id: str) -> dict:
    settings = get_settings()
    if not settings.stripe_secret_key:
        return {
            "id": checkout_id,
            "payment_status": "paid",
            "amount_total": 0,
            "currency": "usd",
            "payment_intent": checkout_id,
            "metadata": {},
            "demo": True,
        }

    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.get(
            f"https://api.stripe.com/v1/checkout/sessions/{checkout_id}",
            auth=(settings.stripe_secret_key, ""),
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "Stripe checkout session lookup failed")
        raise HTTPException(status_code=502, detail=detail)
    return response.json()


async def create_card_setup_session(user: User) -> CheckoutLink | None:
    settings = get_settings()
    if not settings.stripe_secret_key:
        return None

    async with httpx.AsyncClient(timeout=20) as client:
        customer_response = await client.post(
            "https://api.stripe.com/v1/customers",
            data={"email": user.email, "name": user.name, "metadata[infinityguard_user_id]": str(user.id)},
            auth=(settings.stripe_secret_key, ""),
        )
        if customer_response.status_code >= 400:
            detail = customer_response.json().get("error", {}).get("message", "Card customer setup failed")
            raise HTTPException(status_code=502, detail=detail)
        customer_id = customer_response.json()["id"]
        session_response = await client.post(
            "https://api.stripe.com/v1/checkout/sessions",
            data={
                "mode": "setup",
                "currency": "usd",
                "payment_method_types[0]": "card",
                "customer": customer_id,
                "success_url": f"{settings.frontend_url}/payment-app?card_setup={{CHECKOUT_SESSION_ID}}",
                "cancel_url": f"{settings.frontend_url}/payment-app?card_setup=cancelled",
                "metadata[infinityguard_user_id]": str(user.id),
            },
            auth=(settings.stripe_secret_key, ""),
        )
    if session_response.status_code >= 400:
        detail = session_response.json().get("error", {}).get("message", "Card setup session failed")
        raise HTTPException(status_code=502, detail=detail)
    payload = session_response.json()
    return CheckoutLink(provider="Stripe", mode="stripe_test", checkout_id=payload["id"], checkout_url=payload["url"], raw=payload)


async def retrieve_card_setup_session(checkout_id: str) -> dict:
    settings = get_settings()
    if not settings.stripe_secret_key:
        raise HTTPException(status_code=400, detail="Secure card setup is not configured")
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.get(
            f"https://api.stripe.com/v1/checkout/sessions/{checkout_id}",
            params={"expand[]": "setup_intent.payment_method"},
            auth=(settings.stripe_secret_key, ""),
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "Card setup lookup failed")
        raise HTTPException(status_code=502, detail=detail)
    return response.json()


async def charge_saved_card(provider_token: str | None, amount: float, currency: str, description: str) -> dict | None:
    settings = get_settings()
    if not settings.stripe_secret_key or not provider_token:
        return None
    try:
        customer_id, payment_method_id = provider_token.split(":", 1)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Saved card is not ready for payment") from exc
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            "https://api.stripe.com/v1/payment_intents",
            data={
                "amount": str(int(round(amount * 100))),
                "currency": currency.lower(),
                "customer": customer_id,
                "payment_method": payment_method_id,
                "confirm": "true",
                "off_session": "true",
                "description": description,
            },
            auth=(settings.stripe_secret_key, ""),
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "Saved card payment failed")
        raise HTTPException(status_code=402, detail=detail)
    return response.json()


async def verified_stripe_event(request: Request) -> dict:
    settings = get_settings()
    body = await request.body()
    signature = request.headers.get("stripe-signature", "")
    if not settings.stripe_webhook_secret:
        raise HTTPException(status_code=400, detail="Stripe webhook secret is not configured")

    parts = dict(item.split("=", 1) for item in signature.split(",") if "=" in item)
    timestamp = parts.get("t")
    received_signature = parts.get("v1")
    if not timestamp or not received_signature:
        raise HTTPException(status_code=400, detail="Invalid Stripe signature header")

    signed_payload = f"{timestamp}.{body.decode()}".encode()
    expected = hmac.new(settings.stripe_webhook_secret.encode(), signed_payload, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, received_signature):
        raise HTTPException(status_code=400, detail="Invalid Stripe webhook signature")
    if abs(time.time() - int(timestamp)) > 300:
        raise HTTPException(status_code=400, detail="Stale Stripe webhook signature")

    return json.loads(body)
