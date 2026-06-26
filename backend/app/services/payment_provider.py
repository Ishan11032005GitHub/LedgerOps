import hashlib
import hmac
import json
import time
from dataclasses import dataclass
import httpx
from fastapi import HTTPException, Request
from ..config import get_settings
from ..models import Customer, Invoice, QuickLink, User


@dataclass
class CheckoutLink:
    provider: str
    mode: str
    checkout_id: str
    checkout_url: str
    raw: dict


def stripe_mode() -> str:
    settings = get_settings()
    if settings.demo_only:
        return "unconfigured"
    key = settings.stripe_secret_key.strip()
    if key.startswith("sk_live_"):
        return "live"
    if key.startswith("sk_test_"):
        return "test"
    return "unconfigured" if not key else "invalid"


def require_stripe(*, require_webhook: bool = False) -> tuple[object, str]:
    settings = get_settings()
    if settings.demo_only:
        raise HTTPException(status_code=503, detail="Real payments are disabled while LedgerOps is in demo-only mode")
    mode = stripe_mode()
    if mode not in {"test", "live"}:
        raise HTTPException(status_code=503, detail="Stripe is not configured with a valid secret key")
    if mode == "live" and require_webhook and not settings.stripe_webhook_secret.startswith("whsec_"):
        raise HTTPException(status_code=503, detail="Live payments require a configured Stripe webhook secret")
    return settings, mode


def provider_status() -> dict:
    settings = get_settings()
    if settings.demo_only:
        return {
            "provider": "LedgerOps Demo Network",
            "processor": "demo",
            "mode": "demo",
            "connected": False,
            "webhook_configured": False,
            "real_payments_enabled": False,
            "issuer_agnostic": True,
            "card_networks": ["Visa", "Mastercard", "RuPay (demo)"],
        }
    mode = stripe_mode()
    stripe_enabled = mode in {"test", "live"}
    webhook_configured = settings.stripe_webhook_secret.startswith("whsec_")
    return {
        "provider": "Card processor" if stripe_enabled else ("Demo card network" if settings.payment_provider_mode == "demo" else "Not configured"),
        "processor": settings.payment_processor if stripe_enabled else settings.payment_provider_mode,
        "mode": f"stripe_{mode}" if stripe_enabled else settings.payment_provider_mode,
        "connected": stripe_enabled,
        "webhook_configured": webhook_configured,
        "real_payments_enabled": mode == "live" and webhook_configured,
        "issuer_agnostic": True,
        "card_networks": ["Visa", "Mastercard", "American Express", "JCB", "Discover", "Diners Club", "UnionPay"],
    }


async def create_checkout_link(invoice: Invoice, customer: Customer | None, user: User, customer_email: str | None = None, success_url: str | None = None) -> CheckoutLink:
    settings = get_settings()
    if not settings.stripe_secret_key:
        if not settings.demo_only and settings.payment_provider_mode != "demo":
            raise HTTPException(status_code=503, detail="Payment provider is not configured")
        checkout_id = f"ig_chk_{invoice.id}_{int(time.time())}"
        return CheckoutLink(
            provider="Demo card network",
            mode="demo",
            checkout_id=checkout_id,
            checkout_url=f"{settings.frontend_url}/payment-app?checkout={checkout_id}",
            raw={"demo": True},
        )

    settings, mode = require_stripe(require_webhook=True)
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
        "metadata[ledgerops_user_id]": str(invoice.user_id or user.id),
        "metadata[created_by_user_id]": str(user.id),
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
            headers={"Idempotency-Key": f"ledgerops-invoice-{invoice.id}-{invoice.invoice_number}"},
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "Card checkout session failed")
        raise HTTPException(status_code=502, detail=detail)
    payload = response.json()
    return CheckoutLink(
        provider="Card processor",
        mode=f"stripe_{mode}",
        checkout_id=payload["id"],
        checkout_url=payload["url"],
        raw=payload,
    )


