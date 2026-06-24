import httpx
from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session
from ..account_scope import account_user_ids
from ..auth import current_user, require_roles
from ..config import get_settings
from ..database import get_db
from ..models import ComplianceCheck, Customer, DemoWallet, FXRate, Invoice, Payment, Prediction, Role, Transaction, User
from ..schemas import ComplianceIn, CopilotIn, PredictionProxyIn
from ..services.compliance import evaluate_compliance

router = APIRouter(prefix="/api", tags=["intelligence"])


def insufficient(reason: str, required: list[str], observed: dict) -> dict:
    return {
        "data_status": "insufficient",
        "reason": reason,
        "required": required,
        "observed": observed,
    }


@router.post("/compliance/check", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def compliance_check(payload: ComplianceIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    result = evaluate_compliance(payload.model_dump())
    check = ComplianceCheck(user_id=user.id, entity_type=payload.entity_type, entity_id=payload.entity_id, score=result["score"], status=result["status"], recommendations=result["recommendations"])
    db.add(check)
    db.commit()
    return result | {"check_id": check.id}


@router.post("/compliance/current", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def current_compliance_check(db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    tx = (
        db.query(Transaction)
        .filter(Transaction.user_id.in_(scope))
        .order_by(Transaction.risk_score.desc(), Transaction.created_at.desc())
        .first()
    )
    if not tx:
        return insufficient(
            "No account transaction is available for compliance review.",
            ["At least one account transaction", "A known payer or counterparty"],
            {"transactions": 0},
        )

    payment = db.get(Payment, tx.payment_id) if tx.payment_id else None
    invoice = db.get(Invoice, payment.invoice_id) if payment and payment.invoice_id else None
    documents = (invoice.metadata_json or {}).get("documents", []) if invoice else []
    body = {
        "entity_type": "transaction",
        "entity_id": tx.id,
        "amount": tx.amount,
        "country": tx.country,
        "payer_name": tx.counterparty,
        "invoice_amount": invoice.amount if invoice else None,
        "documents": documents,
    }
    result = evaluate_compliance(body)
    check = ComplianceCheck(
        user_id=user.id,
        entity_type="transaction",
        entity_id=tx.id,
        score=result["score"],
        status=result["status"],
        recommendations=result["recommendations"],
    )
    db.add(check)
    db.commit()
    return result | {
        "check_id": check.id,
        "data_status": "ready",
        "source": {"transaction_id": tx.id, "counterparty": tx.counterparty},
    }


async def call_ml(path: str, payload: dict) -> dict:
    async with httpx.AsyncClient(timeout=12) as client:
        response = await client.post(f"{get_settings().ml_service_url}{path}", json=payload)
        response.raise_for_status()
        return response.json()


@router.post("/predict/payment-delay")
async def payment_delay(payload: PredictionProxyIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    invoice = db.query(Invoice).filter(Invoice.id == payload.invoice_id, Invoice.user_id.in_(scope)).first() if payload.invoice_id else None
    customer = db.get(Customer, invoice.customer_id) if invoice else None
    body = payload.payload | ({
        "invoice_amount": invoice.amount,
        "country": invoice.country,
        "currency": invoice.currency,
        "client_history": customer.avg_delay_days,
        "delay_count": customer.delayed_invoice_count,
        "days_until_due": (invoice.due_date - invoice.issued_at).days,
    } if invoice and customer else {})
    result = await call_ml("/predict/payment-delay", body)
    db.add(Prediction(user_id=user.id, prediction_type="payment-delay", entity_type="invoice", entity_id=payload.invoice_id, score=result["delay_risk"], output=result))
    db.commit()
    return result


@router.post("/predict/fx")
async def fx_prediction(payload: PredictionProxyIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    invoice_exposure = (
        db.query(Invoice.currency, func.sum(Invoice.amount))
        .filter(Invoice.user_id.in_(scope), Invoice.status == "pending")
        .group_by(Invoice.currency)
        .all()
    )
    transaction_exposure = (
        db.query(Transaction.currency, func.sum(Transaction.amount))
        .filter(Transaction.user_id.in_(scope))
        .group_by(Transaction.currency)
        .all()
    )
    exposure: dict[str, float] = {}
    for currency, amount in [*invoice_exposure, *transaction_exposure]:
        exposure[currency] = exposure.get(currency, 0) + float(amount or 0)
    if not exposure:
        return insufficient(
            "No currency exposure exists for this account yet.",
            ["A payment, transaction, or open invoice with a currency"],
            {"currencies": 0},
        )

    currency = max(exposure, key=exposure.get)
    rates = (
        db.query(FXRate)
        .filter(FXRate.base_currency == currency)
        .order_by(FXRate.as_of.desc())
        .limit(30)
        .all()
    )
    if len(rates) < 3:
        return insufficient(
            f"Not enough market-rate history is available for {currency}.",
            ["At least 3 market-rate observations"],
            {"currency": currency, "rate_observations": len(rates), "exposure": exposure[currency]},
        )

    body = {
        "currency": currency,
        "rates": [
            {
                "currency": r.base_currency,
                "rate": r.rate,
                "volatility": r.volatility_score,
                "date": r.as_of.isoformat(),
            }
            for r in reversed(rates)
        ],
    }
    result = await call_ml("/predict/fx", body)
    db.add(Prediction(user_id=user.id, prediction_type="fx", entity_type="currency", entity_id=None, score=result.get("volatility_score", 50), output=result))
    db.commit()
    return result | {
        "data_status": "ready",
        "source": {"currency": currency, "exposure": round(exposure[currency], 2), "rate_observations": len(rates)},
    }


@router.post("/predict/anomaly")
async def anomaly(payload: PredictionProxyIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    tx_query = db.query(Transaction).filter(Transaction.user_id.in_(scope))
    transactions = (
        tx_query.filter(Transaction.id == payload.transaction_id).all()
        if payload.transaction_id
        else tx_query.order_by(Transaction.created_at.desc()).limit(40).all()
    )
    if not transactions:
        return insufficient(
            "No account transaction is available for anomaly analysis.",
            ["At least one account transaction"],
            {"transactions": 0},
        )

    counterparty_counts = dict(
        db.query(Transaction.counterparty, func.count(Transaction.id))
        .filter(Transaction.user_id.in_(scope))
        .group_by(Transaction.counterparty)
        .all()
    )
    bodies = []
    for tx in transactions:
        payment = db.get(Payment, tx.payment_id) if tx.payment_id else None
        invoice = db.get(Invoice, payment.invoice_id) if payment and payment.invoice_id else None
        bodies.append({
            "amount": tx.amount,
            "country": tx.country,
            "currency": tx.currency,
            "hour": tx.created_at.hour,
            "risk_score": tx.risk_score,
            "first_time_payer": counterparty_counts.get(tx.counterparty, 0) == 1,
            "invoice_mismatch": bool(invoice and abs(invoice.amount - tx.amount) > max(invoice.amount * 0.05, 100)),
        })

    batch = await call_ml("/predict/anomaly/batch", {"items": bodies})
    peak_index, peak = max(enumerate(batch["items"]), key=lambda item: item[1]["anomaly_score"])
    peak_tx = transactions[peak_index]
    result = peak | {
        "average_score": batch["average_score"],
        "flagged_count": batch["flagged_count"],
    }
    db.add(Prediction(user_id=user.id, prediction_type="anomaly", entity_type="transaction", entity_id=peak_tx.id, score=result["anomaly_score"], output=result))
    db.commit()
    return result | {
        "data_status": "ready",
        "source": {
            "transaction_id": peak_tx.id,
            "counterparty": peak_tx.counterparty,
            "currency": peak_tx.currency,
            "transactions_analyzed": len(transactions),
        },
    }


@router.post("/predict/runway")
async def runway(payload: PredictionProxyIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id.in_(scope))
        .order_by(Transaction.created_at.desc())
        .limit(180)
        .all()
    )
    invoices = db.query(Invoice).filter(Invoice.user_id.in_(scope), Invoice.status == "pending").all()
    incoming = [tx.amount for tx in reversed(transactions) if tx.type == "inbound"]
    outgoing = [tx.amount for tx in transactions if tx.type == "outbound"]
    if not incoming or not outgoing:
        return insufficient(
            "Runway needs both incoming and outgoing account activity; fixed demo expenses are no longer used.",
            ["At least one incoming transaction", "At least one outgoing transaction"],
            {"incoming_transactions": len(incoming), "outgoing_transactions": len(outgoing), "pending_invoices": len(invoices)},
        )

    oldest = min(tx.created_at for tx in transactions)
    newest = max(tx.created_at for tx in transactions)
    observed_months = max((newest - oldest).days / 30, 1)
    monthly_outgoing = sum(outgoing) / observed_months
    wallets = db.query(DemoWallet).filter(DemoWallet.user_id.in_(scope)).all()
    wallet_cash = sum(wallet.balance_minor / 100 for wallet in wallets)
    net_transaction_cash = sum(tx.amount if tx.type == "inbound" else -tx.amount for tx in transactions)
    current_cash = wallet_cash if wallets else max(net_transaction_cash, 0)
    body = {
        "incoming_payments": incoming,
        "delayed_invoices": [i.amount for i in invoices],
        "expenses": monthly_outgoing,
        "payroll": 0,
        "subscriptions": 0,
        "current_cash": current_cash,
    }
    result = await call_ml("/predict/runway", body)
    db.add(Prediction(user_id=user.id, prediction_type="runway", entity_type="company", entity_id=None, score=result["projected_days"], output=result))
    db.commit()
    return result | {
        "data_status": "ready",
        "source": {
            "incoming_transactions": len(incoming),
            "outgoing_transactions": len(outgoing),
            "pending_invoices": len(invoices),
            "current_cash": round(current_cash, 2),
            "observed_monthly_outgoing": round(monthly_outgoing, 2),
        },
    }


@router.post("/copilot")
def copilot(payload: CopilotIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    q = payload.question.lower()
    scope = account_user_ids(db, user)
    pending = db.query(Invoice).filter(Invoice.user_id.in_(scope), Invoice.status == "pending").all()
    risky_customers = db.query(Customer).filter(Customer.user_id.in_(scope), Customer.risk_rating.in_(["Medium", "High"])).all()
    recent_predictions = db.query(Prediction).filter(Prediction.user_id.in_(scope)).order_by(Prediction.created_at.desc()).limit(8).all()
    exposure = {}
    for invoice in pending:
        exposure[invoice.currency] = exposure.get(invoice.currency, 0) + invoice.amount

    if "usd" in q or "conversion" in q or "fx" in q:
        answer = f"USD conversion can be staged. Current open exposure is {exposure or 'not available yet for this account'}. Recent FX intelligence favors partial conversion when volatility is above 55, so avoid an all-at-once conversion unless payroll timing requires it."
    elif "cash" in q or "runway" in q:
        from datetime import date
        overdue = sum(1 for i in pending if i.due_date < date.today())
        answer = f"Cash flow risk is medium: {len(pending)} invoices are pending and {overdue} are overdue. The most useful action is accelerating high-value receivables before new discretionary spend."
    elif "dangerous" in q or "risky" in q or "invoices" in q:
        top = sorted(pending, key=lambda i: i.amount, reverse=True)[:3]
        answer = "No invoices are available for this account yet." if not top else "Highest attention invoices: " + ", ".join(f"{i.invoice_number} {i.currency} {i.amount:,.0f} in {i.country}" for i in top)
    else:
        answer = f"I checked live system state: {len(pending)} pending invoices, {len(risky_customers)} medium/high-risk customers, and {len(recent_predictions)} recent model outputs. Ask about FX, runway, or risky invoices for a tighter recommendation."
    return {"answer": answer, "state_used": {"pending_invoices": len(pending), "currency_exposure": exposure, "recent_predictions": [p.output for p in recent_predictions[:3]]}}
