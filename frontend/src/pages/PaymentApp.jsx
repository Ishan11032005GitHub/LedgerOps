import { useEffect, useMemo, useState } from "react";
import { ArrowDownLeft, ArrowUpRight, CheckCircle2, CreditCard, Link as LinkIcon, Plus, QrCode, RefreshCw, ScanLine, ShieldCheck, Star, Trash2, X } from "lucide-react";
import { Card, Skeleton } from "../components/Card.jsx";
import { accountStorageKey, readStoredUser, walletHandle } from "../lib/account.js";
import { api } from "../lib/api.js";

const contacts = [
  { name: "Northstar Robotics", handle: "northstar@pay", currency: "USD", color: "bg-mint" },
  { name: "Kairo Retail Group", handle: "kairo@pay", currency: "AED", color: "bg-blue-600" },
  { name: "Sakura Supply KK", handle: "sakura@pay", currency: "JPY", color: "bg-coral" },
  { name: "Atlas Minerals", handle: "atlas@pay", currency: "ZAR", color: "bg-amber-500" },
];

const money = (amount, currency = "USD") =>
  new Intl.NumberFormat("en-US", { style: "currency", currency, maximumFractionDigits: 0 }).format(amount || 0);

const emptyMethod = {
  label: "",
  cardholder_name: "",
  brand: "Visa",
  last_four: "",
  expiry_month: "",
  expiry_year: "",
};
const paymentAppCache = {};

