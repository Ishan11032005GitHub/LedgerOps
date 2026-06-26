import httpx
import json
from collections import defaultdict
from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session
from ..account_scope import account_user_ids
from ..auth import current_user, require_roles
from ..config import get_settings
from ..database import get_db
from ..models import AccountPreference, Alert, ComplianceCheck, Customer, DemoWallet, FXRate, Invoice, Payment, PaymentMethod, Prediction, Role, Transaction, User
from ..schemas import ComplianceIn, CopilotIn, PredictionProxyIn
from ..services.compliance import evaluate_compliance
from ..services.gemini import generate_finance_answer

router = APIRouter(prefix="/api", tags=["intelligence"])


def insufficient(reason: str, required: list[str], observed: dict) -> dict:
    return {
        "data_status": "insufficient",
        "reason": reason,
        "required": required,
        "observed": observed,
    }


def confidence_from_sample(sample_count: int, medium_at: int, high_at: int) -> str:
    if sample_count >= high_at:
        return "High"
    if sample_count >= medium_at:
        return "Medium"
    return "Low"


def account_currency(db: Session, user: User) -> str:
    preference = db.query(AccountPreference).filter(AccountPreference.user_id == user.id).first()
    if preference and preference.currency:
        return preference.currency.upper()
    wallet = db.query(DemoWallet).filter(DemoWallet.user_id == user.id).first()
    return wallet.currency.upper() if wallet and wallet.currency else "USD"


