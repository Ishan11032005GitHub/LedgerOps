from datetime import date, datetime
from pydantic import BaseModel, EmailStr, Field
from .models import Role


class SignupIn(BaseModel):
    email: EmailStr
    name: str
    password: str = Field(min_length=8)
    role: Role = Role.viewer
    account_type: str = Field(default="company", pattern="^(company|individual)$")
    workspace_name: str | None = Field(default=None, max_length=160)


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class RefreshIn(BaseModel):
    refresh_token: str


class ProfileUpdateIn(BaseModel):
    name: str = Field(min_length=2, max_length=120)


class CompanyEmployeeCreateIn(BaseModel):
    email: EmailStr
    name: str = Field(min_length=2, max_length=120)
    password: str = Field(min_length=8)
    role: Role = Role.viewer


class PasswordChangeIn(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8)


class ForgotPasswordIn(BaseModel):
    email: EmailStr


class ResetPasswordIn(BaseModel):
    token: str = Field(min_length=20)
    new_password: str = Field(min_length=8)


class AccountPreferencesIn(BaseModel):
    paymentAlerts: bool = True
    riskAlerts: bool = True
    weeklyDigest: bool = False
    currency: str = Field(default="USD", min_length=3, max_length=8)
    timezone: str = Field(default="Asia/Kolkata", max_length=80)


class PaymentWebhookIn(BaseModel):
    external_ref: str
    customer_name: str
    country: str
    currency: str
    amount: float
    invoice_number: str | None = None
    rail: str = "SWIFT"


class InvoiceWebhookIn(BaseModel):
    invoice_number: str
    customer_name: str
    country: str
    currency: str
    amount: float
    issued_at: date
    due_date: date


class ComplianceIn(BaseModel):
    entity_type: str = "payment"
    entity_id: int | None = None
    amount: float
    country: str
    payer_name: str
    invoice_amount: float | None = None
    documents: list[str] = []


class CopilotIn(BaseModel):
    question: str


class PredictionProxyIn(BaseModel):
    invoice_id: int | None = None
    transaction_id: int | None = None
    payload: dict = {}


class PaymentAppConnectIn(BaseModel):
    provider: str = "Stripe"
    account_name: str = "Infinity Payments"
    mode: str = "test"


class PaymentLinkIn(BaseModel):
    invoice_id: int
    customer_email: EmailStr | None = None
    success_url: str | None = None


class PaymentMethodIn(BaseModel):
    label: str = Field(min_length=2, max_length=80)
    cardholder_name: str = Field(min_length=2, max_length=120)
    brand: str = Field(min_length=2, max_length=30)
    last_four: str = Field(pattern=r"^\d{4}$")
    expiry_month: int = Field(ge=1, le=12)
    expiry_year: int = Field(ge=2026, le=2100)


class WalletTransferIn(BaseModel):
    recipient_name: str
    recipient_handle: str
    amount: float = Field(gt=0)
    currency: str = "USD"
    note: str | None = None
    rail: str = "Wallet"
    payment_method_id: int | None = None
    idempotency_key: str = Field(min_length=16, max_length=120)


class WalletRequestIn(BaseModel):
    payer_name: str
    payer_handle: str
    amount: float = Field(gt=0)
    currency: str = "USD"
    note: str | None = None


class DemoChatIn(BaseModel):
    recipient_id: int
    text: str = Field(min_length=1, max_length=1000)


class DashboardOut(BaseModel):
    total_volume: float
    pending_invoices: int
    cash_runway: int
    currency_exposure: dict
    risk_score: float
    alerts: list[dict]
    monthly_transactions: list[dict]
    cash_flow: list[dict]
    fx_trends: list[dict]
    country_heatmap: list[dict]
    anomalies: list[dict]
