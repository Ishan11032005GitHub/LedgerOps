import { useEffect, useState } from "react";
import { Bell, CheckCircle2, Clock3, Download, FileText, History, LockKeyhole, Receipt, RefreshCw, ShieldCheck, UserCheck } from "lucide-react";
import { Card, Skeleton } from "../components/Card.jsx";
import { api, apiBlob } from "../lib/api.js";
import { readStoredUser, accountStorageKey } from "../lib/account.js";
import { downloadCsv, downloadJson } from "../lib/downloads.js";

function money(amount, currency = "USD") {
  return new Intl.NumberFormat(undefined, { style: "currency", currency, maximumFractionDigits: 0 }).format(Number(amount || 0));
}

function localKey(name) {
  return `${name}:${accountStorageKey()}`;
}

function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}

async function loadWorkspace() {
  const [payments, invoices, clients, alerts, quicklinks] = await Promise.all([
    api("/api/payments").catch(() => []),
    api("/api/invoices").catch(() => []),
    api("/api/customers").catch(() => []),
    api("/api/alerts").catch(() => []),
    api("/api/payment-app/quicklinks").catch(() => []),
  ]);
  return { payments, invoices, clients, alerts, quicklinks };
}

function severityClass(value) {
  const severity = String(value || "").toLowerCase();
  if (severity.includes("high") || severity.includes("overdue") || severity.includes("failed")) return "border-coral/30 bg-coral/10 text-coral";
  if (severity.includes("medium") || severity.includes("pending") || severity.includes("review")) return "border-amber-300 bg-amber-50 text-amber-700";
  return "border-mint/30 bg-mint/10 text-mint";
}

export default function ProductOps({ mode }) {
  const [data, setData] = useState(null);
  const [audit, setAudit] = useState([]);
  const [reconciliation, setReconciliation] = useState(null);
  const [busy, setBusy] = useState("");
  const [notice, setNotice] = useState("");

  useEffect(() => {
    setData(null);
    loadWorkspace().then(setData).catch((error) => setNotice(error.message));
    if (["audit", "action-center"].includes(mode)) {
      api("/api/payment-app/audit-log").then(setAudit).catch(() => setAudit([]));
    }
  }, [mode]);

  if (!data) return <Skeleton />;

  const props = { data, audit, reconciliation, setReconciliation, busy, setBusy, notice, setNotice };
  if (mode === "action-center") return <ActionCenter {...props} />;
  if (mode === "payment-timeline") return <PaymentTimeline {...props} />;
  if (mode === "receipt-center") return <ReceiptCenter {...props} />;
  if (mode === "client-profiles") return <ClientProfiles {...props} />;
  if (mode === "approvals") return <ApprovalWorkflows {...props} />;
  if (mode === "audit") return <AuditLog {...props} />;
  if (mode === "notifications") return <Notifications {...props} />;
  if (mode === "reconciliation") return <ReconciliationDashboard {...props} />;
  if (mode === "permissions") return <RolePermissions {...props} />;
  if (mode === "demo-story") return <DemoStory {...props} />;
  return <ActionCenter {...props} />;
}

function PageHero({ eyebrow, title, helper, icon: Icon = CheckCircle2, actions }) {
  return (
    <section className="mb-6 flex flex-col justify-between gap-4 rounded-lg border border-slate-200 bg-white p-5 shadow-soft md:flex-row md:items-center">
      <div className="flex min-w-0 items-center gap-4">
        <div className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-mint/10 text-mint"><Icon size={24} /></div>
        <div>
          <div className="text-sm font-medium text-mint">{eyebrow}</div>
          <h2 className="text-2xl font-semibold">{title}</h2>
          <p className="mt-1 text-sm text-steel">{helper}</p>
        </div>
      </div>
      {actions && <div className="flex shrink-0 flex-wrap gap-2">{actions}</div>}
    </section>
  );
}

