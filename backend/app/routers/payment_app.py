from datetime import datetime
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from sqlalchemy import func
from sqlalchemy.orm import Session
from ..account_scope import account_user_ids
from ..auth import current_user, require_roles
from ..database import SessionLocal, get_db
from ..models import Customer, DemoMessage, DemoWallet, EventLog, Invoice, Payment, PaymentMethod, Role, Transaction, User
from ..schemas import DemoChatIn, PaymentAppConnectIn, PaymentLinkIn, PaymentMethodIn, WalletRequestIn, WalletTransferIn
from ..services.events import enqueue_event, process_event
from ..services.payment_provider import charge_saved_card, create_card_setup_session, create_checkout_link, provider_status, retrieve_card_setup_session, retrieve_checkout_session, verified_stripe_event

router = APIRouter(prefix="/api/payment-app", tags=["payment-app"])
DEMO_EMAILS = {"asha.demo@ledgerops.ai", "rohan.demo@ledgerops.ai"}


def is_demo_user(user: User) -> bool:
    return user.email in DEMO_EMAILS


def demo_handle(user: User) -> str:
    return f"{user.email.split('@')[0]}@pay"


def demo_contact_out(user: User) -> dict:
    wallet = getattr(user, "_demo_wallet", None)
    return {
        "id": user.id,
        "name": user.name,
        "handle": demo_handle(user),
        "currency": wallet.currency if wallet else "INR",
        "initial": user.name[:1].upper(),
    }


def demo_message_out(message: DemoMessage, user_id: int) -> dict:
    return {
        "id": message.id,
        "kind": message.kind,
        "direction": "outgoing" if message.sender_id == user_id else "incoming",
        "text": message.text,
        "note": message.note,
        "amount": message.amount_minor / 100 if message.amount_minor is not None else None,
        "currency": message.currency,
        "status": message.status,
        "createdAt": message.created_at.isoformat(),
    }


def demo_customer(db: Session, owner: User, counterparty: User) -> Customer:
    customer = db.query(Customer).filter(Customer.user_id == owner.id, Customer.name == counterparty.name).first()
    if not customer:
        customer = Customer(user_id=owner.id, name=counterparty.name, country="IN", currency="INR", risk_rating="Low", kyc_status="Demo verified")
        db.add(customer)
        db.flush()
    return customer


def payment_method_out(method: PaymentMethod):
    return {
        "id": method.id,
        "label": method.label,
        "cardholder_name": method.cardholder_name,
        "brand": method.brand,
        "last_four": method.last_four,
        "expiry_month": method.expiry_month,
        "expiry_year": method.expiry_year,
        "is_default": method.is_default,
    }


def reset_demo_state(db: Session) -> dict:
    demo_users = db.query(User).filter(User.email.in_(DEMO_EMAILS)).all()
    demo_ids = [account.id for account in demo_users]
    if len(demo_ids) != 2:
        raise HTTPException(status_code=409, detail="Demo accounts are not ready")

    db.query(DemoMessage).filter(
        (DemoMessage.sender_id.in_(demo_ids)) | (DemoMessage.recipient_id.in_(demo_ids))
    ).delete(synchronize_session=False)
    db.query(Transaction).filter(Transaction.user_id.in_(demo_ids)).delete(synchronize_session=False)
    db.query(Payment).filter(Payment.user_id.in_(demo_ids)).delete(synchronize_session=False)
    db.query(EventLog).filter(EventLog.user_id.in_(demo_ids)).delete(synchronize_session=False)
    db.query(Invoice).filter(Invoice.user_id.in_(demo_ids)).delete(synchronize_session=False)
    db.query(Customer).filter(Customer.user_id.in_(demo_ids)).delete(synchronize_session=False)

    starting_balances = {
        "asha.demo@ledgerops.ai": 2_500_000,
        "rohan.demo@ledgerops.ai": 1_800_000,
    }
    for account in demo_users:
        wallet = db.query(DemoWallet).filter(DemoWallet.user_id == account.id).first()
        if wallet:
            wallet.balance_minor = starting_balances[account.email]
    db.commit()
    return {
        "status": "reset",
        "balances": {
            "asha.demo@ledgerops.ai": 25_000,
            "rohan.demo@ledgerops.ai": 18_000,
        },
        "currency": "INR",
    }


