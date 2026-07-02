import { useEffect, useMemo, useState } from "react";
import {
  Ban,
  Check,
  CheckCircle2,
  Clock3,
  Copy,
  Download,
  ExternalLink,
  FileText,
  Link2,
  LoaderCircle,
  RefreshCw,
  RotateCcw,
  Send,
  ShieldCheck,
} from "lucide-react";
import { Card, Skeleton } from "../components/Card.jsx";
import { api, apiBlob } from "../lib/api.js";
import { formatCurrency, supportedCurrencies } from "../lib/currencies.js";

const purposeCodes = [
  ["services", "Professional services"],
  ["goods", "Goods and merchandise"],
  ["software", "Software and digital products"],
  ["subscription", "Subscription or membership"],
  ["education", "Education and training"],
  ["travel", "Travel and hospitality"],
  ["other", "Other business payment"],
];

const blankForm = {
  title: "",
  payer_name: "",
  payer_email: "",
  payer_country: "",
  amount: "",
  currency: "USD",
  purpose_code: "services",
  expires_in_days: 14,
};

function statusStyle(status) {
  if (status === "paid") return "bg-mint/10 text-mint";
  if (status === "active") return "bg-blue-50 text-blue-700";
  if (status === "pending_review") return "bg-amber-100 text-amber-800";
  if (status === "expired") return "bg-amber-100 text-amber-800";
  return "bg-slate-100 text-steel";
}