@router.post("/compliance/check", dependencies=[Depends(require_roles(Role.admin, Role.finance_manager))])
def compliance_check(payload: ComplianceIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    result = evaluate_compliance(payload.model_dump())
    check = ComplianceCheck(user_id=user.id, entity_type=payload.entity_type, entity_id=payload.entity_id, score=result["score"], status=result["status"], recommendations=result["recommendations"])
    db.add(check)
    db.commit()
    return result | {"check_id": check.id, "confidence": "Medium"}


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
        "confidence": "High" if invoice and "kyc" in [str(item).lower() for item in documents] else "Medium" if invoice or documents else "Low",
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
    history_count = customer.delayed_invoice_count + 1 if customer else 0
    result["confidence"] = confidence_from_sample(history_count, 3, 8)
    db.add(Prediction(user_id=user.id, prediction_type="payment-delay", entity_type="invoice", entity_id=payload.invoice_id, score=result["delay_risk"], output=result))
    db.commit()
    return result


@router.post("/predict/fx")
async def fx_prediction(payload: PredictionProxyIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    scope = account_user_ids(db, user)
    native_currency = account_currency(db, user)
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
    foreign_exposure = {currency: amount for currency, amount in exposure.items() if currency.upper() != native_currency}
    if not foreign_exposure:
        return insufficient(
            f"No foreign-currency exposure exists relative to the account's {native_currency} reporting currency.",
            ["A payment, transaction, or open invoice in a currency different from the reporting currency"],
            {"native_currency": native_currency, "foreign_currencies": 0},
        )

    currency = max(foreign_exposure, key=foreign_exposure.get)
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
            {"currency": currency, "native_currency": native_currency, "rate_observations": len(rates), "exposure": foreign_exposure[currency]},
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
    result["confidence"] = confidence_from_sample(len(rates), 8, 20)
    db.add(Prediction(user_id=user.id, prediction_type="fx", entity_type="currency", entity_id=None, score=result.get("volatility_score", 50), output=result))
    db.commit()
    return result | {
        "data_status": "ready",
        "source": {
            "currency": currency,
            "native_currency": native_currency,
            "exposure": round(foreign_exposure[currency], 2),
            "rate_observations": len(rates),
        },
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
        "confidence": confidence_from_sample(len(transactions), 10, 30),
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
    observation_days = max((newest - oldest).days, 0)
    sample_count = len(incoming) + len(outgoing)
    result["confidence"] = "High" if sample_count >= 20 and observation_days >= 90 else "Medium" if sample_count >= 6 and observation_days >= 30 else "Low"
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
            "observation_days": observation_days,
        },
    }


def money_label(amount: float, currency: str) -> str:
    return f"{currency} {amount:,.2f}"


def finance_snapshot(db: Session, user: User) -> dict:
    scope = account_user_ids(db, user)
    native_currency = account_currency(db, user)
    transactions = db.query(Transaction).filter(Transaction.user_id.in_(scope)).order_by(Transaction.created_at.desc()).limit(250).all()
    payments = db.query(Payment).filter(Payment.user_id.in_(scope)).order_by(Payment.received_at.desc()).limit(150).all()
    invoices = db.query(Invoice).filter(Invoice.user_id.in_(scope)).order_by(Invoice.due_date.asc()).limit(150).all()
    customers = db.query(Customer).filter(Customer.user_id.in_(scope)).order_by(Customer.name.asc()).all()
    alerts = db.query(Alert).filter(Alert.user_id.in_(scope), Alert.is_resolved.is_(False)).order_by(Alert.created_at.desc()).limit(20).all()
    predictions = db.query(Prediction).filter(Prediction.user_id.in_(scope)).order_by(Prediction.created_at.desc()).limit(12).all()
    wallets = db.query(DemoWallet).filter(DemoWallet.user_id.in_(scope)).all()
    methods = db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).order_by(PaymentMethod.is_default.desc()).all()

    inflow_by_currency: dict[str, float] = defaultdict(float)
    outflow_by_currency: dict[str, float] = defaultdict(float)
    counterparty_totals: dict[str, float] = defaultdict(float)
    for tx in transactions:
        target = inflow_by_currency if tx.type == "inbound" else outflow_by_currency
        target[tx.currency] += tx.amount
        counterparty_totals[tx.counterparty] += tx.amount

    pending = [invoice for invoice in invoices if invoice.status == "pending"]
    overdue = [invoice for invoice in pending if invoice.due_date < date.today()]
    pending_by_currency: dict[str, float] = defaultdict(float)
    for invoice in pending:
        pending_by_currency[invoice.currency] += invoice.amount

    verified_statuses = {"verified", "demo verified", "approved", "clear"}
    risky_customers = [
        customer
        for customer in customers
        if customer.risk_rating in {"Medium", "High"}
        or customer.kyc_status.strip().lower() not in verified_statuses
    ]
    wallet_balances = [{"currency": wallet.currency, "amount": wallet.balance_minor / 100} for wallet in wallets]
    top_counterparties = sorted(counterparty_totals.items(), key=lambda item: item[1], reverse=True)[:5]

    return {
        "account": {
            "name": user.name,
            "email": user.email,
            "account_type": user.account_type,
            "workspace": user.workspace_name,
            "role": user.role.value,
            "reporting_currency": native_currency,
        },
        "balances": wallet_balances,
        "transactions": {
            "count": len(transactions),
            "inflow_by_currency": dict(inflow_by_currency),
            "outflow_by_currency": dict(outflow_by_currency),
            "recent": [
                {
                    "id": tx.id,
                    "type": tx.type,
                    "amount": tx.amount,
                    "currency": tx.currency,
                    "counterparty": tx.counterparty,
                    "country": tx.country,
                    "risk_score": tx.risk_score,
                    "created_at": tx.created_at.isoformat(),
                }
                for tx in transactions[:12]
            ],
        },
        "payments": {
            "count": len(payments),
            "settled_count": sum(payment.status == "settled" for payment in payments),
            "processing_count": sum(payment.status == "processing" for payment in payments),
        },
        "invoices": {
            "count": len(invoices),
            "pending_count": len(pending),
            "overdue_count": len(overdue),
            "pending_by_currency": dict(pending_by_currency),
            "largest_pending": [
                {
                    "invoice_number": invoice.invoice_number,
                    "amount": invoice.amount,
                    "currency": invoice.currency,
                    "due_date": invoice.due_date.isoformat(),
                    "country": invoice.country,
                }
                for invoice in sorted(pending, key=lambda item: item.amount, reverse=True)[:5]
            ],
            "pending_items": [
                {
                    "invoice_number": invoice.invoice_number,
                    "amount": invoice.amount,
                    "currency": invoice.currency,
                    "due_date": invoice.due_date.isoformat(),
                    "country": invoice.country,
                }
                for invoice in pending[:30]
            ],
        },
        "customers": {
            "count": len(customers),
            "requiring_review": [
                {
                    "name": customer.name,
                    "risk_rating": customer.risk_rating,
                    "kyc_status": customer.kyc_status,
                    "avg_delay_days": customer.avg_delay_days,
                    "delayed_invoice_count": customer.delayed_invoice_count,
                }
                for customer in risky_customers[:10]
            ],
        },
        "alerts": [
            {"severity": alert.severity, "category": alert.category, "message": alert.message}
            for alert in alerts
        ],
        "recent_predictions": [
            {"type": prediction.prediction_type, "score": prediction.score, "output": prediction.output}
            for prediction in predictions
        ],
        "payment_methods": [
            {"label": method.label, "brand": method.brand, "last_four": method.last_four, "is_default": method.is_default}
            for method in methods
        ],
        "top_counterparties": [{"name": name, "gross_activity": amount} for name, amount in top_counterparties],
    }