def process_event_background(event_id: int) -> None:
    db = SessionLocal()
    try:
        event = db.get(EventLog, event_id)
        if event:
            process_event(db, event)
    finally:
        db.close()


def record_completed_checkout(db: Session, session: dict, invoice_id: int | None, user_id: int | None = None):
    if session.get("payment_status") != "paid":
        raise HTTPException(status_code=409, detail="The checkout has not been paid")
    metadata = session.get("metadata") or {}
    resolved_invoice_id = invoice_id or (int(metadata["invoice_id"]) if metadata.get("invoice_id") else None)
    resolved_user_id = user_id or (int(metadata["ledgerops_user_id"]) if metadata.get("ledgerops_user_id") else None)
    invoice = db.get(Invoice, resolved_invoice_id) if resolved_invoice_id else None
    if invoice and resolved_user_id and invoice.user_id != resolved_user_id:
        raise HTTPException(status_code=403, detail="Checkout session does not belong to this account")
    customer = db.get(Customer, invoice.customer_id) if invoice else None
    if invoice:
        paid_amount = (session.get("amount_total") or 0) / 100
        paid_currency = (session.get("currency") or "").upper()
        if round(paid_amount, 2) != round(invoice.amount, 2) or paid_currency != invoice.currency.upper():
            raise HTTPException(status_code=409, detail="Checkout amount or currency does not match the invoice")
        invoice.status = "paid"
        invoice.paid_at = datetime.utcnow().date()
    if not customer:
        customer = db.query(Customer).filter(Customer.user_id == resolved_user_id, Customer.name == metadata.get("customer_name", "Stripe customer")).first()
    if not customer:
        customer = Customer(user_id=resolved_user_id, name=metadata.get("customer_name", "Stripe customer"), country="US", currency=(session.get("currency") or "usd").upper(), risk_rating="Medium", kyc_status="Review")
        db.add(customer)
        db.flush()

    external_ref = session.get("payment_intent") or session.get("id")
    payment = db.query(Payment).filter(Payment.user_id == resolved_user_id, Payment.external_ref == external_ref).first()
    if not payment:
        amount = (session.get("amount_total") or 0) / 100
        if amount == 0 and invoice:
            amount = invoice.amount
        payment = Payment(
            invoice_id=invoice.id if invoice else None,
            user_id=resolved_user_id,
            customer_id=customer.id,
            amount=amount,
            currency=(session.get("currency") or customer.currency).upper(),
            country=customer.country,
            status="settled",
            rail="Stripe Checkout",
            external_ref=external_ref,
        )
        db.add(payment)
        db.flush()
        db.add(Transaction(user_id=resolved_user_id, payment_id=payment.id, type="inbound", amount=payment.amount, currency=payment.currency, country=payment.country, counterparty=customer.name, risk_score=18))
    return invoice, payment, customer


@router.get("/status")
def status(db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    payment_count = db.query(Payment).filter(Payment.user_id.in_(scope)).count()
    latest_payment = db.query(func.max(Payment.received_at)).filter(Payment.user_id.in_(scope)).scalar()
    last_sync = db.query(EventLog).filter(EventLog.user_id.in_(scope), EventLog.event_type == "payment_app.sync").order_by(EventLog.created_at.desc()).first()
    provider = provider_status()
    if is_demo_user(user):
        wallet = db.query(DemoWallet).filter(DemoWallet.user_id == user.id).first()
        return {
            "provider": "LedgerOps Demo Network",
            "mode": "demo",
            "connected": True,
            "sync_health": "simulated",
            "last_payment_at": latest_payment.isoformat() if latest_payment else None,
            "last_sync_at": None,
            "webhook_events": db.query(DemoMessage).filter((DemoMessage.sender_id == user.id) | (DemoMessage.recipient_id == user.id)).count(),
            "mapped_payments": payment_count,
            "saved_methods": db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).count(),
            "webhook_configured": False,
            "real_payments_enabled": False,
            "available_balance": (wallet.balance_minor / 100) if wallet else 0,
            "currency": wallet.currency if wallet else "INR",
        }
    return {
        "provider": provider["provider"],
        "mode": provider["mode"],
        "connected": provider["connected"],
        "sync_health": "healthy" if provider["connected"] else "not_configured",
        "last_payment_at": latest_payment.isoformat() if latest_payment else None,
        "last_sync_at": last_sync.created_at.isoformat() if last_sync else None,
        "webhook_events": db.query(EventLog).filter(EventLog.user_id.in_(scope)).count(),
        "mapped_payments": payment_count,
        "saved_methods": db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).count(),
        "webhook_configured": provider["webhook_configured"],
        "real_payments_enabled": provider["real_payments_enabled"],
    }


