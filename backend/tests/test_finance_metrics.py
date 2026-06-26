from datetime import date, datetime, timedelta

from app.models import DemoWallet, FXRate, Invoice, Payment, Transaction
from app.services.finance_metrics import dashboard_metrics


def test_dashboard_uses_real_transaction_direction_and_currency_conversion():
    now = datetime(2026, 6, 25, 12, 0)
    metrics = dashboard_metrics(
        payments=[
            Payment(amount=100, currency="USD", status="settled"),
            Payment(amount=100, currency="EUR", status="settled"),
            Payment(amount=999, currency="USD", status="processing"),
        ],
        transactions=[
            Transaction(type="inbound", amount=3000, currency="USD", country="US", counterparty="Client", risk_score=20, created_at=now - timedelta(days=60)),
            Transaction(type="outbound", amount=1000, currency="USD", country="US", counterparty="Payroll", risk_score=10, created_at=now),
        ],
        invoices=[],
        wallets=[DemoWallet(balance_minor=500_000, currency="USD")],
        fx_rates=[FXRate(base_currency="EUR", quote_currency="USD", rate=1.2, volatility_score=4, as_of=date(2026, 6, 25))],
        reporting_currency="USD",
    )

    assert metrics["total_volume"] == 220
    assert metrics["volume_by_currency"] == {"EUR": 100.0, "USD": 100.0}
    assert metrics["cash_flow"][0]["incoming"] == 3000
    assert metrics["cash_flow"][0]["expenses"] == 0
    assert metrics["cash_flow"][1]["incoming"] == 0
    assert metrics["cash_flow"][1]["expenses"] == 1000
    assert metrics["cash_runway"] == 300


def test_dashboard_discloses_missing_conversion_and_withholds_runway():
    now = datetime(2026, 6, 25, 12, 0)
    metrics = dashboard_metrics(
        payments=[Payment(amount=100, currency="JPY", status="settled")],
        transactions=[
            Transaction(type="outbound", amount=500, currency="JPY", country="JP", counterparty="Vendor", risk_score=30, created_at=now),
        ],
        invoices=[
            Invoice(
                workspace_key="test-workspace",
                invoice_number="INV-TEST",
                customer_id=1,
                amount=200,
                currency="JPY",
                country="JP",
                status="pending",
                issued_at=date(2026, 6, 1),
                due_date=date(2026, 7, 1),
            )
        ],
        wallets=[DemoWallet(balance_minor=100_000, currency="USD")],
        fx_rates=[],
        reporting_currency="USD",
    )

    assert metrics["conversion_complete"] is False
    assert metrics["unconverted_currencies"] == ["JPY"]
    assert metrics["cash_runway"] is None
    assert metrics["pending_invoices"] == 1