def snapshot_confidence(snapshot: dict) -> str:
    count = snapshot["transactions"]["count"]
    if count >= 30:
        return "High"
    if count >= 10:
        return "Medium"
    return "Low"


def prompt_attack_detected(question: str) -> bool:
    normalized = question.lower()
    markers = [
        "ignore previous",
        "ignore all instructions",
        "system prompt",
        "developer message",
        "reveal your prompt",
        "show hidden instructions",
        "api key",
        "secret key",
        "authentication token",
    ]
    return any(marker in normalized for marker in markers)


def summarize_amounts(values: dict[str, float]) -> str:
    if not values:
        return "none recorded"
    return ", ".join(money_label(amount, currency) for currency, amount in sorted(values.items()))


def copilot_answer(question: str, snapshot: dict, history: list[dict]) -> tuple[str, list[str]]:
    q = question.lower()
    previous = next((item.get("text", "") for item in reversed(history) if item.get("role") == "user"), "")
    if previous and any(marker in q for marker in ["what about", "and ", "also", "that", "those", "it?"]):
        q = f"{previous.lower()} {q}"
    account = snapshot["account"]
    transactions = snapshot["transactions"]
    invoices = snapshot["invoices"]
    customers = snapshot["customers"]
    sources = []

    if any(term in q for term in ["balance", "cash available", "how much money"]):
        sources.append("account balances")
        balances = snapshot["balances"]
        answer = "Available balances: " + (", ".join(money_label(item["amount"], item["currency"]) for item in balances) if balances else "no linked balance is available yet.")
    elif any(term in q for term in ["spend", "spent", "expense", "outflow", "paid out"]):
        sources.extend(["transaction ledger", "outbound transactions"])
        answer = f"Recorded outflows are {summarize_amounts(transactions['outflow_by_currency'])}. This is based on {transactions['count']} recent ledger transactions; use category-level expense data before making a budget cut."
    elif any(term in q for term in ["income", "revenue", "inflow", "received"]):
        sources.extend(["transaction ledger", "inbound transactions"])
        answer = f"Recorded inflows are {summarize_amounts(transactions['inflow_by_currency'])}. Treat this as cash received, not accounting revenue, unless the underlying payments have been reconciled."
    elif any(term in q for term in ["invoice", "receivable", "collect", "overdue", "dangerous"]):
        sources.append("invoice ledger")
        requested_currency = next((currency for currency in invoices["pending_by_currency"] if currency.lower() in q), None)
        candidates = [item for item in invoices["pending_items"] if not requested_currency or item["currency"] == requested_currency]
        largest = sorted(candidates, key=lambda item: item["amount"], reverse=True)[:5]
        detail = "; ".join(f"{item['invoice_number']} for {money_label(item['amount'], item['currency'])}, due {item['due_date']}" for item in largest)
        scope_label = f" in {requested_currency}" if requested_currency else ""
        answer = f"There are {invoices['pending_count']} pending invoices and {invoices['overdue_count']} overdue{scope_label}. " + (f"Highest-value items{scope_label}: {detail}." if detail else f"No open receivables{scope_label} are recorded.")
    elif any(term in q for term in ["customer", "payer", "kyc", "review"]):
        sources.append("customer risk records")
        review = customers["requiring_review"]
        detail = "; ".join(f"{item['name']} ({item['risk_rating']} risk, KYC {item['kyc_status']}, average delay {item['avg_delay_days']} days)" for item in review[:5])
        answer = f"{len(review)} customers currently need attention. " + (detail if detail else "No customer review flags are recorded.")
    elif any(term in q for term in ["fraud", "anomaly", "suspicious", "risk"]):
        sources.extend(["transaction risk scores", "recent intelligence outputs", "open alerts"])
        anomaly = next((item for item in snapshot["recent_predictions"] if item["type"] == "anomaly"), None)
        alert_text = "; ".join(item["message"] for item in snapshot["alerts"][:3])
        if anomaly:
            output = anomaly["output"]
            answer = f"The latest anomaly analysis scored {output.get('anomaly_score', anomaly['score'])}/100 with {output.get('flagged_count', 0)} flagged transactions. {alert_text or 'No unresolved risk alerts are recorded.'}"
        else:
            answer = f"No completed anomaly analysis is stored yet. {alert_text or 'No unresolved risk alerts are recorded.'}"
    elif any(term in q for term in ["fx", "currency", "convert", "exchange"]):
        sources.extend(["reporting currency", "open invoice exposure", "recent FX intelligence"])
        foreign = {currency: amount for currency, amount in invoices["pending_by_currency"].items() if currency != account["reporting_currency"]}
        prediction = next((item for item in snapshot["recent_predictions"] if item["type"] == "fx"), None)
        recommendation = prediction["output"].get("recommendation") if prediction else None
        answer = f"The reporting currency is {account['reporting_currency']}. Open foreign-currency receivables are {summarize_amounts(foreign)}. " + (f"Latest staged-conversion guidance: {recommendation}." if recommendation else "Run FX Intelligence after rate history is available before converting.")
    elif any(term in q for term in ["runway", "survive", "burn", "cash flow"]):
        sources.extend(["account balances", "inflows and outflows", "runway intelligence"])
        prediction = next((item for item in snapshot["recent_predictions"] if item["type"] == "runway"), None)
        if prediction:
            output = prediction["output"]
            answer = f"The latest runway estimate is {output.get('projected_days', prediction['score'])} days with {output.get('risk', 'unclassified')} risk and {output.get('confidence', 'Low')} confidence. Recalculate after material payments or expenses."
        else:
            answer = "No runway result is stored yet. LedgerOps needs both incoming and outgoing transaction history before it can produce one."
    elif any(term in q for term in ["payment", "settlement", "processing"]):
        sources.append("payment ledger")
        payment_data = snapshot["payments"]
        answer = f"The account has {payment_data['count']} recent payments: {payment_data['settled_count']} settled and {payment_data['processing_count']} processing."
    elif any(term in q for term in ["what should", "recommend", "priority", "priorities", "next action", "help me"]):
        sources.extend(["invoices", "customers", "alerts", "cash activity"])
        actions = []
        if invoices["overdue_count"]:
            actions.append(f"collect {invoices['overdue_count']} overdue invoices")
        if customers["requiring_review"]:
            actions.append(f"review {len(customers['requiring_review'])} customer risk/KYC records")
        if snapshot["alerts"]:
            actions.append(f"resolve {len(snapshot['alerts'])} open alerts")
        if not transactions["outflow_by_currency"]:
            actions.append("connect or record outgoing expenses so runway becomes reliable")
        answer = "Highest-priority actions: " + ("; ".join(actions) if actions else "no urgent account-data issue is visible; review cash allocation and upcoming obligations.")
    else:
        sources.extend(["account snapshot", "payments", "invoices", "customers", "alerts"])
        follow_up = f" I also considered your previous question: “{previous[:120]}”." if previous else ""
        answer = (
            f"I reviewed {account['workspace'] or account['name']}: {transactions['count']} transactions, "
            f"{invoices['pending_count']} pending invoices, {invoices['overdue_count']} overdue invoices, "
            f"{len(customers['requiring_review'])} customer review items, and {len(snapshot['alerts'])} open alerts."
            f"{follow_up} Ask for balances, spending, collections, FX, runway, fraud, compliance, customers, or priorities."
        )
    return answer, sources