@router.get("/demo/contacts")
def demo_contacts(db: Session = Depends(get_db), user: User = Depends(current_user)):
    if not is_demo_user(user):
        return []
    contacts = db.query(User).filter(User.email.in_(DEMO_EMAILS), User.id != user.id).order_by(User.name).all()
    wallets = {wallet.user_id: wallet for wallet in db.query(DemoWallet).filter(DemoWallet.user_id.in_([contact.id for contact in contacts])).all()}
    for contact in contacts:
        contact._demo_wallet = wallets.get(contact.id)
    return [demo_contact_out(contact) for contact in contacts]


@router.get("/demo/messages/{contact_id}")
def demo_messages(contact_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if not is_demo_user(user):
        raise HTTPException(status_code=404, detail="Demo chat is only available to demo accounts")
    contact = db.query(User).filter(User.id == contact_id, User.email.in_(DEMO_EMAILS)).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Demo contact not found")
    records = db.query(DemoMessage).filter(
        ((DemoMessage.sender_id == user.id) & (DemoMessage.recipient_id == contact.id)) |
        ((DemoMessage.sender_id == contact.id) & (DemoMessage.recipient_id == user.id))
    ).order_by(DemoMessage.created_at.asc()).limit(200).all()
    unread = [message for message in records if message.recipient_id == user.id and message.read_at is None]
    for message in unread:
        message.read_at = datetime.utcnow()
    if unread:
        db.commit()
    return [demo_message_out(message, user.id) for message in records]


@router.post("/demo/messages")
def send_demo_message(payload: DemoChatIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if not is_demo_user(user):
        raise HTTPException(status_code=404, detail="Demo chat is only available to demo accounts")
    recipient = db.query(User).filter(User.id == payload.recipient_id, User.email.in_(DEMO_EMAILS)).first()
    if not recipient or recipient.id == user.id:
        raise HTTPException(status_code=404, detail="Demo contact not found")
    message = DemoMessage(sender_id=user.id, recipient_id=recipient.id, kind="text", text=payload.text.strip(), status="sent")
    db.add(message)
    db.commit()
    db.refresh(message)
    return demo_message_out(message, user.id)


@router.get("/payment-methods")
def payment_methods(db: Session = Depends(get_db), user: User = Depends(current_user)):
    methods = db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).order_by(PaymentMethod.is_default.desc(), PaymentMethod.created_at.desc()).all()
    return [payment_method_out(method) for method in methods]


@router.post("/payment-methods", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def add_payment_method(payload: PaymentMethodIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    provider = provider_status()
    if not is_demo_user(user) and provider["mode"] != "demo":
        raise HTTPException(status_code=400, detail="Cards must be added through secure Stripe setup")
    is_first = not db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).first()
    method = PaymentMethod(user_id=user.id, is_default=is_first, **payload.model_dump())
    db.add(method)
    db.commit()
    db.refresh(method)
    return payment_method_out(method)


@router.post("/payment-methods/setup", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
async def start_payment_method_setup(user: User = Depends(current_user)):
    if is_demo_user(user):
        return {"mode": "manual"}
    provider = provider_status()
    if not provider["connected"] and provider["mode"] != "demo":
        raise HTTPException(status_code=503, detail="Payment provider is not configured")
    checkout = await create_card_setup_session(user)
    if not checkout:
        return {"mode": "manual"}
    return {"mode": checkout.mode, "checkout_id": checkout.checkout_id, "checkout_url": checkout.checkout_url}


@router.post("/demo/reset")
def reset_demo(db: Session = Depends(get_db), user: User = Depends(current_user)):
    if not is_demo_user(user):
        raise HTTPException(status_code=404, detail="Demo reset is only available to demo accounts")
    result = reset_demo_state(db)
    wallet = db.query(DemoWallet).filter(DemoWallet.user_id == user.id).first()
    return result | {"available_balance": wallet.balance_minor / 100 if wallet else 0}


@router.post("/demo/public-reset")
def public_reset_demo(db: Session = Depends(get_db)):
    return reset_demo_state(db)


@router.post("/payment-methods/setup/{checkout_id}/complete", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
async def complete_payment_method_setup(checkout_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    session = await retrieve_card_setup_session(checkout_id)
    if str(session.get("metadata", {}).get("ledgerops_user_id")) != str(user.id):
        raise HTTPException(status_code=403, detail="Card setup session does not belong to this account")
    setup_intent = session.get("setup_intent") or {}
    payment_method = setup_intent.get("payment_method") if isinstance(setup_intent, dict) else None
    card = payment_method.get("card") if isinstance(payment_method, dict) else None
    if not card or not payment_method.get("id") or not session.get("customer"):
        raise HTTPException(status_code=400, detail="Card setup has not been completed")
    provider_token = f"{session['customer']}:{payment_method['id']}"
    existing = db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id, PaymentMethod.provider_token == provider_token).first()
    if existing:
        return payment_method_out(existing)
    is_first = not db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).first()
    method = PaymentMethod(
        user_id=user.id,
        label=f"{card.get('brand', 'Card').title()} card",
        cardholder_name=user.name,
        brand=card.get("brand", "card").replace("_", " ").title(),
        last_four=card["last4"],
        expiry_month=card["exp_month"],
        expiry_year=card["exp_year"],
        is_default=is_first,
        provider_token=provider_token,
    )
    db.add(method)
    db.commit()
    db.refresh(method)
    return payment_method_out(method)


@router.patch("/payment-methods/{method_id}/default", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def set_default_payment_method(method_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    method = db.query(PaymentMethod).filter(PaymentMethod.id == method_id, PaymentMethod.user_id == user.id).first()
    if not method:
        raise HTTPException(status_code=404, detail="Payment method not found")
    db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).update({PaymentMethod.is_default: False})
    method.is_default = True
    db.commit()
    db.refresh(method)
    return payment_method_out(method)


@router.delete("/payment-methods/{method_id}", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def remove_payment_method(method_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    method = db.query(PaymentMethod).filter(PaymentMethod.id == method_id, PaymentMethod.user_id == user.id).first()
    if not method:
        raise HTTPException(status_code=404, detail="Payment method not found")
    was_default = method.is_default
    db.delete(method)
    db.commit()
    if was_default:
        next_method = db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).order_by(PaymentMethod.created_at.desc()).first()
        if next_method:
            next_method.is_default = True
            db.commit()
    return {"status": "removed", "id": method_id}


@router.post("/connect", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def connect(payload: PaymentAppConnectIn, background: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(current_user)):
    event = enqueue_event(db, "payment_app.connected", payload.model_dump(), user_id=user.id)
    background.add_task(process_event_background, event.id)
    return {
        "status": "connected",
        "provider": payload.provider,
        "account_name": payload.account_name,
        "mode": payload.mode,
        "event_id": event.id,
    }


@router.post("/sync-demo", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def sync_demo(background: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if provider_status()["mode"] != "demo":
        raise HTTPException(status_code=404, detail="Demo synchronization is disabled")
    scope = account_user_ids(db, user)
    customer = db.query(Customer).filter(Customer.user_id.in_(scope), Customer.name == "Northstar Robotics").first()
    if not customer:
        customer = Customer(user_id=user.id, name="Northstar Robotics", country="US", currency="USD", risk_rating="Low", kyc_status="Verified")
        db.add(customer)
        db.flush()

    external_ref = f"stripe_pi_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
    payment = Payment(
        customer_id=customer.id,
        user_id=user.id,
        amount=18420.75,
        currency=customer.currency,
        country=customer.country,
        status="settled",
        rail="Stripe",
        external_ref=external_ref,
    )
    db.add(payment)
    db.flush()
    db.add(Transaction(user_id=user.id, payment_id=payment.id, type="inbound", amount=payment.amount, currency=payment.currency, country=payment.country, counterparty=customer.name, risk_score=28))
    event = enqueue_event(db, "payment_app.sync", {"provider": "Stripe", "payment_id": payment.id, "external_ref": external_ref}, user_id=user.id)
    background.add_task(process_event_background, event.id)
    return {"status": "synced", "imported_payments": 1, "payment_id": payment.id, "external_ref": external_ref, "event_id": event.id}


@router.post("/payment-link", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
async def payment_link(payload: PaymentLinkIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    invoice = db.query(Invoice).filter(Invoice.id == payload.invoice_id, Invoice.user_id.in_(account_user_ids(db, user))).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    customer = db.get(Customer, invoice.customer_id)
    checkout = await create_checkout_link(invoice, customer, user, payload.customer_email, payload.success_url)
    event = enqueue_event(db, "payment_link.created", {"invoice_id": invoice.id, "provider": checkout.provider, "checkout_id": checkout.checkout_id}, user_id=user.id)
    return {
        "status": "created",
        "provider": checkout.provider,
        "mode": checkout.mode,
        "checkout_id": checkout.checkout_id,
        "invoice_number": invoice.invoice_number,
        "amount": invoice.amount,
        "currency": invoice.currency,
        "customer": customer.name if customer else None,
        "checkout_url": checkout.checkout_url,
        "event_id": event.id,
    }


@router.post("/stripe-webhook")
async def stripe_webhook(request: Request, background: BackgroundTasks, db: Session = Depends(get_db)):
    event = await verified_stripe_event(request)
    stripe_event_id = event.get("id")
    recent_completed = db.query(EventLog).filter(EventLog.event_type == "stripe.checkout.completed").order_by(EventLog.created_at.desc()).limit(100).all()
    duplicate = next((stored for stored in recent_completed if stored.payload.get("stripe_event_id") == stripe_event_id), None) if stripe_event_id else None
    if duplicate:
        return {"status": "already_processed", "event_id": duplicate.id}
    if event.get("type") not in {"checkout.session.completed", "checkout.session.async_payment_succeeded"}:
        stored = enqueue_event(db, "stripe.webhook.ignored", {"stripe_event_id": event.get("id"), "type": event.get("type")})
        return {"status": "ignored", "event_id": stored.id}

    session = event.get("data", {}).get("object", {})
    metadata = session.get("metadata") or {}
    if not metadata.get("invoice_id") or not metadata.get("ledgerops_user_id"):
        stored = enqueue_event(db, "stripe.webhook.ignored", {"stripe_event_id": stripe_event_id, "type": event.get("type"), "reason": "not_a_ledgerops_checkout"})
        return {"status": "ignored", "event_id": stored.id}
    if event.get("type") == "checkout.session.completed" and session.get("payment_status") != "paid":
        stored = enqueue_event(db, "stripe.checkout.pending", {"stripe_event_id": stripe_event_id, "invoice_id": metadata.get("invoice_id")})
        return {"status": "pending", "event_id": stored.id}
    invoice_id = int(metadata["invoice_id"]) if metadata.get("invoice_id") else None
    invoice, payment, _customer = record_completed_checkout(db, session, invoice_id)
    stored = enqueue_event(db, "stripe.checkout.completed", {"stripe_event_id": event.get("id"), "invoice_id": invoice.id if invoice else invoice_id, "external_ref": payment.external_ref}, user_id=payment.user_id)
    background.add_task(process_event_background, stored.id)
    return {"status": "processed", "event_id": stored.id}


@router.post("/verify-checkout/{checkout_id}", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
async def verify_checkout(checkout_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    session = await retrieve_checkout_session(checkout_id)
    metadata = session.get("metadata") or {}
    invoice_id = int(metadata["invoice_id"]) if metadata.get("invoice_id") else None
    if not invoice_id:
        events = db.query(EventLog).filter(EventLog.user_id.in_(account_user_ids(db, user)), EventLog.event_type == "payment_link.created").order_by(EventLog.created_at.desc()).limit(50).all()
        event = next((item for item in events if item.payload.get("checkout_id") == checkout_id), None)
        invoice_id = event.payload.get("invoice_id") if event else None
    if session.get("payment_status") != "paid":
        return {
            "status": "unpaid",
            "checkout_id": checkout_id,
            "payment_status": session.get("payment_status", "unknown"),
            "message": "Stripe has not marked this checkout session as paid yet.",
        }
    invoice_record = db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.user_id.in_(account_user_ids(db, user))).first() if invoice_id else None
    if not invoice_record:
        raise HTTPException(status_code=403, detail="Checkout session does not belong to this workspace")
    metadata_owner = (session.get("metadata") or {}).get("ledgerops_user_id")
    if metadata_owner and str(metadata_owner) != str(invoice_record.user_id):
        raise HTTPException(status_code=403, detail="Checkout ownership does not match the invoice")
    invoice, payment, customer = record_completed_checkout(db, session, invoice_id, user_id=invoice_record.user_id)
    stored = enqueue_event(db, "stripe.checkout.manually_verified", {"checkout_id": checkout_id, "invoice_id": invoice.id if invoice else invoice_id, "external_ref": payment.external_ref}, user_id=user.id)
    return {
        "status": "verified",
        "checkout_id": checkout_id,
        "invoice_id": invoice.id if invoice else invoice_id,
        "invoice_number": invoice.invoice_number if invoice else None,
        "payment_id": payment.id,
        "recipient": customer.name,
        "amount": payment.amount,
        "currency": payment.currency,
        "event_id": stored.id,
    }


@router.post("/pay", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
async def pay(payload: WalletTransferIn, background: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(current_user)):
    prior = db.query(EventLog).filter(EventLog.user_id == user.id, EventLog.event_type == "wallet.payment.sent").order_by(EventLog.created_at.desc()).limit(100).all()
    prior_event = next((event for event in prior if event.payload.get("idempotency_key") == payload.idempotency_key), None)
    if prior_event:
        payment = db.get(Payment, prior_event.payload.get("payment_id"))
        if payment:
            return {"status": payment.status, "payment_id": payment.id, "external_ref": payment.external_ref, "recipient": payload.recipient_name, "amount": payment.amount, "currency": payment.currency, "funding_source": payment.rail}

    if is_demo_user(user):
        recipient = db.query(User).filter(User.email.in_(DEMO_EMAILS), User.id != user.id).first()
        if not recipient or payload.recipient_name != recipient.name:
            raise HTTPException(status_code=404, detail="Demo recipient not found")
        sender_wallet = db.query(DemoWallet).filter(DemoWallet.user_id == user.id).with_for_update().first()
        recipient_wallet = db.query(DemoWallet).filter(DemoWallet.user_id == recipient.id).with_for_update().first()
        amount_minor = int(round(payload.amount * 100))
        if not sender_wallet or not recipient_wallet:
            raise HTTPException(status_code=409, detail="Demo wallet is unavailable")
        if payload.currency != sender_wallet.currency or recipient_wallet.currency != sender_wallet.currency:
            raise HTTPException(status_code=400, detail="Demo wallets use INR")
        if amount_minor > sender_wallet.balance_minor:
            raise HTTPException(status_code=402, detail="Insufficient demo balance")

        sender_wallet.balance_minor -= amount_minor
        recipient_wallet.balance_minor += amount_minor
        reference = f"demo_{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}"
        sender_customer = demo_customer(db, user, recipient)
        recipient_customer = demo_customer(db, recipient, user)
        sender_payment = Payment(user_id=user.id, customer_id=sender_customer.id, amount=payload.amount, currency="INR", country="IN", status="settled", rail="LedgerOps Demo", external_ref=f"{reference}_out")
        recipient_payment = Payment(user_id=recipient.id, customer_id=recipient_customer.id, amount=payload.amount, currency="INR", country="IN", status="settled", rail="LedgerOps Demo", external_ref=f"{reference}_in")
        db.add_all([sender_payment, recipient_payment])
        db.flush()
        db.add_all([
            Transaction(user_id=user.id, payment_id=sender_payment.id, type="outbound", amount=payload.amount, currency="INR", country="IN", counterparty=recipient.name, risk_score=5),
            Transaction(user_id=recipient.id, payment_id=recipient_payment.id, type="inbound", amount=payload.amount, currency="INR", country="IN", counterparty=user.name, risk_score=5),
            DemoMessage(sender_id=user.id, recipient_id=recipient.id, kind="payment", text=f"Paid INR {payload.amount:,.2f}", note=payload.note, amount_minor=amount_minor, currency="INR", status="completed"),
        ])
        event = enqueue_event(db, "wallet.payment.sent", payload.model_dump() | {"payment_id": sender_payment.id, "external_ref": sender_payment.external_ref, "funding_source": "Demo balance"}, user_id=user.id)
        return {"status": "settled", "payment_id": sender_payment.id, "external_ref": sender_payment.external_ref, "recipient": recipient.name, "amount": payload.amount, "currency": "INR", "funding_source": "Demo balance", "event_id": event.id}

    provider = provider_status()
    if provider["mode"] == "stripe_live":
        raise HTTPException(status_code=501, detail="Live recipient payouts require connected recipient accounts and are not enabled yet. Use invoice checkout for live collections.")
    if not provider["connected"] and provider["mode"] != "demo":
        raise HTTPException(status_code=503, detail="Payment provider is not configured")
    method = None
    if payload.payment_method_id:
        method = db.query(PaymentMethod).filter(PaymentMethod.id == payload.payment_method_id, PaymentMethod.user_id == user.id).first()
        if not method:
            raise HTTPException(status_code=404, detail="Payment method not found")
    customer = db.query(Customer).filter(Customer.user_id.in_(account_user_ids(db, user)), Customer.name == payload.recipient_name).first()
    if not customer:
        customer = Customer(user_id=user.id, name=payload.recipient_name, country="US", currency=payload.currency, risk_rating="Medium", kyc_status="Review")
        db.add(customer)
        db.flush()
    if provider["connected"] and not method:
        raise HTTPException(status_code=400, detail="Select a securely saved payment card")
    card_charge = await charge_saved_card(method.provider_token if method else None, payload.amount, payload.currency, f"Payment to {payload.recipient_name}", f"ledgerops-pay-{user.id}-{payload.idempotency_key}")
    external_ref = card_charge["id"] if card_charge else f"wallet_pay_{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}"
    payment_rail = f"{method.brand} ending {method.last_four}" if method else payload.rail
    payment = Payment(
        customer_id=customer.id,
        user_id=user.id,
        amount=payload.amount,
        currency=payload.currency,
        country=customer.country,
        status="settled" if card_charge else "processing",
        rail=payment_rail,
        external_ref=external_ref,
    )
    db.add(payment)
    db.flush()
    db.add(Transaction(user_id=user.id, payment_id=payment.id, type="outbound", amount=payload.amount, currency=payload.currency, country=customer.country, counterparty=payload.recipient_name, risk_score=22))
    event = enqueue_event(db, "wallet.payment.sent", payload.model_dump() | {"payment_id": payment.id, "external_ref": external_ref, "funding_source": payment_rail}, user_id=user.id)
    background.add_task(process_event_background, event.id)
    return {"status": payment.status, "payment_id": payment.id, "external_ref": external_ref, "recipient": payload.recipient_name, "amount": payload.amount, "currency": payload.currency, "funding_source": payment_rail}


@router.post("/request", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def request_money(payload: WalletRequestIn, background: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if is_demo_user(user):
        payer = db.query(User).filter(User.email.in_(DEMO_EMAILS), User.id != user.id).first()
        if not payer or payload.payer_name != payer.name:
            raise HTTPException(status_code=404, detail="Demo payer not found")
        wallet = db.query(DemoWallet).filter(DemoWallet.user_id == user.id).first()
        if not wallet or payload.currency != wallet.currency:
            raise HTTPException(status_code=400, detail="Demo wallets use INR")
        message = DemoMessage(sender_id=user.id, recipient_id=payer.id, kind="request", text=f"Requested INR {payload.amount:,.2f}", note=payload.note, amount_minor=int(round(payload.amount * 100)), currency="INR", status="pending")
        db.add(message)
        db.commit()
        db.refresh(message)
        return {"status": "requested", "request_id": f"demo_request_{message.id}", "payer": payer.name, "amount": payload.amount, "currency": "INR"}
    request_id = f"wallet_req_{int(datetime.utcnow().timestamp())}"
    event = enqueue_event(db, "wallet.payment.requested", payload.model_dump() | {"request_id": request_id}, user_id=user.id)
    background.add_task(process_event_background, event.id)
    return {"status": "requested", "request_id": request_id, "payer": payload.payer_name, "amount": payload.amount, "currency": payload.currency}
