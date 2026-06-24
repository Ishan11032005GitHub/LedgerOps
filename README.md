# LedgerOps

AI finance operations layer for cross-border SMB payments.

LedgerOps is a full-stack finance operations system with Stripe Checkout collection, signed webhooks, fraud detection, FX recommendations, cash forecasting, compliance scoring, and a state-aware AI finance copilot.

## Stack

- Frontend: React, Vite, TailwindCSS, React Router, Recharts, Framer Motion
- Backend: FastAPI, JWT auth, REST APIs, background event handling, webhook ingestion
- Data: PostgreSQL
- Cache/queue: Redis
- ML service: FastAPI, scikit-learn, XGBoost, pandas, Prophet dependency, joblib-ready runtime
- Deployment: Docker, docker-compose, Vercel frontend config, Render backend/ML blueprint

## Run With Docker

```bash
docker compose up --build
```

Open:

- Frontend: `http://localhost:8081`
- Backend API docs: `http://localhost:8000/docs`
- ML health is available inside the Docker network.

## Two-account Demo

Docker starts LedgerOps in demo-only mode. Real Stripe operations are disabled even when Stripe keys exist in the shell.

- `asha.demo@ledgerops.ai` / `DemoPass123` - INR 25,000
- `rohan.demo@ledgerops.ai` / `DemoPass123` - INR 18,000

Use the one-click demo account buttons on the sign-in page. Open the second account in an incognito window or another browser. Payments update both balances and both payment histories; messages and payment requests appear in the floating Pay chat. Use **Reset demo** on the Payment App page to restore the initial state.

## Real Payments

Real-money collection is fail-closed. LedgerOps only reports live payments as enabled when both a Stripe live secret key and webhook signing secret are configured.

```powershell
$env:STRIPE_SECRET_KEY="sk_live_..."
$env:STRIPE_WEBHOOK_SECRET="whsec_..."
$env:PAYMENT_PROVIDER_MODE="disabled"
docker compose up --build
```

Configure the Stripe webhook endpoint as `https://<your-api-domain>/api/payment-app/stripe-webhook` and subscribe to `checkout.session.completed` and `checkout.session.async_payment_succeeded`. Do not place live keys in source control. A public HTTPS deployment, activated Stripe account, business verification, production database, secret manager, and operational monitoring are required before launch.

Invoice checkout supports real inbound collection. General recipient payouts are intentionally blocked in live mode until connected recipient onboarding and payout compliance are implemented.

Seed users:

- `admin@ledgerops.ai` / `AdminPass123`
- `finance@ledgerops.ai` / `FinancePass123`
- `viewer@ledgerops.ai` / `ViewerPass123`

## Local Development

Backend:

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload
```

ML service:

```bash
cd ml-service
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 9000
```

Frontend:

```bash
cd frontend
npm install
copy .env.example .env
npm run dev
```

## Key APIs

- `POST /api/auth/signup`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `GET /api/payments`
- `GET /api/invoices`
- `GET /api/customers`
- `GET /api/transactions`
- `GET /api/fx-rates`
- `POST /api/webhooks/payment-received`
- `POST /api/webhooks/invoice-created`
- `POST /api/compliance/check`
- `POST /api/predict/payment-delay`
- `POST /api/predict/fx`
- `POST /api/predict/anomaly`
- `POST /api/predict/runway`
- `POST /api/copilot`

## Example Webhook

```bash
curl -X POST http://localhost:8000/api/webhooks/payment-received \
  -H "Authorization: Bearer <access-token>" \
  -H "Content-Type: application/json" \
  -d "{\"external_ref\":\"pay_live_001\",\"customer_name\":\"Northstar Robotics\",\"country\":\"US\",\"currency\":\"USD\",\"amount\":42000,\"invoice_number\":\"INV-2026-1001\",\"rail\":\"ACH\"}"
```

## Project Structure

```text
frontend/      React dashboard and Vercel config
backend/       FastAPI API, auth, domain models, webhooks, compliance, copilot
ml-service/    ML prediction service
docker/        shared deployment config
docs/          architecture notes
```

See `docs/ARCHITECTURE.md` for the service design.