async def create_quicklink_checkout(quick_link: QuickLink, user: User) -> CheckoutLink:
    settings = get_settings()
    if not settings.stripe_secret_key:
        if not settings.demo_only and settings.payment_provider_mode != "demo":
            raise HTTPException(status_code=503, detail="Payment provider is not configured")
        checkout_id = f"ql_demo_{quick_link.public_id}"
        return CheckoutLink(
            provider="LedgerOps Demo Network",
            mode="demo",
            checkout_id=checkout_id,
            checkout_url=f"{settings.frontend_url}/pay/{quick_link.public_id}",
            raw={"demo": True},
        )

    settings, mode = require_stripe(require_webhook=True)
    data = {
        "mode": "payment",
        "payment_method_types[0]": "card",
        "success_url": f"{settings.frontend_url}/quicklinks?checkout=success&quicklink={quick_link.public_id}",
        "cancel_url": f"{settings.frontend_url}/quicklinks?checkout=cancelled&quicklink={quick_link.public_id}",
        "client_reference_id": quick_link.public_id,
        "metadata[quicklink_id]": str(quick_link.id),
        "metadata[quicklink_public_id]": quick_link.public_id,
        "metadata[ledgerops_user_id]": str(quick_link.user_id),
        "metadata[created_by_user_id]": str(user.id),
        "metadata[customer_name]": quick_link.payer_name or "QuickLink payer",
        "metadata[purpose_code]": quick_link.purpose_code,
        "line_items[0][quantity]": "1",
        "line_items[0][price_data][currency]": quick_link.currency.lower(),
        "line_items[0][price_data][unit_amount]": str(int(round(quick_link.amount * 100))),
        "line_items[0][price_data][product_data][name]": quick_link.title,
        "line_items[0][price_data][product_data][description]": f"LedgerOps QuickLink | Purpose: {quick_link.purpose_code}",
    }
    if quick_link.payer_email:
        data["customer_email"] = quick_link.payer_email

    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            "https://api.stripe.com/v1/checkout/sessions",
            data=data,
            auth=(settings.stripe_secret_key, ""),
            headers={"Idempotency-Key": f"ledgerops-quicklink-{quick_link.public_id}"},
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "QuickLink checkout session failed")
        raise HTTPException(status_code=502, detail=detail)
    payload = response.json()
    return CheckoutLink(
        provider="Card processor",
        mode=f"stripe_{mode}",
        checkout_id=payload["id"],
        checkout_url=payload["url"],
        raw=payload,
    )


async def retrieve_checkout_session(checkout_id: str) -> dict:
    settings = get_settings()
    if not settings.stripe_secret_key:
        if not settings.demo_only and settings.payment_provider_mode != "demo":
            raise HTTPException(status_code=503, detail="Payment provider is not configured")
        return {
            "id": checkout_id,
            "payment_status": "paid",
            "amount_total": 0,
            "currency": "usd",
            "payment_intent": checkout_id,
            "metadata": {},
            "demo": True,
        }

    settings, _mode = require_stripe()
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.get(
            f"https://api.stripe.com/v1/checkout/sessions/{checkout_id}",
            auth=(settings.stripe_secret_key, ""),
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "Card checkout session lookup failed")
        raise HTTPException(status_code=502, detail=detail)
    return response.json()


async def create_card_setup_session(user: User) -> CheckoutLink | None:
    settings = get_settings()
    if not settings.stripe_secret_key:
        return None

    settings, mode = require_stripe(require_webhook=True)
    async with httpx.AsyncClient(timeout=20) as client:
        customer_response = await client.post(
            "https://api.stripe.com/v1/customers",
            data={"email": user.email, "name": user.name, "metadata[ledgerops_user_id]": str(user.id)},
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
                "metadata[ledgerops_user_id]": str(user.id),
            },
            auth=(settings.stripe_secret_key, ""),
        )
    if session_response.status_code >= 400:
        detail = session_response.json().get("error", {}).get("message", "Card setup session failed")
        raise HTTPException(status_code=502, detail=detail)
    payload = session_response.json()
    return CheckoutLink(provider="Card processor", mode=f"stripe_{mode}", checkout_id=payload["id"], checkout_url=payload["url"], raw=payload)


async def retrieve_card_setup_session(checkout_id: str) -> dict:
    settings = get_settings()
    if not settings.stripe_secret_key:
        raise HTTPException(status_code=400, detail="Secure card setup is not configured")
    settings, _mode = require_stripe()
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


async def charge_saved_card(provider_token: str | None, amount: float, currency: str, description: str, idempotency_key: str) -> dict | None:
    settings = get_settings()
    if not settings.stripe_secret_key or not provider_token:
        return None
    settings, _mode = require_stripe(require_webhook=True)
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
            headers={"Idempotency-Key": idempotency_key},
        )
    if response.status_code >= 400:
        detail = response.json().get("error", {}).get("message", "Saved card payment failed")
        raise HTTPException(status_code=402, detail=detail)
    payload = response.json()
    if payload.get("status") != "succeeded":
        raise HTTPException(status_code=402, detail="The card payment requires customer action or was not completed")
    return payload


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
