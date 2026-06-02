const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

const demoCustomers = [
  { id: 1, country: "US", risk_rating: "Low", kyc_status: "Verified", name: "Northstar Robotics", currency: "USD", avg_delay_days: 2 },
  { id: 2, country: "AE", risk_rating: "Medium", kyc_status: "Verified", name: "Kairo Retail Group", currency: "AED", avg_delay_days: 7 },
  { id: 3, country: "DE", risk_rating: "Low", kyc_status: "Verified", name: "Blue Harbor GmbH", currency: "EUR", avg_delay_days: 1 },
  { id: 4, country: "JP", risk_rating: "Medium", kyc_status: "Review", name: "Sakura Supply KK", currency: "JPY", avg_delay_days: 9 },
  { id: 5, country: "ZA", risk_rating: "High", kyc_status: "Review", name: "Atlas Minerals", currency: "ZAR", avg_delay_days: 13 },
  { id: 6, country: "CA", risk_rating: "Low", kyc_status: "Verified", name: "Maple Cloud Ltd", currency: "CAD", avg_delay_days: 3 },
];

const demoInvoices = [
  { invoice_number: "INV-2026-1041", id: 42, currency: "CAD", status: "paid", due_date: "2025-10-04", paid_at: "2025-10-18", amount: 12835.97 },
  { invoice_number: "INV-2026-1040", id: 41, currency: "ZAR", status: "pending", due_date: "2025-10-10", paid_at: "", amount: 58943.1 },
  { invoice_number: "INV-2026-1039", id: 40, currency: "JPY", status: "paid", due_date: "2025-10-16", paid_at: "2025-10-30", amount: 23990.25 },
  { invoice_number: "INV-2026-1038", id: 39, currency: "EUR", status: "paid", due_date: "2025-10-22", paid_at: "2025-11-07", amount: 34858.54 },
  { invoice_number: "INV-2026-1037", id: 38, currency: "AED", status: "paid", due_date: "2025-10-28", paid_at: "2025-11-07", amount: 16538.53 },
  { invoice_number: "INV-2026-1036", id: 37, currency: "USD", status: "pending", due_date: "2025-11-03", paid_at: "", amount: 15956.57 },
  { invoice_number: "INV-2026-1032", id: 33, currency: "EUR", status: "pending", due_date: "2025-11-27", paid_at: "", amount: 64381.63 },
];

const basePayments = [
  { id: 1, recipient: "Kairo Retail Group", country: "AE", rail: "SWIFT", external_ref: "pay_00001", invoice_id: 2, customer_id: 2, amount: 5538.38, currency: "AED", status: "settled" },
  { id: 3, recipient: "Sakura Supply KK", country: "JP", rail: "SWIFT", external_ref: "pay_00003", invoice_id: 4, customer_id: 4, amount: 10585.51, currency: "JPY", status: "settled" },
  { id: 2, recipient: "Blue Harbor GmbH", country: "DE", rail: "SWIFT", external_ref: "pay_00002", invoice_id: 3, customer_id: 3, amount: 14872.34, currency: "EUR", status: "settled" },
  { id: 4, recipient: "Maple Cloud Ltd", country: "CA", rail: "ACH", external_ref: "pay_00005", invoice_id: 6, customer_id: 6, amount: 22461.86, currency: "CAD", status: "settled" },
  { id: 5, recipient: "Northstar Robotics", country: "US", rail: "ACH", external_ref: "pay_00006", invoice_id: 7, customer_id: 1, amount: 19705.27, currency: "USD", status: "settled" },
  { id: 10, recipient: "Kairo Retail Group", country: "AE", rail: "SWIFT", external_ref: "pay_00013", invoice_id: 14, customer_id: 2, amount: 69280.95, currency: "AED", status: "settled" },
];

function storedPayments() {
  try {
    return JSON.parse(localStorage.getItem("ig_demo_payments") || "[]");
  } catch {
    localStorage.removeItem("ig_demo_payments");
    return [];
  }
}

function storedMethods() {
  try {
    return JSON.parse(localStorage.getItem("ig_demo_methods") || "[]");
  } catch {
    localStorage.removeItem("ig_demo_methods");
    return [];
  }
}

function demoUser(payload = {}) {
  return { id: 999, email: payload.email || "admin@infinityguard.ai", name: payload.name || "Avery Shah", role: payload.role || "Admin" };
}

function demoTokenPair(user) {
  return { access_token: "offline-demo-token", refresh_token: "offline-demo-refresh", token_type: "bearer", user };
}

