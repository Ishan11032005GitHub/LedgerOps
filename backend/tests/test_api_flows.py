from fastapi.testclient import TestClient
from app.database import Base, SessionLocal, engine
from app.main import app
from app.models import Alert, EventLog, Payment, QuickLink
from app.seed import seed


def setup_module():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed(db)
    finally:
        db.close()


client = TestClient(app)


def login_demo(email="asha.demo@ledgerops.ai"):
    response = client.post("/api/auth/login", json={"email": email, "password": "DemoPass123"})
    assert response.status_code == 200
    return response.json()


def test_refresh_rotation_and_logout_revocation():
    tokens = login_demo()
    refreshed = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert refreshed.status_code == 200
    assert refreshed.json()["refresh_token"] != tokens["refresh_token"]
    old_refresh = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert old_refresh.status_code == 401
    signed_out = client.post("/api/auth/logout", json={"refresh_token": refreshed.json()["refresh_token"]})
    assert signed_out.status_code == 200
    revoked = client.post("/api/auth/refresh", json={"refresh_token": refreshed.json()["refresh_token"]})
    assert revoked.status_code == 401


def test_demo_quicklink_settlement_refund_and_reconciliation():
    tokens = login_demo()
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    created = client.post(
        "/api/payment-app/quicklinks",
        headers=headers,
        json={
            "title": "Consulting services",
            "amount": 1500,
            "currency": "INR",
            "payer_name": "Rohan Kapoor",
            "payer_email": "rohan.demo@ledgerops.ai",
            "payer_country": "IN",
            "purpose_code": "services",
            "expires_in_days": 14,
        },
    )
    assert created.status_code == 200
    link = created.json()
    public_link = client.get(f"/api/payment-app/public/quicklinks/{link['public_id']}")
    assert public_link.status_code == 200
    assert public_link.json()["status"] == "active"
    paid = client.post(
        f"/api/payment-app/public/quicklinks/{link['public_id']}/demo-pay",
        json={
            "cardholder_name": "Rohan Kapoor",
            "card_number": "4242424242424242",
            "expiry_month": 12,
            "expiry_year": 2029,
            "cvc": "123",
        },
    )
    assert paid.status_code == 200
    assert paid.json()["status"] == "paid"
    refunded = client.post(
        f"/api/payment-app/quicklinks/{link['id']}/refund",
        headers=headers,
        json={"reason": "requested_by_customer", "idempotency_key": "refund-test-key-0001"},
    )
    assert refunded.status_code == 200
    assert refunded.json()["quicklink_status"] == "refunded"
    duplicate = client.post(
        f"/api/payment-app/quicklinks/{link['id']}/refund",
        headers=headers,
        json={"reason": "requested_by_customer", "idempotency_key": "refund-test-key-0001"},
    )
    assert duplicate.status_code == 200
    reconciliation = client.post("/api/payment-app/reconciliation", headers=headers)
    assert reconciliation.status_code == 200
    assert reconciliation.json()["status"] == "completed"


def create_demo_quicklink(headers, *, amount=1500, currency="INR"):
    created = client.post(
        "/api/payment-app/quicklinks",
        headers=headers,
        json={
            "title": "Webhook services",
            "amount": amount,
            "currency": currency,
            "payer_name": "Rohan Kapoor",
            "payer_email": "rohan.demo@ledgerops.ai",
            "payer_country": "IN",
            "purpose_code": "services",
            "expires_in_days": 14,
        },
    )
    assert created.status_code == 200
    return created.json()


def test_stripe_webhook_settles_quicklink_and_is_idempotent(monkeypatch):
    tokens = login_demo()
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    link = create_demo_quicklink(headers)

    async def fake_event(_request):
        return {
            "id": "evt_checkout_quicklink_once",
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "id": "cs_test_quicklink_once",
                    "payment_status": "paid",
                    "amount_total": 150000,
                    "currency": "inr",
                    "payment_intent": "pi_quicklink_once",
                    "metadata": {
                        "quicklink_id": str(link["id"]),
                        "ledgerops_user_id": str(tokens["user"]["id"]),
                        "customer_name": "Rohan Kapoor",
                    },
                }
            },
        }

    monkeypatch.setattr("app.routers.payment_app.verified_stripe_event", fake_event)
    processed = client.post("/api/payment-app/stripe-webhook", content=b"{}")
    assert processed.status_code == 200
    assert processed.json()["status"] == "processed"

    duplicate = client.post("/api/payment-app/stripe-webhook", content=b"{}")
    assert duplicate.status_code == 200
    assert duplicate.json()["status"] == "already_processed"

    db = SessionLocal()
    try:
        stored = db.get(QuickLink, link["id"])
        assert stored.status == "paid"
        assert stored.payment_id is not None
        events = db.query(EventLog).filter(EventLog.event_type == "stripe.checkout.completed").all()
        matching = [event for event in events if event.payload.get("stripe_event_id") == "evt_checkout_quicklink_once"]
        assert len(matching) == 1
    finally:
        db.close()