export default function QuickLinks() {
  const currencies = useMemo(supportedCurrencies, []);
  const [links, setLinks] = useState([]);
  const [form, setForm] = useState(blankForm);
  const [loading, setLoading] = useState("load");
  const [notice, setNotice] = useState("");
  const [noticeTone, setNoticeTone] = useState("neutral");
  const [createdLink, setCreatedLink] = useState(null);
  const [copiedId, setCopiedId] = useState(null);

  async function load() {
    const data = await api("/api/payment-app/quicklinks");
    setLinks(data);
  }

  useEffect(() => {
    load()
      .catch((error) => setNotice(error.message))
      .finally(() => setLoading(""));
  }, []);

  async function createLink(event) {
    event.preventDefault();
    setLoading("create");
    setNotice("");
    setCreatedLink(null);
    try {
      const created = await api("/api/payment-app/quicklinks", {
        method: "POST",
        body: JSON.stringify({
          ...form,
          amount: Number(form.amount),
          payer_name: form.payer_name || null,
          payer_email: form.payer_email || null,
          payer_country: form.payer_country || null,
          expires_in_days: Number(form.expires_in_days),
        }),
      });
      setLinks((current) => [created, ...current]);
      setForm(blankForm);
      setCreatedLink(created);
      setNoticeTone("success");
      setNotice(created.status === "pending_review" ? "QuickLink is waiting for manual compliance approval." : "QuickLink is ready to share.");
    } catch (error) {
      setNoticeTone("error");
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  async function copyLink(link) {
    if (!link.checkout_url) return;
    await navigator.clipboard.writeText(link.checkout_url);
    setCopiedId(link.id);
    window.setTimeout(() => setCopiedId(null), 1600);
  }

  async function approve(link) {
    setLoading(`approve-${link.id}`);
    setNotice("");
    try {
      const result = await api(`/api/payment-app/quicklinks/${link.id}/approve`, { method: "POST" });
      setLinks((current) => current.map((item) => (item.id === link.id ? result : item)));
      setCreatedLink(result);
      setNoticeTone("success");
      setNotice(result.message || "Manual compliance approved. QuickLink is ready to share.");
    } catch (error) {
      setNoticeTone("error");
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  async function verify(link) {
    setLoading(`verify-${link.id}`);
    setNotice("");
    try {
      const result = await api(`/api/payment-app/quicklinks/${link.id}/verify`, { method: "POST" });
      setLinks((current) => current.map((item) => (item.id === link.id ? result : item)));
      setNotice(result.status === "paid" ? "Payment settled. Remittance advice is ready." : result.message || "Payment is still pending.");
    } catch (error) {
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  async function disable(link) {
    setLoading(`disable-${link.id}`);
    try {
      const result = await api(`/api/payment-app/quicklinks/${link.id}`, { method: "DELETE" });
      setLinks((current) => current.map((item) => (item.id === link.id ? result : item)));
    } catch (error) {
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  async function downloadRemittance(link) {
    setLoading(`document-${link.id}`);
    try {
      const blob = await apiBlob(`/api/payment-app/quicklinks/${link.id}/remittance`);
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = `remittance-${link.public_id}.pdf`;
      anchor.click();
      URL.revokeObjectURL(url);
    } catch (error) {
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  async function downloadReceipt(link) {
    setLoading(`receipt-${link.id}`);
    try {
      const blob = await apiBlob(`/api/payment-app/quicklinks/${link.id}/receipt`);
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = `receipt-${link.public_id}.pdf`;
      anchor.click();
      URL.revokeObjectURL(url);
    } catch (error) {
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  async function refund(link) {
    if (!window.confirm(`Refund the full ${formatCurrency(link.amount, link.currency)} payment?`)) return;
    setLoading(`refund-${link.id}`);
    setNotice("");
    try {
      const result = await api(`/api/payment-app/quicklinks/${link.id}/refund`, {
        method: "POST",
        body: JSON.stringify({
          reason: "requested_by_customer",
          idempotency_key: crypto.randomUUID(),
        }),
      });
      setLinks((current) => current.map((item) => (
        item.id === link.id ? { ...item, status: result.quicklink_status } : item
      )));
      setNotice(`${formatCurrency(result.amount, result.currency)} refund ${result.status}.`);
    } catch (error) {
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  if (loading === "load") return <Skeleton />;

  return (
    <div className="space-y-5">
      <section className="flex flex-col justify-between gap-4 rounded-lg border border-slate-200 bg-white p-5 shadow-soft lg:flex-row lg:items-center">
        <div className="flex min-w-0 items-start gap-4">
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-mint/10 text-mint"><Link2 size={25} /></div>
          <div>
            <div className="text-sm font-medium text-mint">LedgerOps QuickLink</div>
            <h2 className="mt-1 text-2xl font-semibold">Collect an international card payment</h2>
            <p className="mt-1 text-sm text-steel">Share one secure checkout link for eligible cards issued by banks worldwide. Bank account and SWIFT details stay private.</p>
          </div>
        </div>
        <div className="grid shrink-0 grid-cols-2 gap-x-5 gap-y-2 text-xs text-steel sm:grid-cols-4 lg:grid-cols-2">
          {["Any eligible issuer", "No bank details", "Multi-currency", "Settlement record"].map((item) => (
            <div key={item} className="flex items-center gap-2"><Check size={14} className="text-mint" /> {item}</div>
          ))}
        </div>
      </section>

      <div className="grid gap-5 xl:grid-cols-[420px_1fr]">
        <Card title="Create QuickLink">
          <form onSubmit={createLink} className="mt-4 space-y-4">
            <label className="block text-sm font-medium">Payment title
              <input required value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} placeholder="Website design services" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
            </label>
            <div className="grid grid-cols-[1fr_130px] gap-3">
              <label className="block text-sm font-medium">Amount
                <input required min="0.01" step="0.01" type="number" value={form.amount} onChange={(event) => setForm({ ...form, amount: event.target.value })} placeholder="2500.00" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
              </label>
              <label className="block text-sm font-medium">Currency
                <select value={form.currency} onChange={(event) => setForm({ ...form, currency: event.target.value })} className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2.5 outline-none focus:border-mint">
                  {currencies.map((currency) => <option key={currency}>{currency}</option>)}
                </select>
              </label>
            </div>
            <label className="block text-sm font-medium">Purpose
              <select value={form.purpose_code} onChange={(event) => setForm({ ...form, purpose_code: event.target.value })} className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2.5 outline-none focus:border-mint">
                {purposeCodes.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </label>
            <div className="grid gap-3 sm:grid-cols-2">
              <label className="block text-sm font-medium">Payer name <span className="font-normal text-steel">(optional)</span>
                <input value={form.payer_name} onChange={(event) => setForm({ ...form, payer_name: event.target.value })} placeholder="Client or company" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
              </label>
              <label className="block text-sm font-medium">Payer email <span className="font-normal text-steel">(optional)</span>
                <input type="email" value={form.payer_email} onChange={(event) => setForm({ ...form, payer_email: event.target.value })} placeholder="billing@client.com" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
              </label>
            </div>
            <label className="block text-sm font-medium">Payer country <span className="font-normal text-steel">(two-letter code)</span>
              <input maxLength={2} value={form.payer_country} onChange={(event) => setForm({ ...form, payer_country: event.target.value.toUpperCase().replace(/[^A-Z]/g, "") })} placeholder="IN" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 uppercase outline-none focus:border-mint" />
            </label>
            <label className="block text-sm font-medium">Link expires
              <select value={form.expires_in_days} onChange={(event) => setForm({ ...form, expires_in_days: event.target.value })} className="mt-1 w-full rounded-md border border-slate-300 bg-white px-3 py-2.5 outline-none focus:border-mint">
                {[7, 14, 30, 60, 90].map((days) => <option key={days} value={days}>{days} days</option>)}
              </select>
            </label>
            <button disabled={loading === "create" || !Number(form.amount)} className="flex w-full items-center justify-center gap-2 rounded-md bg-ink px-4 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:opacity-60">
              {loading === "create" ? <LoaderCircle size={17} className="animate-spin" /> : <Send size={17} />}
              {loading === "create" ? "Creating secure checkout..." : "Create QuickLink"}
            </button>
            <div className="flex items-start gap-2 rounded-md bg-panel p-3 text-xs text-steel">
              <ShieldCheck size={16} className="mt-0.5 shrink-0 text-mint" />
              Card details are entered on the processor-hosted checkout and are not stored by LedgerOps. Acceptance depends on the card network, issuer settings, country, currency, and processor coverage.
            </div>
            {notice && (
              <div className={`rounded-md p-3 text-sm ${noticeTone === "error" ? "bg-red-50 text-coral" : noticeTone === "success" ? "bg-emerald-50 text-emerald-800" : "bg-panel text-steel"}`}>
                {notice}
              </div>
            )}
            {createdLink && (
              <div className="rounded-md border border-mint/40 bg-mint/5 p-3">
                <div className="text-sm font-medium">{createdLink.status === "pending_review" ? "Manual approval required" : "Your QuickLink is ready"}</div>
                <div className="mt-1 break-all text-xs text-steel">{createdLink.checkout_url || "Approve this QuickLink from the list before sharing checkout."}</div>
                <div className="mt-3 flex flex-wrap gap-2">
                  {createdLink.status === "pending_review" ? (
                    <button type="button" onClick={() => approve(createdLink)} disabled={loading === `approve-${createdLink.id}`} className="inline-flex items-center gap-1.5 rounded-md bg-ink px-3 py-2 text-xs font-medium text-white disabled:opacity-60"><ShieldCheck size={14} /> Approve review</button>
                  ) : (
                    <>
                      <button type="button" onClick={() => copyLink(createdLink)} className="inline-flex items-center gap-1.5 rounded-md border border-slate-300 bg-white px-3 py-2 text-xs font-medium"><Copy size={14} /> Copy link</button>
                      <a href={createdLink.checkout_url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 rounded-md bg-mint px-3 py-2 text-xs font-medium text-white"><ExternalLink size={14} /> Open payer checkout</a>
                    </>
                  )}
                </div>
              </div>
            )}
          </form>
        </Card>

        <Card title="QuickLinks" actions={<button type="button" onClick={() => load().catch((error) => setNotice(error.message))} title="Refresh links" className="grid h-8 w-8 place-items-center rounded-md border border-slate-300 text-steel hover:bg-panel"><RefreshCw size={15} /></button>}>
          <div className="mt-4 space-y-3">
            {links.map((link) => (
              <article key={link.id} className="rounded-md border border-slate-200 p-4">
                <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="font-medium">{link.title}</h3>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-medium capitalize ${statusStyle(link.status)}`}>{link.status.replaceAll("_", " ")}</span>
                    </div>
                    <div className="mt-1 text-lg font-semibold">{formatCurrency(link.amount, link.currency)}</div>
                    <div className="mt-1 text-xs text-steel">
                      {link.payer_name || "Open payer"}{link.payer_email ? ` | ${link.payer_email}` : ""}{link.payer_country ? ` | ${link.payer_country}` : ""} | {link.purpose_code.replaceAll("_", " ")}
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {link.status === "pending_review" && (
                      <button type="button" onClick={() => approve(link)} disabled={loading === `approve-${link.id}`} className="inline-flex items-center gap-1.5 rounded-md bg-ink px-3 py-2 text-xs font-medium text-white disabled:opacity-60"><ShieldCheck size={14} /> Approve</button>
                    )}
                    {link.status === "active" && (
                      <>
                        <button type="button" onClick={() => copyLink(link)} className="inline-flex items-center gap-1.5 rounded-md border border-slate-300 px-3 py-2 text-xs font-medium hover:bg-panel">
                          {copiedId === link.id ? <CheckCircle2 size={14} className="text-mint" /> : <Copy size={14} />} {copiedId === link.id ? "Copied" : "Copy"}
                        </button>
                        <a href={link.checkout_url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 rounded-md bg-mint px-3 py-2 text-xs font-medium text-white hover:bg-emerald-700"><ExternalLink size={14} /> Open</a>
                      </>
                    )}
                    {link.remittance_available && (
                      <button type="button" onClick={() => downloadRemittance(link)} disabled={loading === `document-${link.id}`} className="inline-flex items-center gap-1.5 rounded-md bg-ink px-3 py-2 text-xs font-medium text-white disabled:opacity-60"><Download size={14} /> Remittance PDF</button>
                    )}
                    {link.receipt_available && (
                      <button type="button" onClick={() => downloadReceipt(link)} disabled={loading === `receipt-${link.id}`} className="inline-flex items-center gap-1.5 rounded-md border border-slate-300 px-3 py-2 text-xs font-medium hover:bg-panel disabled:opacity-60"><FileText size={14} /> Receipt</button>
                    )}
                    {link.status === "paid" && (
                      <button type="button" onClick={() => refund(link)} disabled={loading === `refund-${link.id}`} className="inline-flex items-center gap-1.5 rounded-md border border-coral/40 px-3 py-2 text-xs font-medium text-coral hover:bg-coral/5 disabled:opacity-60"><RotateCcw size={14} /> Refund</button>
                    )}
                  </div>
                </div>
                <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 pt-3">
                  <div className="flex items-center gap-2 text-xs text-steel"><Clock3 size={14} /> Expires {new Date(link.expires_at).toLocaleDateString()}</div>
                  {["active", "pending_review"].includes(link.status) && (
                    <div className="flex gap-2">
                      {link.status === "active" && (
                        <button type="button" onClick={() => verify(link)} disabled={loading === `verify-${link.id}`} className="inline-flex items-center gap-1.5 text-xs font-medium text-steel hover:text-mint disabled:opacity-60">
                          <RefreshCw size={13} className={loading === `verify-${link.id}` ? "animate-spin" : ""} /> Check payment
                        </button>
                      )}
                      <button type="button" onClick={() => disable(link)} disabled={loading === `disable-${link.id}`} className="inline-flex items-center gap-1.5 text-xs font-medium text-steel hover:text-coral disabled:opacity-60"><Ban size={13} /> Disable</button>
                    </div>
                  )}
                </div>
              </article>
            ))}
            {!links.length && (
              <div className="rounded-md border border-dashed border-slate-300 px-5 py-10 text-center">
                <Link2 size={24} className="mx-auto text-steel" />
                <div className="mt-3 text-sm font-medium">No QuickLinks yet</div>
                <div className="mt-1 text-sm text-steel">Your international card collection links will appear here.</div>
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}