function ActionCenter({ data, audit }) {
  const overdue = data.invoices.filter((invoice) => invoice.status === "pending");
  const highRisk = data.clients.filter((client) => String(client.risk_rating).toLowerCase() === "high" || String(client.kyc_status).toLowerCase().includes("review"));
  const expiredLinks = data.quicklinks.filter((link) => ["expired", "disabled"].includes(link.status));
  const items = [
    ...data.alerts.map((alert, index) => ({ id: `alert-${index}`, type: `${alert.severity} / ${alert.category}`, title: alert.message, detail: "Generated from account alerts", tone: alert.severity })),
    ...overdue.map((invoice) => ({ id: `invoice-${invoice.id}`, type: "Overdue receivable", title: `${invoice.invoice_number} is still ${invoice.status}`, detail: `${money(invoice.amount, invoice.currency)} due ${invoice.due_date}`, tone: "medium" })),
    ...highRisk.map((client) => ({ id: `client-${client.id}`, type: "Client review", title: client.name, detail: `${client.risk_rating} risk | KYC ${client.kyc_status}`, tone: client.risk_rating })),
    ...expiredLinks.map((link) => ({ id: `link-${link.id}`, type: "QuickLink attention", title: link.title, detail: `Status: ${link.status}`, tone: "medium" })),
  ];
  return (
    <>
      <PageHero eyebrow="Operations inbox" title="Action Center" helper="One place for overdue invoices, risk flags, compliance items, failed links, and workflow work." icon={Bell} />
      <div className="grid gap-4 lg:grid-cols-[1fr_360px]">
        <Card title="Needs attention" actions={<span className="rounded-full bg-coral/10 px-3 py-1 text-xs font-medium text-coral">{items.length} open</span>}>
          <div className="mt-4 grid gap-3">
            {items.length ? items.map((item) => (
              <div key={item.id} className={`rounded-md border p-4 ${severityClass(item.tone)}`}>
                <div className="text-xs font-medium uppercase tracking-normal">{item.type}</div>
                <div className="mt-1 font-semibold text-ink">{item.title}</div>
                <div className="mt-1 text-sm text-steel">{item.detail}</div>
              </div>
            )) : <Empty label="No open action items. Your workspace is clean." />}
          </div>
        </Card>
        <Card title="Recent operational activity">
          <div className="mt-4 space-y-3">
            {audit.slice(0, 6).map((row) => (
              <div key={row.id} className="rounded-md border border-slate-200 p-3 text-sm">
                <div className="font-medium">{row.action}</div>
                <div className="mt-1 text-xs text-steel">{new Date(row.created_at).toLocaleString()}</div>
              </div>
            ))}
            {!audit.length && <Empty label="Audit activity appears here for admin accounts." />}
          </div>
        </Card>
      </div>
    </>
  );
}

function PaymentTimeline({ data }) {
  const rows = data.payments.slice(0, 30);
  const steps = ["Created", "Authorized", "Settled", "Receipt ready", "Reconciled"];
  return (
    <>
      <PageHero eyebrow="Traceability" title="Payment Timeline" helper="Follow each payment from creation through settlement, receipt, and reconciliation." icon={History} />
      <div className="grid gap-4">
        {rows.map((payment) => (
          <Card key={payment.id} title={`${payment.recipient || "Payment"} | ${money(payment.amount, payment.currency)}`} helper={`${payment.external_ref || "No reference"} | ${payment.rail || "Payment rail"}`}>
            <div className="mt-5 grid gap-3 md:grid-cols-5">
              {steps.map((step, index) => {
                const done = index < 3 || String(payment.status).includes("settled") || String(payment.status).includes("refunded");
                return (
                  <div key={step} className={`rounded-md border p-3 ${done ? "border-mint/30 bg-mint/5" : "border-slate-200 bg-panel"}`}>
                    <CheckCircle2 size={16} className={done ? "text-mint" : "text-steel"} />
                    <div className="mt-2 text-sm font-medium">{step}</div>
                    <div className="mt-1 text-xs text-steel">{done ? "Complete" : "Waiting"}</div>
                  </div>
                );
              })}
            </div>
          </Card>
        ))}
        {!rows.length && <Card><Empty label="No payment timeline yet. Create a QuickLink or payment first." /></Card>}
      </div>
    </>
  );
}