export default function PaymentApp() {
  const accountKey = accountStorageKey();
  const cached = paymentAppCache[accountKey];
  const [status, setStatus] = useState(cached?.status || null);
  const [payments, setPayments] = useState(cached?.payments || []);
  const [methods, setMethods] = useState(cached?.methods || []);
  const [selectedMethodId, setSelectedMethodId] = useState("");
  const [showMethodForm, setShowMethodForm] = useState(false);
  const [methodForm, setMethodForm] = useState(emptyMethod);
  const [invoices, setInvoices] = useState(cached?.invoices || []);
  const [mode, setMode] = useState("pay");
  const [selected, setSelected] = useState(contacts[0]);
  const [amount, setAmount] = useState("2500");
  const [note, setNote] = useState("Invoice settlement");
  const [invoiceId, setInvoiceId] = useState("");
  const [message, setMessage] = useState("");
  const [linkMessage, setLinkMessage] = useState("");
  const [verifyStatus, setVerifyStatus] = useState("");
  const [link, setLink] = useState(null);
  const [loading, setLoading] = useState("");
  const [loadError, setLoadError] = useState("");
  const account = readStoredUser();
  const currentWalletHandle = walletHandle(account);
  const gatewayBalance = 0;

  async function load() {
    setLoadError("");
    const [statusResult, invoiceResult, paymentResult, methodResult] = await Promise.allSettled([
      api("/api/payment-app/status"),
      api("/api/invoices"),
      api("/api/payments"),
      api("/api/payment-app/payment-methods"),
    ]);
    if (statusResult.status === "rejected") throw statusResult.reason;
    const statusData = statusResult.value;
    const invoiceData = invoiceResult.status === "fulfilled" ? invoiceResult.value : [];
    const pendingInvoices = invoiceData.filter((invoice) => invoice.status === "pending");
    const paymentData = paymentResult.status === "fulfilled" ? paymentResult.value : [];
    const methodData = methodResult.status === "fulfilled" ? methodResult.value : [];
    setStatus(statusData);
    setInvoices(pendingInvoices);
    setPayments(paymentData.slice(0, 6));
    setMethods(methodData);
    paymentAppCache[accountStorageKey()] = {
      status: statusData,
      invoices: pendingInvoices,
      payments: paymentData.slice(0, 6),
      methods: methodData,
    };
    if (methodResult.status === "rejected") {
      setMessage("Saved cards will be available after the backend service is updated. Wallet activity is still accessible.");
    }
    setSelectedMethodId((current) => {
      if (current && methodData.some((method) => String(method.id) === current)) return current;
      const preferred = methodData.find((method) => method.is_default) || methodData[0];
      return preferred ? String(preferred.id) : "";
    });
    if (!pendingInvoices.length) {
      setInvoiceId("");
    } else if (!invoiceId || !pendingInvoices.some((invoice) => String(invoice.id) === invoiceId)) {
      const pending = pendingInvoices[0];
      setInvoiceId(String(pending.id));
    }
  }

  useEffect(() => {
    const cachedAccount = paymentAppCache[accountStorageKey()];
    setStatus(cachedAccount?.status || null);
    setPayments(cachedAccount?.payments || []);
    setMethods(cachedAccount?.methods || []);
    setInvoices(cachedAccount?.invoices || []);
    const setupSession = new URLSearchParams(window.location.search).get("card_setup");
    if (setupSession === "cancelled") {
      setMessage("Card setup cancelled.");
      window.history.replaceState({}, "", "/payment-app");
      load().catch((err) => setLoadError(err.message));
    } else if (setupSession) {
      setLoading("setup-complete");
      api(`/api/payment-app/payment-methods/setup/${setupSession}/complete`, { method: "POST" })
        .then(() => {
          setMessage("Card securely added to your wallet.");
          window.history.replaceState({}, "", "/payment-app");
          return load();
        })
        .catch((err) => {
          setLoadError(err.message);
          return load();
        })
        .finally(() => setLoading(""));
    } else {
      load().catch((err) => setLoadError(err.message));
    }
  }, [accountKey]);

  const selectedInvoice = useMemo(() => invoices.find((invoice) => String(invoice.id) === invoiceId), [invoiceId, invoices]);
  const selectedMethod = useMemo(() => methods.find((method) => String(method.id) === selectedMethodId), [methods, selectedMethodId]);

  async function beginMethodSetup() {
    setLoading("setup");
    setMessage("");
    try {
      const result = await api("/api/payment-app/payment-methods/setup", { method: "POST" });
      if (result.mode === "manual") {
        setShowMethodForm(true);
      } else {
        window.location.assign(result.checkout_url);
      }
    } catch (err) {
      setMessage(err.message);
    } finally {
      setLoading("");
    }
  }

  async function syncDemo() {
    setLoading("sync");
    setMessage("");
    try {
      const result = await api("/api/payment-app/sync-demo", { method: "POST" });
      setMessage(`Synced ${result.imported_payments} latest wallet payment.`);
      await load();
    } catch (err) {
      setMessage(err.message);
    } finally {
      setLoading("");
    }
  }

  async function addMethod(e) {
    e.preventDefault();
    setLoading("method");
    setMessage("");
    try {
      await api("/api/payment-app/payment-methods", {
        method: "POST",
        body: JSON.stringify({
          ...methodForm,
          expiry_month: Number(methodForm.expiry_month),
          expiry_year: Number(methodForm.expiry_year),
        }),
      });
      setMethodForm(emptyMethod);
      setShowMethodForm(false);
      setMessage("Card added to your wallet.");
      await load();
    } catch (err) {
      setMessage(err.message);
    } finally {
      setLoading("");
    }
  }

  async function makeDefault(methodId) {
    setLoading(`default-${methodId}`);
    try {
      await api(`/api/payment-app/payment-methods/${methodId}/default`, { method: "PATCH" });
      setSelectedMethodId(String(methodId));
      await load();
    } catch (err) {
      setMessage(err.message);
    } finally {
      setLoading("");
    }
  }

  async function removeMethod(methodId) {
    setLoading(`remove-${methodId}`);
    try {
      await api(`/api/payment-app/payment-methods/${methodId}`, { method: "DELETE" });
      setMessage("Card removed from your wallet.");
      await load();
    } catch (err) {
      setMessage(err.message);
    } finally {
      setLoading("");
    }
  }

  async function submitWallet(e) {
    e.preventDefault();
    setLoading(mode);
    setMessage("");
    setLink(null);
    const endpoint = mode === "pay" ? "/api/payment-app/pay" : "/api/payment-app/request";
    const payload = mode === "pay"
      ? { recipient_name: selected.name, recipient_handle: selected.handle, amount: Number(amount), currency: selected.currency, note, rail: "Wallet Pay", payment_method_id: selectedMethod ? selectedMethod.id : null }
      : { payer_name: selected.name, payer_handle: selected.handle, amount: Number(amount), currency: selected.currency, note };
    try {
      const result = await api(endpoint, { method: "POST", body: JSON.stringify(payload) });
      setMessage(mode === "pay" ? `Payment to ${result.recipient} is ${result.status}${result.funding_source ? ` using ${result.funding_source}.` : "."}` : `Request sent to ${result.payer}.`);
      await load();
    } catch (err) {
      setMessage(err.message);
    } finally {
      setLoading("");
    }
  }

  async function createLink(e) {
    e.preventDefault();
    setLoading("link");
    setMessage("");
    setLinkMessage("");
    setVerifyStatus("");
    try {
      const result = await api("/api/payment-app/payment-link", {
        method: "POST",
        body: JSON.stringify({ invoice_id: Number(invoiceId) }),
      });
      setLink(result);
      setLinkMessage(`Checkout link ready for ${result.invoice_number}. Open checkout, complete the test payment, then verify it here.`);
    } catch (err) {
      setMessage(err.message);
    } finally {
      setLoading("");
    }
  }

  async function verifyCheckout() {
    if (!link?.checkout_id) return;
    setLoading("verify");
    setMessage("");
    setLinkMessage("Checking payment status...");
    setVerifyStatus("checking");
    try {
      const result = await api(`/api/payment-app/verify-checkout/${link.checkout_id}`, { method: "POST" });
      setLinkMessage(result.status === "verified" ? `Verified ${result.invoice_number || "checkout"} and recorded ${money(result.amount, result.currency)}.` : result.message);
      setVerifyStatus(result.status === "verified" ? "verified" : "unpaid");
      await load();
    } catch (err) {
      setLinkMessage(err.message);
      setVerifyStatus("error");
    } finally {
      setLoading("");
    }
  }

  if (!status && loadError) {
    return (
      <Card title="Payment App unavailable">
        <div className="mt-4 rounded-md border border-coral/20 bg-coral/5 p-4">
          <div className="text-sm font-medium text-ink">The payment service did not finish loading.</div>
          <div className="mt-1 text-sm text-steel">{loadError}</div>
          <button type="button" onClick={() => load().catch((err) => setLoadError(err.message))} className="mt-4 inline-flex items-center gap-2 rounded-md bg-ink px-4 py-2.5 text-sm font-medium text-white">
            <RefreshCw size={16} /> Try again
          </button>
        </div>
      </Card>
    );
  }

  if (!status) return <Skeleton />;

  return (
    <div className="space-y-5">
      <div className="grid gap-5 xl:grid-cols-[390px_1fr]">
        <section className="rounded-lg border border-slate-200 bg-white shadow-soft">
          <div className="border-b border-slate-200 p-5">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-sm font-medium text-mint">Infinity Gateway</div>
                <h2 className="mt-1 text-2xl font-semibold">Payment gateway</h2>
              </div>
              <span className={`rounded-full px-3 py-1 text-xs font-medium ${methods.length ? "bg-mint/10 text-mint" : "bg-amber-100 text-amber-700"}`}>{methods.length ? `${methods.length} card${methods.length === 1 ? "" : "s"}` : "Add a card"}</span>
            </div>
            <div className="mt-5 rounded-lg bg-ink p-5 text-white">
              <div className="text-sm text-white/65">Gateway balance</div>
              <div className="mt-2 text-3xl font-semibold">{money(gatewayBalance)}</div>
              <div className="mt-1 text-xs text-white/55">Card balances are not exposed by card networks.</div>
              <div className="mt-4 flex items-center justify-between text-xs text-white/65">
                <span>Wallet ID: {currentWalletHandle}</span>
                <ShieldCheck size={16} />
              </div>
            </div>
            <div className="mt-4 grid grid-cols-4 gap-2">
              <Action icon={ScanLine} label="Scan" />
              <Action icon={ArrowUpRight} label="Pay" active={mode === "pay"} onClick={() => setMode("pay")} />
              <Action icon={ArrowDownLeft} label="Request" active={mode === "request"} onClick={() => setMode("request")} />
              <Action icon={QrCode} label="QR" />
            </div>
          </div>

          <form onSubmit={submitWallet} className="p-5">
            <div className="mb-4 flex rounded-md bg-panel p-1">
              <button type="button" onClick={() => setMode("pay")} className={`flex-1 rounded px-3 py-2 text-sm font-medium ${mode === "pay" ? "bg-white shadow-sm" : "text-steel"}`}>Pay</button>
              <button type="button" onClick={() => setMode("request")} className={`flex-1 rounded px-3 py-2 text-sm font-medium ${mode === "request" ? "bg-white shadow-sm" : "text-steel"}`}>Request</button>
            </div>

            <label className="text-sm font-medium">{mode === "pay" ? "Pay to" : "Request from"}</label>
            <div className="mt-2 grid grid-cols-4 gap-2">
              {contacts.map((contact) => (
                <button key={contact.handle} type="button" onClick={() => setSelected(contact)} className={`rounded-md border p-2 text-center ${selected.handle === contact.handle ? "border-mint bg-mint/5" : "border-slate-200"}`}>
                  <div className={`mx-auto grid h-9 w-9 place-items-center rounded-full text-sm font-semibold text-white ${contact.color}`}>{contact.name.slice(0, 1)}</div>
                  <div className="mt-2 truncate text-xs">{contact.name.split(" ")[0]}</div>
                </button>
              ))}
            </div>

            <div className="mt-4 rounded-md border border-slate-200 p-3">
              <div className="text-sm font-medium">{selected.name}</div>
              <div className="text-xs text-steel">{selected.handle}</div>
            </div>

            {mode === "pay" && (
              <>
                <label className="mt-4 block text-sm font-medium">Pay with</label>
                {methods.length ? (
                  <select value={selectedMethodId} onChange={(e) => setSelectedMethodId(e.target.value)} className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2 outline-none focus:border-mint">
                    {methods.map((method) => (
                      <option key={method.id} value={method.id}>{method.label} | {method.brand} ending {method.last_four}</option>
                    ))}
                  </select>
                ) : (
                  <button type="button" onClick={beginMethodSetup} className="mt-1 flex w-full items-center justify-center gap-2 rounded-md border border-dashed border-slate-300 px-3 py-3 text-sm text-steel hover:border-mint hover:text-mint">
                    <Plus size={16} /> Add a credit or debit card
                  </button>
                )}
              </>
            )}

            <label className="mt-4 block text-sm font-medium">Amount</label>
            <div className="mt-1 flex rounded-md border border-slate-300 focus-within:border-mint">
              <span className="border-r border-slate-200 px-3 py-2 text-sm text-steel">{selected.currency}</span>
              <input value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" className="min-w-0 flex-1 rounded-r-md px-3 py-2 outline-none" />
            </div>

            <label className="mt-4 block text-sm font-medium">Note</label>
            <input value={note} onChange={(e) => setNote(e.target.value)} className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint" />

            <button disabled={loading === mode || !Number(amount) || (mode === "pay" && !selectedMethod)} className="mt-5 flex w-full items-center justify-center gap-2 rounded-md bg-mint px-4 py-2.5 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60">
              {mode === "pay" ? <ArrowUpRight size={17} /> : <ArrowDownLeft size={17} />}
              {loading === mode ? "Processing..." : mode === "pay" ? "Pay now" : "Request money"}
            </button>
          </form>
        </section>

        <div className="space-y-5">
          <Card title="Payment Gateway">
            <div className="mt-4 grid gap-3 md:grid-cols-4">
              <Metric label="Funding" value="Cards + checkout" />
              <Metric label="Methods" value={status.saved_methods || methods.length} />
              <Metric label="Payments" value={status.mapped_payments} />
              <Metric label="Activity" value={status.webhook_events} />
            </div>
            <div className="mt-5 grid gap-3 sm:grid-cols-2">
              <button onClick={beginMethodSetup} disabled={loading === "setup" || loading === "setup-complete"} className="flex items-center justify-center gap-2 rounded-md bg-ink px-4 py-2.5 text-sm font-medium text-white hover:bg-slate-800 disabled:opacity-60">
                <Plus size={17} /> {loading === "setup" || loading === "setup-complete" ? "Connecting..." : "Add funding card"}
              </button>
              <button onClick={syncDemo} disabled={loading === "sync"} className="flex items-center justify-center gap-2 rounded-md border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-ink hover:bg-panel disabled:opacity-60">
                <RefreshCw size={17} /> {loading === "sync" ? "Refreshing..." : "Refresh gateway activity"}
              </button>
            </div>
            {message && <div className="mt-4 rounded-md bg-panel p-3 text-sm text-steel">{message}</div>}
          </Card>

          <Card title="Saved Cards" actions={<button onClick={beginMethodSetup} className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-3 py-1.5 text-xs font-medium hover:bg-panel"><Plus size={14} /> Add</button>}>
            {showMethodForm && (
              <form onSubmit={addMethod} className="mt-4 rounded-md border border-slate-200 bg-panel p-4">
                <div className="mb-3 flex items-center justify-between">
                  <div className="text-sm font-medium">Add test card</div>
                  <button type="button" title="Close" onClick={() => setShowMethodForm(false)} className="text-steel hover:text-ink"><X size={17} /></button>
                </div>
                <div className="grid gap-3 sm:grid-cols-2">
                  <label className="text-xs font-medium text-steel">Card label
                    <input required value={methodForm.label} onChange={(e) => setMethodForm({ ...methodForm, label: e.target.value })} placeholder="Corporate travel" className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-ink outline-none focus:border-mint" />
                  </label>
                  <label className="text-xs font-medium text-steel">Name on card
                    <input required value={methodForm.cardholder_name} onChange={(e) => setMethodForm({ ...methodForm, cardholder_name: e.target.value })} placeholder="Avery Shah" className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-ink outline-none focus:border-mint" />
                  </label>
                  <label className="text-xs font-medium text-steel">Network
                    <select value={methodForm.brand} onChange={(e) => setMethodForm({ ...methodForm, brand: e.target.value })} className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-ink">
                      {["Visa", "Mastercard", "American Express", "RuPay"].map((brand) => <option key={brand}>{brand}</option>)}
                    </select>
                  </label>
                  <label className="text-xs font-medium text-steel">Last four digits
                    <input required pattern="\d{4}" maxLength={4} inputMode="numeric" value={methodForm.last_four} onChange={(e) => setMethodForm({ ...methodForm, last_four: e.target.value.replace(/\D/g, "").slice(0, 4) })} placeholder="4242" className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-ink outline-none focus:border-mint" />
                  </label>
                  <label className="text-xs font-medium text-steel">Expiry month
                    <input required min="1" max="12" type="number" value={methodForm.expiry_month} onChange={(e) => setMethodForm({ ...methodForm, expiry_month: e.target.value })} placeholder="12" className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-ink outline-none focus:border-mint" />
                  </label>
                  <label className="text-xs font-medium text-steel">Expiry year
                    <input required min="2026" max="2100" type="number" value={methodForm.expiry_year} onChange={(e) => setMethodForm({ ...methodForm, expiry_year: e.target.value })} placeholder="2029" className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-ink outline-none focus:border-mint" />
                  </label>
                </div>
                <button disabled={loading === "method"} className="mt-4 rounded-md bg-mint px-4 py-2 text-sm font-medium text-white disabled:opacity-60">{loading === "method" ? "Adding..." : "Add card"}</button>
              </form>
            )}
            <div className="mt-4 grid gap-3 sm:grid-cols-2">
              {methods.map((method) => (
                <div key={method.id} className={`rounded-md border p-3 ${String(method.id) === selectedMethodId ? "border-mint bg-mint/5" : "border-slate-200"}`}>
                  <button type="button" onClick={() => setSelectedMethodId(String(method.id))} className="w-full text-left">
                    <div className="flex items-start justify-between gap-2">
                      <CreditCard size={19} className="text-steel" />
                      {method.is_default && <span className="rounded-full bg-mint/10 px-2 py-0.5 text-xs text-mint">Default</span>}
                    </div>
                    <div className="mt-3 text-sm font-medium">{method.label}</div>
                    <div className="mt-1 text-sm text-steel">{method.brand} ending {method.last_four}</div>
                    <div className="mt-1 text-xs text-steel">Expires {String(method.expiry_month).padStart(2, "0")}/{method.expiry_year}</div>
                  </button>
                  <div className="mt-3 flex gap-2">
                    {!method.is_default && (
                      <button type="button" onClick={() => makeDefault(method.id)} className="inline-flex items-center gap-1 text-xs font-medium text-steel hover:text-mint"><Star size={13} /> Make default</button>
                    )}
                    <button type="button" onClick={() => removeMethod(method.id)} className="ml-auto inline-flex items-center gap-1 text-xs text-steel hover:text-coral"><Trash2 size={13} /> Remove</button>
                  </div>
                </div>
              ))}
              {!methods.length && !showMethodForm && <div className="col-span-full rounded-md border border-dashed border-slate-300 p-5 text-center text-sm text-steel">No saved cards yet.</div>}
            </div>
          </Card>

          <Card title="Payments List">
            <div className="mt-4 space-y-3">
              {payments.map((payment) => (
                <div key={payment.id} className="flex items-center justify-between rounded-md border border-slate-200 p-3">
                  <div className="flex items-center gap-3">
                    <div className="grid h-9 w-9 place-items-center rounded-full bg-panel text-sm font-semibold text-steel">{(payment.recipient || "P").slice(0, 1)}</div>
                    <div>
                      <div className="text-sm font-medium">{payment.recipient || "Unknown recipient"}</div>
                      <div className="text-xs text-steel">{payment.external_ref} | {payment.rail} | {payment.status || "settled"}</div>
                    </div>
                  </div>
                  <div className="text-sm font-semibold">{money(payment.amount, payment.currency || "USD")}</div>
                </div>
              ))}
            </div>
          </Card>

          <Card title="Recipients">
            <div className="mt-4 grid gap-3 sm:grid-cols-2">
              {contacts.map((contact) => (
                <button key={contact.handle} type="button" onClick={() => setSelected(contact)} className="flex items-center gap-3 rounded-md border border-slate-200 p-3 text-left hover:bg-panel">
                  <div className={`grid h-10 w-10 place-items-center rounded-full text-sm font-semibold text-white ${contact.color}`}>{contact.name.slice(0, 1)}</div>
                  <div>
                    <div className="text-sm font-medium">{contact.name}</div>
                    <div className="text-xs text-steel">{contact.handle} | {contact.currency}</div>
                  </div>
                </button>
              ))}
            </div>
          </Card>
        </div>
      </div>

      <Card title="Collect From Invoice">
        <form onSubmit={createLink} className="mt-4 grid gap-3 lg:grid-cols-[1fr_auto]">
          <select value={invoiceId} onChange={(e) => setInvoiceId(e.target.value)} className="rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint">
            {invoices.map((invoice) => (
              <option key={invoice.id} value={invoice.id}>
                {invoice.invoice_number} | {money(invoice.amount, invoice.currency)} | {invoice.currency}
              </option>
            ))}
          </select>
          <button disabled={!invoiceId || loading === "link"} className="flex items-center justify-center gap-2 rounded-md bg-ink px-4 py-2.5 text-sm font-medium text-white hover:bg-slate-800 disabled:opacity-60">
            <LinkIcon size={17} /> {loading === "link" ? "Creating..." : "Create payment link"}
          </button>
        </form>
        {selectedInvoice && <div className="mt-3 text-sm text-steel">Ready to collect {money(selectedInvoice.amount, selectedInvoice.currency)} for {selectedInvoice.invoice_number}.</div>}
        {link && (
          <div className="mt-4 grid gap-4 rounded-md border border-slate-200 bg-panel p-4 md:grid-cols-[120px_1fr]">
            <div className="grid aspect-square place-items-center rounded-md bg-white">
              <QrCode size={64} className="text-ink" />
            </div>
            <div>
              <div className="flex items-center gap-2 text-sm font-medium"><CheckCircle2 size={17} className="text-mint" /> Payment link ready</div>
              <div className="mt-1 text-xs uppercase text-steel">Secure checkout | {link.mode === "stripe_test" ? "Test payment" : link.mode || "test"}</div>
              <div className="mt-2 break-all text-sm text-steel">{link.checkout_url}</div>
              <div className="mt-4 flex flex-wrap gap-2">
                <a href={link.checkout_url} target="_blank" rel="noreferrer" className="inline-flex items-center justify-center rounded-md bg-mint px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">
                  Open checkout
                </a>
                <button type="button" onClick={verifyCheckout} disabled={loading === "verify" || !link.checkout_id} className={`inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium disabled:opacity-60 ${verifyStatus === "verified" ? "border-mint bg-mint/10 text-mint" : verifyStatus === "unpaid" || verifyStatus === "error" ? "border-coral bg-coral/10 text-coral" : "border-slate-300 bg-white text-ink hover:bg-panel"}`}>
                  {verifyStatus === "checking" ? "Checking..." : verifyStatus === "verified" ? "Verified" : verifyStatus === "unpaid" ? "Not paid yet" : verifyStatus === "error" ? "Verification failed" : "Verify payment"}
                </button>
              </div>
              {linkMessage && <div className="mt-3 rounded-md bg-white p-3 text-sm text-steel">{linkMessage}</div>}
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}

function Action({ icon: Icon, label, active, onClick }) {
  return (
    <button type="button" onClick={onClick} className={`grid place-items-center gap-1 rounded-md border px-2 py-3 text-xs font-medium ${active ? "border-mint bg-mint/5 text-mint" : "border-slate-200 text-steel hover:bg-panel"}`}>
      <Icon size={18} />
      {label}
    </button>
  );
}

function Metric({ label, value }) {
  return (
    <div className="rounded-md border border-slate-200 p-3">
      <div className="text-xs uppercase tracking-wide text-steel">{label}</div>
      <div className="mt-1 text-sm font-semibold capitalize text-ink">{value || "Not available"}</div>
    </div>
  );
}