def test_stripe_refund_and_dispute_webhooks_update_payment_state(monkeypatch):
    tokens = login_demo()
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    link = create_demo_quicklink(headers, amount=2000)
    paid = client.post(
        f"/api/payment-app/public/quicklinks/{link['public_id']}/demo-pay",
        json={
            "cardholder_name": "Rohan Kapoor",
            "card_number": "4242424242424242",
            "expiry_month": 12,
            "expiry_year": 2029,
            "cvc": "123",
        },
    )
    assert paid.status_code == 200

    db = SessionLocal()
    try:
        stored_link = db.get(QuickLink, link["id"])
        payment = db.get(Payment, stored_link.payment_id)
        payment_ref = payment.external_ref
    finally:
        db.close()

    async def refund_event(_request):
        return {
            "id": "evt_charge_refunded_once",
            "type": "charge.refunded",
            "data": {"object": {"payment_intent": payment_ref, "amount_refunded": 200000}},
        }

    monkeypatch.setattr("app.routers.payment_app.verified_stripe_event", refund_event)
    refunded = client.post("/api/payment-app/stripe-webhook", content=b"{}")
    assert refunded.status_code == 200
    assert refunded.json()["status"] == "processed"

    db = SessionLocal()
    try:
        payment = db.query(Payment).filter(Payment.external_ref == payment_ref).first()
        assert payment.status == "refunded"
        assert db.get(QuickLink, link["id"]).status == "refunded"
        payment.status = "settled"
        db.commit()
    finally:
        db.close()

    async def dispute_event(_request):
        return {
            "id": "evt_dispute_once",
            "type": "charge.dispute.created",
            "data": {"object": {"id": "dp_once", "payment_intent": payment_ref, "reason": "fraudulent"}},
        }

    monkeypatch.setattr("app.routers.payment_app.verified_stripe_event", dispute_event)
    disputed = client.post("/api/payment-app/stripe-webhook", content=b"{}")
    assert disputed.status_code == 200
    assert disputed.json()["status"] == "processed"

    db = SessionLocal()
    try:
        payment = db.query(Payment).filter(Payment.external_ref == payment_ref).first()
        assert payment.status == "disputed"
        alert = db.query(Alert).filter(Alert.entity_type == "payment", Alert.entity_id == payment.id).first()
        assert alert is not None
        assert alert.category == "payment-dispute"
    finally:
        db.close()


def test_company_scope_is_shared_but_individual_accounts_are_isolated():
    admin = client.post("/api/auth/login", json={"email": "admin@ledgerops.ai", "password": "AdminPass123"}).json()
    viewer = client.post("/api/auth/login", json={"email": "viewer@ledgerops.ai", "password": "ViewerPass123"}).json()
    individual = login_demo()
    admin_payments = client.get("/api/payments", headers={"Authorization": f"Bearer {admin['access_token']}"}).json()
    viewer_payments = client.get("/api/payments", headers={"Authorization": f"Bearer {viewer['access_token']}"}).json()
    individual_payments = client.get("/api/payments", headers={"Authorization": f"Bearer {individual['access_token']}"}).json()
    assert admin_payments
    assert {item["id"] for item in admin_payments} == {item["id"] for item in viewer_payments}
    assert "external_ref" in admin_payments[0]
    assert "external_ref" not in viewer_payments[0]
    assert not ({item["id"] for item in admin_payments} & {item["id"] for item in individual_payments})


def test_live_quicklink_requires_verified_email_and_mfa(monkeypatch):
    signup = client.post(
        "/api/auth/signup",
        json={
            "email": "live-gate@example.com",
            "name": "Live Gate",
            "password": "SecurePass123",
            "account_type": "individual",
        },
    )
    assert signup.status_code == 200
    monkeypatch.setattr("app.routers.payment_app.is_demo_user", lambda _user: False)
    monkeypatch.setattr("app.routers.payment_app.get_settings", lambda: type("Settings", (), {"demo_only": False})())
    response = client.post(
        "/api/payment-app/quicklinks",
        headers={"Authorization": f"Bearer {signup.json()['access_token']}"},
        json={
            "title": "Live collection",
            "amount": 100,
            "currency": "USD",
            "payer_name": "Payer",
            "payer_email": "payer@example.com",
            "payer_country": "US",
            "purpose_code": "services",
        },
    )
    assert response.status_code == 403
    assert "Verify your email" in response.json()["detail"]


def test_company_admin_can_deactivate_employee_and_revoke_login():
    admin = client.post("/api/auth/login", json={"email": "admin@ledgerops.ai", "password": "AdminPass123"}).json()
    headers = {"Authorization": f"Bearer {admin['access_token']}"}
    created = client.post(
        "/api/auth/company/users",
        headers=headers,
        json={
            "email": "temporary.employee@ledgerops.ai",
            "name": "Temporary Employee",
            "password": "SecurePass123",
            "role": "Finance Manager",
        },
    )
    assert created.status_code == 200
    member_id = created.json()["id"]
    employee = client.post(
        "/api/auth/login",
        json={"email": "temporary.employee@ledgerops.ai", "password": "SecurePass123"},
    ).json()
    imported = client.post(
        "/api/webhooks/payment-received",
        headers={"Authorization": f"Bearer {employee['access_token']}"},
        json={
            "external_ref": "employee_import_survives_deactivation",
            "customer_name": "Historical Client",
            "country": "US",
            "currency": "USD",
            "amount": 125,
            "rail": "ACH",
        },
    )
    assert imported.status_code == 200
    deactivated = client.delete(f"/api/auth/company/users/{member_id}", headers=headers)
    assert deactivated.status_code == 200
    login = client.post(
        "/api/auth/login",
        json={"email": "temporary.employee@ledgerops.ai", "password": "SecurePass123"},
    )
    assert login.status_code == 401
    payments = client.get("/api/payments", headers=headers).json()
    assert any(item.get("external_ref") == "employee_import_survives_deactivation" for item in payments)