function ReceiptCenter({ data, setNotice }) {
  async function downloadPayment(payment) {
    try {
      const blob = await apiBlob(`/api/payment-app/payments/${payment.id}/receipt`);
      downloadBlob(blob, `receipt-payment-${payment.id}.pdf`);
    } catch (error) {
      setNotice(error.message);
    }
  }
  async function downloadQuickLink(link, type) {
    try {
      const blob = await apiBlob(`/api/payment-app/quicklinks/${link.id}/${type}`);
      downloadBlob(blob, `${type}-${link.public_id}.pdf`);
    } catch (error) {
      setNotice(error.message);
    }
  }
  const paidLinks = data.quicklinks.filter((link) => link.receipt_available || link.remittance_available || ["paid", "refunded", "partially_refunded"].includes(link.status));
  return (
    <>
      <PageHero eyebrow="Documents" title="Receipt Center" helper="Download payment receipts and remittance documents from one searchable operating surface." icon={Receipt}
        actions={<><button onClick={() => downloadCsv("receipt_center_payments.csv", data.payments)} className="rounded-md border border-slate-300 bg-white px-3 py-2 text-sm font-medium">CSV</button><button onClick={() => downloadJson("receipt_center.json", { payments: data.payments, quicklinks: paidLinks })} className="rounded-md border border-slate-300 bg-white px-3 py-2 text-sm font-medium">JSON</button></>} />
      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="Payment receipts">
          <div className="mt-4 space-y-3">
            {data.payments.map((payment) => (
              <div key={payment.id} className="flex items-center justify-between gap-3 rounded-md border border-slate-200 p-3">
                <div>
                  <div className="font-medium">{payment.recipient || `Payment ${payment.id}`}</div>
                  <div className="text-sm text-steel">{payment.external_ref || payment.status} | {money(payment.amount, payment.currency)}</div>
                </div>
                <button onClick={() => downloadPayment(payment)} className="inline-flex items-center gap-1 rounded-md bg-ink px-3 py-2 text-xs font-medium text-white"><Download size={14} /> Receipt</button>
              </div>
            ))}
            {!data.payments.length && <Empty label="No settled payments available." />}
          </div>
        </Card>
        <Card title="QuickLink remittance">
          <div className="mt-4 space-y-3">
            {paidLinks.map((link) => (
              <div key={link.id} className="rounded-md border border-slate-200 p-3">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <div className="font-medium">{link.title}</div>
                    <div className="text-sm text-steel">{link.public_id} | {money(link.amount, link.currency)} | {link.status}</div>
                  </div>
                  <div className="flex gap-2">
                    <button onClick={() => downloadQuickLink(link, "receipt")} className="rounded-md border border-slate-300 px-3 py-2 text-xs font-medium">Receipt</button>
                    <button onClick={() => downloadQuickLink(link, "remittance")} className="rounded-md bg-mint px-3 py-2 text-xs font-medium text-white">Remittance</button>
                  </div>
                </div>
              </div>
            ))}
            {!paidLinks.length && <Empty label="Paid QuickLinks will appear here." />}
          </div>
        </Card>
      </div>
    </>
  );
}

function ClientProfiles({ data }) {
  return (
    <>
      <PageHero eyebrow="Relationship intelligence" title="Client Profiles" helper="Review each client's payments, invoices, risk, currency, and delay behavior together." icon={UserCheck} />
      <div className="grid gap-4 xl:grid-cols-2">
        {data.clients.map((client) => {
          const payments = data.payments.filter((payment) => payment.recipient === client.name || payment.customer_id === client.id);
          const invoices = data.invoices.filter((invoice) => invoice.customer_id === client.id);
          return (
            <Card key={client.id} title={client.name} actions={<span className={`rounded-full px-2 py-1 text-xs font-medium ${severityClass(client.risk_rating)}`}>{client.risk_rating}</span>}>
              <div className="mt-4 grid gap-3 sm:grid-cols-4">
                <Metric label="Currency" value={client.currency} />
                <Metric label="KYC" value={client.kyc_status} />
                <Metric label="Avg delay" value={`${client.avg_delay_days || 0}d`} />
                <Metric label="Invoices" value={invoices.length} />
              </div>
              <div className="mt-4 rounded-md border border-slate-200 p-3">
                <div className="text-sm font-medium">Recent payments</div>
                <div className="mt-2 space-y-2">
                  {payments.slice(0, 3).map((payment) => <div key={payment.id} className="flex justify-between text-sm"><span>{payment.external_ref}</span><span>{money(payment.amount, payment.currency)}</span></div>)}
                  {!payments.length && <div className="text-sm text-steel">No payments yet.</div>}
                </div>
              </div>
            </Card>
          );
        })}
        {!data.clients.length && <Card><Empty label="No clients yet." /></Card>}
      </div>
    </>
  );
}

