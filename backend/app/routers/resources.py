from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..account_scope import account_user_ids
from ..auth import current_user
from ..database import get_db
from ..models import AccountPreference, Alert, Customer, DemoWallet, FXRate, Invoice, Payment, Transaction, User
from ..services.finance_metrics import dashboard_metrics

router = APIRouter(prefix="/api", tags=["finance"])


def rows(items):
    return [item.__dict__ | {"_sa_instance_state": None} for item in items]


def visible_payment_fields(user: User) -> set[str]:
    base = {"id", "recipient", "amount", "currency", "status", "rail", "country"}
    if user.role.value in {"Admin", "Finance Manager"}:
        return base | {"external_ref", "invoice_id"}
    return base


def filter_fields(record: dict, allowed: set[str]) -> dict:
    return {key: value for key, value in record.items() if key in allowed}


@router.get("/payments")
def payments(db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    records = db.query(Payment, Customer).join(Customer, Payment.customer_id == Customer.id).filter(Payment.user_id.in_(scope)).order_by(Payment.received_at.desc()).limit(100).all()
    allowed = visible_payment_fields(user)
    return [
        filter_fields(
        {
            "id": payment.id,
            "recipient": customer.name,
            "country": payment.country,
            "rail": payment.rail,
            "external_ref": payment.external_ref,
            "invoice_id": payment.invoice_id,
            "amount": payment.amount,
            "currency": payment.currency,
            "status": payment.status,
        },
        allowed,
        )
        for payment, customer in records
    ]


@router.get("/invoices")
def invoices(db: Session = Depends(get_db), user: User = Depends(current_user)):
    return db.query(Invoice).filter(Invoice.user_id.in_(account_user_ids(db, user))).order_by(Invoice.due_date.asc()).limit(100).all()


@router.get("/customers")
def customers(db: Session = Depends(get_db), user: User = Depends(current_user)):
    return db.query(Customer).filter(Customer.user_id.in_(account_user_ids(db, user))).order_by(Customer.name.asc()).all()


@router.get("/transactions")
def transactions(db: Session = Depends(get_db), user: User = Depends(current_user)):
    return db.query(Transaction).filter(Transaction.user_id.in_(account_user_ids(db, user))).order_by(Transaction.created_at.desc()).limit(150).all()


@router.get("/fx-rates")
def fx_rates(db: Session = Depends(get_db), user: User = Depends(current_user)):
    return db.query(FXRate).order_by(FXRate.as_of.desc()).limit(250).all()


@router.get("/alerts")
def alerts(db: Session = Depends(get_db), user: User = Depends(current_user)):
    return db.query(Alert).filter(Alert.user_id.in_(account_user_ids(db, user))).order_by(Alert.created_at.desc()).limit(30).all()


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    preference = db.query(AccountPreference).filter(AccountPreference.user_id == user.id).first()
    reporting_currency = preference.currency.upper() if preference and preference.currency else "USD"
    payments = db.query(Payment).filter(Payment.user_id.in_(scope)).order_by(Payment.received_at.asc()).all()
    transactions = db.query(Transaction).filter(Transaction.user_id.in_(scope)).order_by(Transaction.created_at.asc()).all()
    invoices = db.query(Invoice).filter(Invoice.user_id.in_(scope)).all()
    wallets = db.query(DemoWallet).filter(DemoWallet.user_id.in_(scope)).all()
    fx = db.query(FXRate).order_by(FXRate.as_of.asc()).all() if payments or transactions or invoices else []
    alerts = db.query(Alert).filter(Alert.user_id.in_(scope)).order_by(Alert.created_at.desc()).limit(8).all()
    fx_trends = [{"date": rate.as_of.isoformat(), "currency": rate.base_currency, "rate": rate.rate, "volatility": rate.volatility_score} for rate in fx[-90:]]
    metrics = dashboard_metrics(
        payments=payments,
        transactions=transactions,
        invoices=invoices,
        wallets=wallets,
        fx_rates=fx,
        reporting_currency=reporting_currency,
    )
    return metrics | {
        "alerts": [{"severity": a.severity, "category": a.category, "message": a.message} for a in alerts],
        "fx_trends": fx_trends,
    }
