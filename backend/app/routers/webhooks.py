from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from sqlalchemy.orm import Session
from ..account_scope import account_user_ids
from ..auth import current_user, require_roles
from ..database import SessionLocal, get_db
from ..models import Customer, EventLog, Invoice, Payment, Role, Transaction, User
from ..schemas import InvoiceWebhookIn, PaymentWebhookIn
from ..services.events import enqueue_event, process_event

router = APIRouter(prefix="/api/webhooks", tags=["webhooks"])


def process_event_background(event_id: int) -> None:
    db = SessionLocal()
    try:
        event = db.get(EventLog, event_id)
        if event:
            process_event(db, event)
    finally:
        db.close()


def find_or_create_customer(db: Session, user: User, name: str, country: str, currency: str) -> Customer:
    customer = db.query(Customer).filter(Customer.user_id.in_(account_user_ids(db, user)), Customer.name == name).first()
    if customer:
        return customer
    customer = Customer(user_id=user.id, name=name, country=country, currency=currency, risk_rating="Medium", kyc_status="Review")
    db.add(customer)
    db.flush()
    return customer


@router.post("/payment-received", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def payment_received(payload: PaymentWebhookIn, background: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(current_user)):
    existing = db.query(Payment).filter(Payment.external_ref == payload.external_ref).first()
    if existing:
        if existing.user_id not in account_user_ids(db, user):
            raise HTTPException(status_code=409, detail="Payment reference is already registered")
        return {"status": "already_exists", "payment_id": existing.id}
    customer = find_or_create_customer(db, user, payload.customer_name, payload.country, payload.currency)
    invoice = db.query(Invoice).filter(Invoice.user_id.in_(account_user_ids(db, user)), Invoice.invoice_number == payload.invoice_number).first() if payload.invoice_number else None
    payment = Payment(
        user_id=user.id,
        invoice_id=invoice.id if invoice else None,
        customer_id=customer.id,
        amount=payload.amount,
        currency=payload.currency,
        country=payload.country,
        rail=payload.rail,
        external_ref=payload.external_ref,
    )
    db.add(payment)
    if invoice:
        invoice.status = "paid"
    db.flush()
    db.add(Transaction(user_id=user.id, payment_id=payment.id, type="inbound", amount=payload.amount, currency=payload.currency, country=payload.country, counterparty=customer.name, risk_score=35))
    event = enqueue_event(db, "payment.received", payload.model_dump() | {"payment_id": payment.id}, user_id=user.id)
    background.add_task(process_event_background, event.id)
    return {"status": "accepted", "payment_id": payment.id, "event_id": event.id}


@router.post("/invoice-created", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def invoice_created(payload: InvoiceWebhookIn, background: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(current_user)):
    customer = find_or_create_customer(db, user, payload.customer_name, payload.country, payload.currency)
    duplicate = db.query(Invoice).filter(
        Invoice.user_id.in_(account_user_ids(db, user)),
        Invoice.invoice_number == payload.invoice_number,
    ).first()
    if duplicate:
        return {"status": "already_exists", "invoice_id": duplicate.id}
    invoice = Invoice(user_id=user.id, workspace_key=user.workspace_key, customer_id=customer.id, **payload.model_dump(exclude={"customer_name"}), status="pending")
    db.add(invoice)
    db.flush()
    event = enqueue_event(db, "invoice.created", payload.model_dump(mode="json") | {"invoice_id": invoice.id}, user_id=user.id)
    background.add_task(process_event_background, event.id)
    return {"status": "accepted", "invoice_id": invoice.id, "event_id": event.id}