function ApprovalWorkflows() {
  const user = readStoredUser();
  const [items, setItems] = useState(() => JSON.parse(localStorage.getItem(localKey("approval_workflows")) || "[]"));
  const [draft, setDraft] = useState("Approve high-value QuickLink refund");
  function save(next) {
    setItems(next);
    localStorage.setItem(localKey("approval_workflows"), JSON.stringify(next));
  }
  function add() {
    save([{ id: Date.now(), title: draft, requester: user.name || "Admin", status: "Pending manager approval", created_at: new Date().toISOString() }, ...items]);
    setDraft("");
  }
  function approve(id) {
    save(items.map((item) => item.id === id ? { ...item, status: "Approved" } : item));
  }
  return (
    <>
      <PageHero eyebrow="Controls" title="Approval Workflows" helper="Model manager/admin approval before sensitive finance actions are released." icon={ShieldCheck} />
      <Card title="Create approval request">
        <div className="mt-4 flex gap-3">
          <input value={draft} onChange={(event) => setDraft(event.target.value)} className="min-w-0 flex-1 rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint" />
          <button onClick={add} disabled={!draft.trim()} className="rounded-md bg-ink px-4 py-2 font-medium text-white disabled:opacity-50">Create</button>
        </div>
      </Card>
      <div className="mt-4 grid gap-3">
        {items.map((item) => <Card key={item.id} title={item.title} helper={`${item.requester} | ${new Date(item.created_at).toLocaleString()}`} actions={<button onClick={() => approve(item.id)} className="rounded-md border border-slate-300 px-3 py-2 text-sm">{item.status === "Approved" ? "Approved" : "Approve"}</button>}><div className="mt-3 text-sm text-steel">{item.status}</div></Card>)}
        {!items.length && <Card><Empty label="No approval requests yet." /></Card>}
      </div>
    </>
  );
}

function AuditLog({ audit }) {
  return (
    <>
      <PageHero eyebrow="Trust trail" title="Audit Log" helper="Review sensitive user, payment, refund, reconciliation, and account actions." icon={LockKeyhole}
        actions={<button onClick={() => downloadCsv("audit_log.csv", audit)} className="rounded-md border border-slate-300 bg-white px-3 py-2 text-sm font-medium">CSV</button>} />
      <Card title="Workspace audit events">
        <div className="mt-4 overflow-auto">
          {audit.length ? <table className="min-w-full text-left text-sm"><thead><tr>{["created_at", "action", "entity_type", "outcome"].map((column) => <th key={column} className="border-b border-slate-200 px-3 py-2 text-steel">{column}</th>)}</tr></thead><tbody>{audit.map((row) => <tr key={row.id}><td className="border-b border-slate-100 px-3 py-2">{new Date(row.created_at).toLocaleString()}</td><td className="border-b border-slate-100 px-3 py-2">{row.action}</td><td className="border-b border-slate-100 px-3 py-2">{row.entity_type}</td><td className="border-b border-slate-100 px-3 py-2">{row.outcome}</td></tr>)}</tbody></table> : <Empty label="No audit events available for this role." />}
        </div>
      </Card>
    </>
  );
}

function Notifications({ data }) {
  const notifications = [
    ...data.alerts.map((alert, index) => ({ id: `alert-${index}`, title: alert.message, detail: `${alert.severity} ${alert.category}` })),
    ...data.quicklinks.filter((link) => link.status === "paid").map((link) => ({ id: `ql-${link.id}`, title: `QuickLink paid: ${link.title}`, detail: money(link.amount, link.currency) })),
    ...data.invoices.filter((invoice) => invoice.status === "pending").map((invoice) => ({ id: `inv-${invoice.id}`, title: `Invoice pending: ${invoice.invoice_number}`, detail: money(invoice.amount, invoice.currency) })),
  ];
  return (
    <>
      <PageHero eyebrow="Attention queue" title="Notifications" helper="In-app notification feed for payments, invoices, QuickLinks, risk, and compliance changes." icon={Bell} />
      <Card title="Latest notifications">
        <div className="mt-4 grid gap-3">
          {notifications.map((item) => <div key={item.id} className="rounded-md border border-slate-200 p-3"><div className="font-medium">{item.title}</div><div className="mt-1 text-sm text-steel">{item.detail}</div></div>)}
          {!notifications.length && <Empty label="No notifications yet." />}
        </div>
      </Card>
    </>
  );
}

