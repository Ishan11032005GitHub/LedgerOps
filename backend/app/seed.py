from datetime import date, datetime, timedelta
from random import Random
from sqlalchemy.orm import Session
from .auth import hash_password
from .models import Alert, Customer, DemoWallet, FXRate, Invoice, Payment, PaymentMethod, Role, Transaction, User


DEMO_USERS = (
    {"email": "asha.demo@ledgerops.ai", "name": "Asha Mehta", "password": "DemoPass123", "balance_minor": 2500000, "card": ("RuPay", "4242")},
    {"email": "rohan.demo@ledgerops.ai", "name": "Rohan Kapoor", "password": "DemoPass123", "balance_minor": 1800000, "card": ("Visa", "1881")},
)


def ensure_demo_accounts(db: Session) -> None:
    for spec in DEMO_USERS:
        user = db.query(User).filter(User.email == spec["email"]).first()
        if not user:
            user = User(
                email=spec["email"],
                name=spec["name"],
                account_type="individual",
                workspace_name=f"{spec['name']}'s demo wallet",
                hashed_password=hash_password(spec["password"]),
                role=Role.admin,
            )
            db.add(user)
            db.flush()
        if not db.query(DemoWallet).filter(DemoWallet.user_id == user.id).first():
            db.add(DemoWallet(user_id=user.id, balance_minor=spec["balance_minor"], currency="INR"))
        if not db.query(PaymentMethod).filter(PaymentMethod.user_id == user.id).first():
            brand, last_four = spec["card"]
            db.add(PaymentMethod(
                user_id=user.id,
                label="Demo card",
                cardholder_name=user.name,
                brand=brand,
                last_four=last_four,
                expiry_month=12,
                expiry_year=2029,
                is_default=True,
            ))
    db.commit()


def seed(db: Session) -> None:
    ensure_demo_accounts(db)
    demo_emails = [item["email"] for item in DEMO_USERS]
    if db.query(User).filter(~User.email.in_(demo_emails)).first():
        return

    admin = User(email="admin@ledgerops.ai", name="Avery Shah", account_type="company", workspace_name="LedgerOps workspace", hashed_password=hash_password("AdminPass123"), role=Role.admin)
    db.add_all([
        admin,
        User(email="finance@ledgerops.ai", name="Mira Chen", account_type="company", workspace_name="LedgerOps workspace", hashed_password=hash_password("FinancePass123"), role=Role.finance_manager),
        User(email="viewer@ledgerops.ai", name="Leo Grant", account_type="company", workspace_name="LedgerOps workspace", hashed_password=hash_password("ViewerPass123"), role=Role.viewer),
    ])
    db.flush()

    customers = [
        Customer(user_id=admin.id, name="Northstar Robotics", country="US", currency="USD", risk_rating="Low", avg_delay_days=2, delayed_invoice_count=1, kyc_status="Verified"),
        Customer(user_id=admin.id, name="Kairo Retail Group", country="AE", currency="AED", risk_rating="Medium", avg_delay_days=7, delayed_invoice_count=3, kyc_status="Verified"),
        Customer(user_id=admin.id, name="Blue Harbor GmbH", country="DE", currency="EUR", risk_rating="Low", avg_delay_days=1, delayed_invoice_count=0, kyc_status="Verified"),
        Customer(user_id=admin.id, name="Sakura Supply KK", country="JP", currency="JPY", risk_rating="Medium", avg_delay_days=9, delayed_invoice_count=4, kyc_status="Review"),
        Customer(user_id=admin.id, name="Atlas Minerals", country="ZA", currency="ZAR", risk_rating="High", avg_delay_days=13, delayed_invoice_count=5, kyc_status="Review"),
        Customer(user_id=admin.id, name="Maple Cloud Ltd", country="CA", currency="CAD", risk_rating="Low", avg_delay_days=3, delayed_invoice_count=1, kyc_status="Verified"),
    ]
    db.add_all(customers)
    db.flush()

    rng = Random(42)
    today = date.today()
    invoices: list[Invoice] = []
    payments: list[Payment] = []
    transactions: list[Transaction] = []
    for idx in range(42):
        customer = customers[idx % len(customers)]
        issued = today - timedelta(days=idx * 6 + 8)
        due = issued + timedelta(days=30)
        amount = round(rng.uniform(3500, 85000), 2)
        paid = idx % 4 != 0
        paid_at = due + timedelta(days=rng.randint(-3, 16)) if paid else None
        invoice = Invoice(
            user_id=admin.id,
            invoice_number=f"INV-{2026}-{1000 + idx}",
            customer_id=customer.id,
            amount=amount,
            currency=customer.currency,
            country=customer.country,
            status="paid" if paid else "pending",
            issued_at=issued,
            due_date=due,
            paid_at=paid_at,
            metadata_json={"contract": "cross-border services", "payment_terms": "net30"},
        )
        invoices.append(invoice)
        db.add(invoice)
        db.flush()
        if paid:
            payment = Payment(
                user_id=admin.id,
                invoice_id=invoice.id,
                customer_id=customer.id,
                amount=amount,
                currency=customer.currency,
                country=customer.country,
                status="settled",
                rail="ACH" if customer.country in {"US", "CA"} else "SWIFT",
                received_at=datetime.combine(paid_at, datetime.min.time()) + timedelta(hours=rng.randint(8, 22)),
                external_ref=f"pay_{idx:05d}",
            )
            payments.append(payment)
            db.add(payment)
            db.flush()
            transactions.append(Transaction(
                payment_id=payment.id,
                user_id=admin.id,
                type="inbound",
                amount=amount,
                currency=customer.currency,
                country=customer.country,
                counterparty=customer.name,
                risk_score=min(92, customer.avg_delay_days * 4 + rng.randint(8, 30)),
                created_at=payment.received_at,
            ))

    fx_series = {"EUR": 1.08, "GBP": 1.26, "JPY": 0.0067, "AED": 0.272, "CAD": 0.73, "ZAR": 0.054, "USD": 1.0}
    for ccy, base in fx_series.items():
        for day in range(30):
            db.add(FXRate(
                base_currency=ccy,
                quote_currency="USD",
                rate=round(base * (1 + rng.uniform(-0.025, 0.025)), 5),
                volatility_score=round(rng.uniform(12, 78), 2),
                as_of=today - timedelta(days=day),
            ))
    db.add_all(transactions)
    db.add_all([
        Alert(user_id=admin.id, severity="high", category="fraud", message="JPY payment pattern changed outside normal settlement window.", entity_type="transaction", entity_id=8),
        Alert(user_id=admin.id, severity="medium", category="fx", message="EUR exposure rose 18% while volatility is trending upward.", entity_type="fx", entity_id=None),
        Alert(user_id=admin.id, severity="medium", category="cash", message="Delayed invoices could reduce runway below 60 days.", entity_type="forecast", entity_id=None),
    ])
    db.commit()
