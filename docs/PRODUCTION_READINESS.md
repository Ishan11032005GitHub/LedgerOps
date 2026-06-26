# LedgerOps Production Readiness

## Implemented safeguards

- Versioned Alembic migrations run before backend startup.
- Revocable refresh sessions with token rotation and logout invalidation.
- Opaque workspace membership keys instead of display-name tenant grouping.
- Email verification, authenticator MFA, and SMTP-backed account recovery.
- Authentication and financial-mutation rate limits.
- Request IDs and baseline browser security headers.
- Provider-neutral payment boundary with Stripe as the first adapter.
- QuickLink settlement, receipts, remittance advice, refunds, disputes, and reconciliation.
- Idempotent refund requests.
- Account-scoped audit records for financial mutations.
- Live QuickLink compliance preflight fails closed when screening is unavailable.
- Gemini output is rejected when it introduces numbers absent from account data.
- Automated backend tests and frontend production builds run in GitHub Actions.

## External launch gates

These cannot be completed only in source code:

1. Activate and verify the merchant account with the selected payment processor.
2. Configure live processor keys and signed webhooks in a secret manager.
3. Contract and configure a KYC/KYB, AML, and sanctions-screening vendor.
4. Obtain legal review for terms, privacy, refunds, disputes, remittance documents, and supported jurisdictions.
5. Configure production email delivery for verification and password recovery.
6. Configure managed PostgreSQL backups, point-in-time recovery, Redis, monitoring, and incident alerts.
7. Complete an independent penetration test and payment-flow review.

## Required production variables

```text
ENVIRONMENT=production
JWT_SECRET=<unique 32+ character secret>
DATABASE_URL=<managed PostgreSQL URL>
REDIS_URL=<managed Redis URL>
CORS_ORIGINS=https://app.example.com
FRONTEND_URL=https://app.example.com
PAYMENT_PROCESSOR=stripe
DEMO_ONLY=false
STRIPE_SECRET_KEY=<live secret>
STRIPE_WEBHOOK_SECRET=<signed webhook secret>
COMPLIANCE_PROVIDER=<installed adapter name>
COMPLIANCE_PROVIDER_URL=<HTTPS screening endpoint>
COMPLIANCE_PROVIDER_API_KEY=<managed API token>
GEMINI_API_KEY=<server-side key>
SMTP_HOST=<mail server>
SMTP_PORT=587
SMTP_USERNAME=<mail user>
SMTP_PASSWORD=<managed secret>
SMTP_FROM_EMAIL=security@example.com
```

## Deliberately blocked until vendor configuration

- Live collection fails closed without a compliance provider adapter. The built-in `http` adapter accepts only explicit `clear` or `approved` responses and rejects ambiguous responses.
- Live QuickLinks fail closed until the operator has verified email and enabled MFA.
- Unsupported processors fail closed; adding a processor requires a signed-webhook implementation, idempotent checkout/refund behavior, and reconciliation mapping.
- Payouts and recipient transfers remain unavailable in live mode until recipient onboarding and jurisdiction-specific compliance are implemented.

## Release path

1. Deploy staging with processor test keys.
2. Run `alembic upgrade head`.
3. Complete the QuickLink, webhook, receipt, refund, dispute, and reconciliation tests.
4. Run tenant and role-access tests.
5. Back up the staging database and perform a restore drill.
6. Deploy production with live keys only after external launch gates are signed off.

## Runtime readiness

`GET /ready` verifies database connectivity and reports deployment checks. In production it returns HTTP 503 when required configuration is missing. `GET /api/system/readiness` returns the same machine-readable checklist for deployment automation.