@router.post("/copilot")
async def copilot(payload: CopilotIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    snapshot = finance_snapshot(db, user)
    confidence = snapshot_confidence(snapshot)
    fallback_answer, fallback_sources = copilot_answer(payload.question, snapshot, payload.history[-8:])
    if prompt_attack_detected(payload.question):
        return {
            "answer": "I cannot reveal hidden instructions, credentials, or authentication data. I can still help with the financial records available in this workspace.",
            "confidence": confidence,
            "sources": ["workspace security policy"],
            "model": "LedgerOps safety policy",
            "as_of": date.today().isoformat(),
            "state_used": {},
            "notice": "No account secrets or hidden instructions were disclosed.",
        }
    provider = "LedgerOps grounded fallback"
    answer = fallback_answer
    sources = fallback_sources
    try:
        generated = await generate_finance_answer(payload.question, snapshot, payload.history[-8:], confidence)
        if generated:
            answer = generated["answer"]
            sources = fallback_sources
            provider = generated["model"]
    except (httpx.HTTPError, json.JSONDecodeError, KeyError, TypeError, ValueError):
        pass
    return {
        "answer": answer,
        "confidence": confidence,
        "sources": sources,
        "model": provider,
        "as_of": date.today().isoformat(),
        "state_used": {
            "reporting_currency": snapshot["account"]["reporting_currency"],
            "transaction_count": snapshot["transactions"]["count"],
            "pending_invoices": snapshot["invoices"]["pending_count"],
            "overdue_invoices": snapshot["invoices"]["overdue_count"],
            "customer_review_items": len(snapshot["customers"]["requiring_review"]),
            "open_alerts": len(snapshot["alerts"]),
        },
        "notice": "Operational guidance based on LedgerOps account data. Confirm material tax, legal, investment, lending, and regulatory decisions with a qualified professional.",
    }