function demoResponse(path, options = {}) {
  const method = options.method || "GET";
  const body = options.body ? JSON.parse(options.body) : {};
  const payments = [...storedPayments(), ...basePayments];

  if (path === "/api/auth/login") return demoTokenPair(demoUser(body));
  if (path === "/api/auth/signup") return demoTokenPair(demoUser(body));
  if (path === "/api/auth/me" && method === "GET") return demoUser(JSON.parse(localStorage.getItem("ig_user") || "{}"));
  if (path === "/api/auth/me" && method === "PATCH") {
    const user = { ...demoUser(JSON.parse(localStorage.getItem("ig_user") || "{}")), name: body.name };
    return user;
  }
  if (path === "/api/auth/password" && method === "POST") return { status: "updated" };
  if (path === "/api/auth/forgot-password" && method === "POST") {
    return {
      message: "If this email is registered, a password reset link has been prepared.",
      reset_url: `${window.location.origin}/reset-password?token=offline-reset-token-for-local-testing`,
    };
  }
  if (path === "/api/auth/reset-password" && method === "POST") return { status: "updated", message: "Password reset complete. You can now sign in." };
  if (path === "/api/auth/preferences" && method === "GET") return JSON.parse(localStorage.getItem("ig_preferences") || JSON.stringify({ paymentAlerts: true, riskAlerts: true, weeklyDigest: false, currency: "USD", timezone: "Asia/Kolkata" }));
  if (path === "/api/auth/preferences" && method === "PATCH") {
    localStorage.setItem("ig_preferences", JSON.stringify(body));
    return body;
  }
  if (path === "/api/payments") return payments;
  if (path === "/api/invoices") return demoInvoices;
  if (path === "/api/customers") return demoCustomers;
  if (path === "/api/dashboard") {
    return {
      total_volume: payments.reduce((sum, payment) => sum + Number(payment.amount || 0), 0),
      pending_invoices: demoInvoices.filter((invoice) => invoice.status === "pending").length,
      cash_runway: 49,
      currency_exposure: { USD: 15956, EUR: 99240, JPY: 23990, AED: 85819, CAD: 35300, ZAR: 58943 },
      risk_score: 77.5,
      alerts: [
        { severity: "medium", category: "cash", message: "Delayed invoices could reduce runway below 60 days." },
        { severity: "medium", category: "fx", message: "EUR exposure rose 18% while volatility is trending upward." },
        { severity: "high", category: "fraud", message: "JPY payment pattern changed outside normal settlement window." },
      ],
      monthly_transactions: [
        { month: "Oct", volume: 38000 }, { month: "Nov", volume: 84000 }, { month: "Dec", volume: 208000 },
        { month: "Jan", volume: 229000 }, { month: "Feb", volume: 235000 }, { month: "Mar", volume: 111000 },
        { month: "Apr", volume: 137000 }, { month: "May", volume: 108000 }, { month: "Jun", volume: 6000 },
      ],
      cash_flow: [
        { month: "Oct", incoming: 38000, expenses: 21000 }, { month: "Nov", incoming: 84000, expenses: 50000 },
        { month: "Dec", incoming: 208000, expenses: 120000 }, { month: "Jan", incoming: 236000, expenses: 134000 },
        { month: "Feb", incoming: 242000, expenses: 137000 }, { month: "Mar", incoming: 109000, expenses: 63000 },
        { month: "Apr", incoming: 138000, expenses: 81000 }, { month: "May", incoming: 107000, expenses: 62000 },
        { month: "Jun", incoming: 6000, expenses: 3000 },
      ],
      fx_trends: Array.from({ length: 35 }, (_, index) => ({ currency: ["EUR", "AED", "ZAR", "JPY"][index % 4], rate: 0.6 + (index % 7) / 10, volatility: 18 + ((index * 13) % 62) })),
      country_heatmap: [
        { country: "CA", volume: 239389 }, { country: "JP", volume: 219244 }, { country: "DE", volume: 162469 },
        { country: "AE", volume: 304613 }, { country: "ZA", volume: 95666 }, { country: "US", volume: 130398 },
      ],
      anomalies: [{ name: "Atlas Minerals", score: 76, amount: 58943 }, { name: "Sakura Supply KK", score: 82, amount: 23990 }],
    };
  }
  if (path === "/api/payment-app/status") {
    return { provider: "Secure card network", mode: "offline test", connected: true, sync_health: "offline_ready", last_payment_at: null, last_sync_at: localStorage.getItem("ig_demo_last_sync"), webhook_events: storedPayments().length + 3, mapped_payments: payments.length, saved_methods: storedMethods().length };
  }
  if (path === "/api/payment-app/connect" && method === "POST") {
    localStorage.setItem("ig_demo_payment_connected", "true");
    return { status: "connected", provider: body.provider || "Stripe", account_name: body.account_name || "InfinityGuard Treasury", mode: body.mode || "test", event_id: Date.now() };
  }
  if (path === "/api/payment-app/sync-demo" && method === "POST") {
    const payment = { id: Date.now(), country: "US", rail: "Stripe", external_ref: `stripe_pi_${Date.now()}`, invoice_id: "", customer_id: 1, amount: 18420.75 };
    localStorage.setItem("ig_demo_payments", JSON.stringify([payment, ...storedPayments()]));
    localStorage.setItem("ig_demo_last_sync", new Date().toISOString());
    return { status: "synced", imported_payments: 1, payment_id: payment.id, external_ref: payment.external_ref, event_id: Date.now() };
  }
  if (path === "/api/payment-app/payment-link" && method === "POST") {
    const invoice = demoInvoices.find((item) => item.id === body.invoice_id) || demoInvoices[0];
    return { status: "created", provider: "Stripe", invoice_number: invoice.invoice_number, amount: invoice.amount, currency: invoice.currency, checkout_url: `https://checkout.stripe.com/c/pay/ig_chk_${invoice.id}_${Date.now()}` };
  }
  if (path === "/api/payment-app/payment-methods" && method === "GET") return storedMethods();
  if (path === "/api/payment-app/payment-methods/setup" && method === "POST") return { mode: "manual" };
  if (path === "/api/payment-app/payment-methods" && method === "POST") {
    const methods = storedMethods();
    const saved = { id: Date.now(), ...body, is_default: methods.length === 0 };
    localStorage.setItem("ig_demo_methods", JSON.stringify([saved, ...methods]));
    return saved;
  }
  if (path.match(/^\/api\/payment-app\/payment-methods\/\d+\/default$/) && method === "PATCH") {
    const methodId = Number(path.split("/")[4]);
    const methods = storedMethods().map((item) => ({ ...item, is_default: item.id === methodId }));
    localStorage.setItem("ig_demo_methods", JSON.stringify(methods));
    return methods.find((item) => item.id === methodId);
  }
  if (path.match(/^\/api\/payment-app\/payment-methods\/\d+$/) && method === "DELETE") {
    const methodId = Number(path.split("/")[4]);
    let methods = storedMethods().filter((item) => item.id !== methodId);
    if (methods.length && !methods.some((item) => item.is_default)) methods = methods.map((item, index) => ({ ...item, is_default: index === 0 }));
    localStorage.setItem("ig_demo_methods", JSON.stringify(methods));
    return { status: "removed", id: methodId };
  }
  if (path === "/api/payment-app/pay" && method === "POST") {
    const method = storedMethods().find((item) => item.id === body.payment_method_id);
    const payment = {
      id: Date.now(),
      country: "US",
      rail: method ? `${method.brand} ending ${method.last_four}` : body.rail || "Wallet Pay",
      external_ref: `wallet_pay_${Date.now()}`,
      invoice_id: "",
      customer_id: 999,
      recipient: body.recipient_name,
      amount: body.amount,
      currency: body.currency,
      status: "processing",
    };
    localStorage.setItem("ig_demo_payments", JSON.stringify([payment, ...storedPayments()]));
    return { status: "processing", payment_id: payment.id, external_ref: payment.external_ref, recipient: body.recipient_name, amount: body.amount, currency: body.currency, funding_source: payment.rail };
  }
  if (path === "/api/payment-app/request" && method === "POST") {
    localStorage.setItem("ig_demo_last_sync", new Date().toISOString());
    return { status: "requested", request_id: `wallet_req_${Date.now()}`, payer: body.payer_name, amount: body.amount, currency: body.currency };
  }
  if (path.startsWith("/api/predict/") || path === "/api/compliance/check") return { status: "completed", mode: "offline test", recommendation: "Review high-value, delayed, or volatile-currency items before settlement." };
  if (path === "/api/copilot") return { answer: "Offline test mode: the riskiest invoices are pending high-value invoices in ZAR and EUR, especially INV-2026-1040 and INV-2026-1032.", state_used: { pending_invoices: 3, highest_risk_currency: "ZAR" } };
  throw new Error("Offline test data is not available for this action.");
}

export function getToken() {
  return localStorage.getItem("ig_access_token");
}

export async function api(path, options = {}) {
  const headers = { "Content-Type": "application/json", ...(options.headers || {}) };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  let response;
  try {
    response = await fetch(`${API_URL}${path}`, { ...options, headers });
  } catch {
    return demoResponse(path, options);
  }
  if (!response.ok) {
    const detail = await response.json().catch(() => ({}));
    throw new Error(detail.detail || `Request failed: ${response.status}`);
  }
  return response.json();
}

export async function login(email, password) {
  const data = await api("/api/auth/login", { method: "POST", body: JSON.stringify({ email, password }) });
  localStorage.setItem("ig_access_token", data.access_token);
  localStorage.setItem("ig_refresh_token", data.refresh_token);
  localStorage.setItem("ig_user", JSON.stringify(data.user));
  return data.user;
}

export async function signup(payload) {
  const data = await api("/api/auth/signup", { method: "POST", body: JSON.stringify(payload) });
  localStorage.setItem("ig_access_token", data.access_token);
  localStorage.setItem("ig_refresh_token", data.refresh_token);
  localStorage.setItem("ig_user", JSON.stringify(data.user));
  return data.user;
}