function ReconciliationDashboard({ data, reconciliation, setReconciliation, busy, setBusy, setNotice }) {
  async function run() {
    setBusy("reconcile");
    setNotice("");
    try {
      setReconciliation(await api("/api/payment-app/reconciliation", { method: "POST" }));
    } catch (error) {
      setNotice(error.message);
    } finally {
      setBusy("");
    }
  }
  const matched = reconciliation?.matched_count ?? data.payments.filter((payment) => payment.external_ref).length;
  const checked = reconciliation?.checked_count ?? data.payments.length;
  const exceptions = reconciliation?.exceptions || data.payments.filter((payment) => !payment.external_ref).map((payment) => ({ payment_id: payment.id, issues: ["missing_processor_reference"] }));
  return (
    <>
      <PageHero eyebrow="Settlement control" title="Reconciliation Dashboard" helper="Compare LedgerOps records against processor references and invoice settlement state." icon={RefreshCw}
        actions={<button onClick={run} disabled={busy === "reconcile"} className="rounded-md bg-ink px-4 py-2 text-sm font-medium text-white disabled:opacity-60">{busy === "reconcile" ? "Checking..." : "Run reconciliation"}</button>} />
      <div className="grid gap-4 md:grid-cols-3">
        <MetricCard label="Checked" value={checked} />
        <MetricCard label="Matched" value={matched} />
        <MetricCard label="Exceptions" value={exceptions.length} tone={exceptions.length ? "danger" : "success"} />
      </div>
      <div className="mt-4"><Card title="Exceptions">{exceptions.length ? <div className="mt-4 space-y-3">{exceptions.map((item, index) => <div key={index} className="rounded-md border border-coral/30 bg-coral/5 p-3 text-sm">Payment {item.payment_id}: {(item.issues || []).join(", ")}</div>)}</div> : <Empty label="No reconciliation exceptions detected." />}</Card></div>
    </>
  );
}

function RolePermissions() {
  const permissions = [
    ["View dashboard", "Admin", "Finance Manager", "Viewer"],
    ["Create QuickLinks", "Admin", "Finance Manager", ""],
    ["Refund payments", "Admin", "Finance Manager", ""],
    ["Export finance data", "Admin", "Finance Manager", "Viewer"],
    ["Manage employees", "Admin", "", ""],
    ["View audit log", "Admin", "", ""],
  ];
  return (
    <>
      <PageHero eyebrow="Access control" title="Role Permission Editor" helper="A product-ready permission map for company accounts. Hidden data should not render for unauthorized roles." icon={LockKeyhole} />
      <Card title="Permission matrix">
        <table className="mt-4 min-w-full text-left text-sm">
          <thead><tr>{["Permission", "Admin", "Finance Manager", "Viewer"].map((column) => <th key={column} className="border-b border-slate-200 px-3 py-2 text-steel">{column}</th>)}</tr></thead>
          <tbody>{permissions.map((row) => <tr key={row[0]}>{row.map((cell, index) => <td key={index} className="border-b border-slate-100 px-3 py-3">{index === 0 ? cell : cell ? <CheckCircle2 className="text-mint" size={17} /> : ""}</td>)}</tr>)}</tbody>
        </table>
      </Card>
    </>
  );
}

function DemoStory({ data }) {
  const steps = [
    ["Create QuickLink", data.quicklinks.length > 0],
    ["Accept payment", data.quicklinks.some((link) => ["paid", "refunded", "partially_refunded"].includes(link.status)) || data.payments.length > 0],
    ["Detect risk", data.alerts.length > 0],
    ["Generate receipt", data.payments.length > 0],
    ["Ask Copilot", true],
  ];
  return (
    <>
      <PageHero eyebrow="Presentation mode" title="Demo Story Mode" helper="A guided path for showing LedgerOps as a complete finance operating system." icon={FileText} />
      <div className="grid gap-4 md:grid-cols-5">
        {steps.map(([label, done], index) => <Card key={label} title={`Step ${index + 1}`} value={label}><div className={`mt-4 inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-medium ${done ? "bg-mint/10 text-mint" : "bg-amber-50 text-amber-700"}`}>{done ? <CheckCircle2 size={14} /> : <Clock3 size={14} />} {done ? "Ready" : "Try now"}</div></Card>)}
      </div>
    </>
  );
}

function MetricCard({ label, value, tone = "neutral" }) {
  const color = tone === "danger" ? "text-coral" : tone === "success" ? "text-mint" : "text-ink";
  return <Card title={label} value={<span className={color}>{value}</span>} />;
}

function Metric({ label, value }) {
  return <div className="rounded-md border border-slate-200 bg-panel p-3"><div className="text-xs uppercase text-steel">{label}</div><div className="mt-1 font-semibold">{value}</div></div>;
}

function Empty({ label }) {
  return <div className="rounded-md border border-dashed border-slate-300 px-4 py-8 text-center text-sm text-steel">{label}</div>;
}
