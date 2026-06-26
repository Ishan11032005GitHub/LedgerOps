# Payment processor adapters

LedgerOps models card issuers, card networks, and payment processors separately.

- **Issuers:** ICICI Bank, AU Small Finance Bank, SBI, Chase, and similar banks.
- **Networks:** Visa, Mastercard, RuPay, American Express, JCB, Discover, Diners Club, and UnionPay.
- **Processors:** Stripe, Razorpay, Cashfree, Adyen, and other acquiring/payment platforms.

Issuer-specific adapters are not required. A bank-issued card is accepted when its network, country, currency, authentication requirements, and the configured processor permit it.

The backend exposes a `PaymentProcessor` protocol in `app/services/processors.py`. New adapters must implement idempotent refunds and should additionally implement checkout creation, session lookup, card setup, charges, and webhook verification before they can replace the initial Stripe adapter.

Every adapter must:

1. Verify webhook signatures.
2. Preserve idempotency keys.
3. Return stable processor references.
4. Fail closed on ambiguous status.
5. Never store PAN, CVV, or raw card credentials.
6. Map settlements, refunds, and disputes into the LedgerOps ledger and audit log.
