# LedgerOps Launch Runbook

This runbook separates what the code can enforce from what must be completed with external vendors before real money is enabled.

## 1. Preserve the build

```powershell
git status
git add .
git commit -m "Complete LedgerOps staging MVP"
.\scripts\backup_postgres.ps1
```

Keep the generated SQL backup outside public source control.

## 2. Staging deployment

Deploy frontend, backend, ML service, PostgreSQL, and Redis under HTTPS.

Required staging URLs:

```text
FRONTEND_URL=https://staging.ledgerops.app
CORS_ORIGINS=https://staging.ledgerops.app
```

Use test processor keys first.

## 3. Payment processor

Stripe is the first installed processor adapter. Configure:

```text
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Webhook endpoint:

```text
https://api-staging.ledgerops.app/api/payment-app/stripe-webhook
```

Subscribe to:

```text
checkout.session.completed
checkout.session.async_payment_succeeded
charge.refunded
charge.dispute.created
```

Run the lifecycle:

```text
QuickLink -> card checkout -> signed webhook -> ledger payment -> receipt/remittance -> refund -> reconciliation
```

## 4. Compliance provider

Configure the fail-closed HTTP adapter:

```text
COMPLIANCE_PROVIDER=http
COMPLIANCE_PROVIDER_URL=https://provider.example/check
COMPLIANCE_PROVIDER_API_KEY=<secret>
```

The provider must return one of:

```text
clear
approved
review
blocked
```

Only `clear` and `approved` allow live collection.

## 5. Email delivery

Configure SMTP for verification and password recovery:

```text
SMTP_HOST=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_FROM_EMAIL=
SMTP_USE_TLS=true
```

## 6. Backups and recovery

For local/staging drills:

```powershell
.\scripts\backup_postgres.ps1
.\scripts\restore_postgres.ps1 -InputPath .\backups\ledgerops-YYYYMMDD-HHMMSS.sql
```

For production, use managed PostgreSQL backups and point-in-time recovery. Set:

```text
DATABASE_BACKUPS_CONFIGURED=true
```

only after a restore drill succeeds.

## 7. Monitoring and incident response

Monitor:

```text
GET /health
GET /ready
GET /api/system/readiness
```

Configure uptime alerts, backend error reporting, database alerts, and payment-webhook failure alerts.

Set:

```text
MONITORING_CONFIGURED=true
```

only after alerts have been tested.

## 8. Legal and security sign-off

Complete review of:

- Terms of service
- Privacy policy
- Refund policy
- Dispute policy
- Merchant agreement
- Data-retention policy
- Supported-country and currency policy
- Penetration test
- Payment-flow security review

Set:

```text
LEGAL_REVIEW_COMPLETED=true
SECURITY_REVIEW_COMPLETED=true
```

only after sign-off.

## 9. Restricted pilot

Before public registration:

- Use verified merchants only.
- Keep low transaction limits.
- Require manual review for elevated-risk payments.
- Reconcile daily.
- Test refunds and disputes.

Set:

```text
RESTRICTED_PILOT_ENABLED=true
```

only for a controlled pilot group.

## 10. Live mode

After every readiness check is green:

```text
ENVIRONMENT=production
DEMO_ONLY=false
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Confirm:

```text
GET /api/system/readiness
```

has no blocking checks before accepting live payments.
