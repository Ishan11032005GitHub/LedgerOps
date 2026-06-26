from collections import defaultdict
from datetime import datetime
from decimal import Decimal

from ..models import DemoWallet, FXRate, Invoice, Payment, Transaction


ZERO = Decimal("0")


def money(value) -> Decimal:
    return Decimal(str(value or 0))


def latest_conversion_rates(rates: list[FXRate], reporting_currency: str) -> dict[str, Decimal]:
    reporting = reporting_currency.upper()
    conversions = {reporting: Decimal("1")}
    latest: dict[tuple[str, str], FXRate] = {}
    for rate in rates:
        pair = (rate.base_currency.upper(), rate.quote_currency.upper())
        if pair not in latest or rate.as_of > latest[pair].as_of:
            latest[pair] = rate

    for (base, quote), rate in latest.items():
        value = money(rate.rate)
        if value <= 0:
            continue
        if quote == reporting:
            conversions[base] = value
        elif base == reporting:
            conversions[quote] = Decimal("1") / value
    return conversions


def convert_amount(amount, currency: str, conversions: dict[str, Decimal]) -> Decimal | None:
    rate = conversions.get(currency.upper())
    return money(amount) * rate if rate is not None else None


def dashboard_metrics(
    *,
    payments: list[Payment],
    transactions: list[Transaction],
    invoices: list[Invoice],
    wallets: list[DemoWallet],
    fx_rates: list[FXRate],
    reporting_currency: str,
) -> dict:
    reporting = reporting_currency.upper()
    conversions = latest_conversion_rates(fx_rates, reporting)
    settled_volume = defaultdict(lambda: ZERO)
    converted_total = ZERO
    unconverted_currencies: set[str] = set()

    for payment in payments:
        if payment.status != "settled":
            continue
        currency = payment.currency.upper()
        settled_volume[currency] += money(payment.amount)
        converted = convert_amount(payment.amount, currency, conversions)
        if converted is None:
            unconverted_currencies.add(currency)
        else:
            converted_total += converted

    monthly = defaultdict(lambda: {"incoming": ZERO, "expenses": ZERO, "volume": ZERO})
    country_volume = defaultdict(lambda: ZERO)
    exposure = defaultdict(lambda: ZERO)
    anomalies = []
    converted_inflow = ZERO
    converted_outflow = ZERO
    converted_wallet_cash = ZERO
    transaction_dates: list[datetime] = []

    for tx in transactions:
        month = tx.created_at.strftime("%Y-%m")
        amount = money(tx.amount)
        exposure[tx.currency.upper()] += amount
        transaction_dates.append(tx.created_at)
        converted = convert_amount(amount, tx.currency, conversions)
        if converted is None:
            unconverted_currencies.add(tx.currency.upper())
        else:
            monthly[month]["volume"] += converted
            direction = "expenses" if tx.type == "outbound" else "incoming"
            monthly[month][direction] += converted
            country_volume[tx.country] += converted
            if tx.type == "outbound":
                converted_outflow += converted
            else:
                converted_inflow += converted
        if tx.risk_score >= 65:
            anomalies.append(
                {
                    "name": tx.counterparty,
                    "score": round(float(tx.risk_score), 1),
                    "amount": float(amount),
                    "currency": tx.currency.upper(),
                }
            )

    pending = [invoice for invoice in invoices if invoice.status == "pending"]
    for invoice in pending:
        exposure[invoice.currency.upper()] += money(invoice.amount)

    for wallet in wallets:
        converted = convert_amount(Decimal(wallet.balance_minor) / 100, wallet.currency, conversions)
        if converted is None:
            unconverted_currencies.add(wallet.currency.upper())
        else:
            converted_wallet_cash += converted

    observed_days = 0
    if transaction_dates:
        observed_days = max((max(transaction_dates) - min(transaction_dates)).days, 1)
    observed_months = max(Decimal(observed_days) / Decimal(30), Decimal("1"))
    monthly_burn = converted_outflow / observed_months
    current_cash = converted_wallet_cash if wallets else max(converted_inflow - converted_outflow, ZERO)
    runway = None
    if monthly_burn > 0 and not unconverted_currencies:
        runway = min(365, max(0, int((current_cash / monthly_burn) * 30)))

    risk_score = (
        round(sum(float(tx.risk_score) for tx in transactions) / len(transactions), 1)
        if transactions
        else 0
    )

    return {
        "reporting_currency": reporting,
        "total_volume": round(float(converted_total), 2),
        "volume_by_currency": {
            currency: round(float(amount), 2) for currency, amount in sorted(settled_volume.items())
        },
        "conversion_complete": not unconverted_currencies,
        "unconverted_currencies": sorted(unconverted_currencies),
        "pending_invoices": len(pending),
        "cash_runway": runway,
        "runway_inputs": {
            "current_cash": round(float(current_cash), 2),
            "observed_monthly_burn": round(float(monthly_burn), 2),
            "observation_days": observed_days,
            "inbound_transactions": sum(tx.type != "outbound" for tx in transactions),
            "outbound_transactions": sum(tx.type == "outbound" for tx in transactions),
        },
        "currency_exposure": {
            currency: round(float(amount), 2) for currency, amount in sorted(exposure.items())
        },
        "risk_score": risk_score,
        "monthly_transactions": [
            {"month": month, "volume": round(float(values["volume"]), 2)}
            for month, values in sorted(monthly.items())
        ],
        "cash_flow": [
            {
                "month": month,
                "incoming": round(float(values["incoming"]), 2),
                "expenses": round(float(values["expenses"]), 2),
            }
            for month, values in sorted(monthly.items())
        ],
        "country_heatmap": [
            {"country": country, "volume": round(float(amount), 2)}
            for country, amount in sorted(country_volume.items())
        ],
        "anomalies": sorted(anomalies, key=lambda item: item["score"], reverse=True)[:12],
    }
