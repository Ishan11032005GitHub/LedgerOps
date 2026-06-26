import { useEffect, useRef, useState } from "react";
import { Area, AreaChart, Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Download } from "lucide-react";
import { Card, Skeleton } from "../components/Card.jsx";
import { accountStorageKey, readStoredUser, workspaceName } from "../lib/account.js";
import { api } from "../lib/api.js";
import { downloadCsv, downloadJson, downloadSvg } from "../lib/downloads.js";

const money = (n, currency = "USD") => new Intl.NumberFormat("en-US", { style: "currency", currency, maximumFractionDigits: 0 }).format(n || 0);
const dashboardCache = {};
const dashboardRequest = {};

export function prefetchDashboard() {
  const key = accountStorageKey();
  if (dashboardCache[key]) return Promise.resolve(dashboardCache[key]);
  if (!dashboardRequest[key]) {
    dashboardRequest[key] = api("/api/dashboard")
      .then((result) => {
        dashboardCache[key] = result;
        return result;
      })
      .finally(() => {
        delete dashboardRequest[key];
      });
  }
  return dashboardRequest[key];
}

export default function Dashboard() {
  const cacheKey = accountStorageKey();
  const [data, setData] = useState(dashboardCache[cacheKey]);
  const [error, setError] = useState("");
  useEffect(() => {
    const key = accountStorageKey();
    setData(dashboardCache[key] || null);
    setError("");
    prefetchDashboard().then((result) => {
      setData(result);
    }).catch((err) => {
      if (!dashboardCache[key]) setError(err.message);
    });
  }, [cacheKey]);
  if (error) return <Card title="Dashboard unavailable" helper={error}><div className="mt-4 text-sm text-steel">Sign out and sign back in if your session token is stale.</div></Card>;
  if (!data) return <div className="grid gap-4 md:grid-cols-3"><Skeleton /><Skeleton /><Skeleton /></div>;
  const exposure = Object.entries(data.currency_exposure).map(([currency, amount]) => ({ currency, amount }));
  const account = readStoredUser();
  const workspace = workspaceName(account);
  const accountLabel = account.name || "this account";
  const reportingCurrency = data.reporting_currency || "USD";
  const riskLabel = data.risk_score >= 70 ? "Elevated review" : data.risk_score >= 45 ? "Watchlist" : "Controlled";
  const runwayLabel = data.cash_runway == null ? "Not enough data" : `${data.cash_runway} days`;
  const volumeHelper = data.conversion_complete
    ? `Settled payments converted to ${reportingCurrency}`
    : `Excludes ${data.unconverted_currencies.join(", ")} without a ${reportingCurrency} conversion rate`;
  const stats = [
    { metric: "total_transaction_volume", value: data.total_volume, unit: reportingCurrency },
    { metric: "pending_invoices", value: data.pending_invoices, unit: "count" },
    { metric: "cash_runway", value: data.cash_runway ?? "", unit: "days" },
    { metric: "currency_exposure_count", value: exposure.length, unit: "count" },
    { metric: "risk_score", value: data.risk_score || 24, unit: "score" },
  ];
  return (
    <div className="space-y-6">
      <div className="flex flex-col justify-between gap-3 rounded-lg border border-slate-200 bg-white p-5 shadow-soft md:flex-row md:items-center">
        <div>
          <div className="text-sm font-medium text-mint">{workspace}</div>
          <h2 className="mt-1 text-2xl font-semibold">{accountLabel}'s operating snapshot</h2>
          <p className="mt-1 text-sm text-steel">Account-specific posture for {account.email || workspace} across payments, receivables, currency exposure, and anomaly signals.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button onClick={() => downloadCsv("dashboard_stats.csv", stats, ["metric", "value", "unit"])} className="inline-flex items-center gap-2 rounded-md border border-slate-300 bg-white px-3 py-2 text-sm font-medium hover:bg-panel"><Download size={15} /> Stats CSV</button>
          <button onClick={() => downloadJson("dashboard_snapshot.json", { stats, dashboard: data })} className="inline-flex items-center gap-2 rounded-md border border-slate-300 bg-white px-3 py-2 text-sm font-medium hover:bg-panel"><Download size={15} /> JSON</button>
          <div className="rounded-md border border-slate-200 px-4 py-3 text-right">
          <div className="text-xs uppercase tracking-wide text-steel">Risk posture</div>
          <div className="mt-1 text-lg font-semibold">{riskLabel}</div>
          </div>
        </div>
      </div>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
        <Card title="Total transaction volume" value={money(data.total_volume, reportingCurrency)} helper={volumeHelper} />
        <Card title="Pending invoices" value={data.pending_invoices} helper="Open receivables" />
        <Card title="Cash runway" value={runwayLabel} helper={data.cash_runway == null ? "Requires outbound activity and usable FX rates" : `Based on ${money(data.runway_inputs?.observed_monthly_burn, reportingCurrency)} observed monthly burn`} />
        <Card title="Currency exposure" value={exposure.length} helper="Active currencies" />
        <Card title="Risk score" value={data.risk_score || 24} helper="Anomaly-weighted" />
      </div>
      <div className="grid gap-5 xl:grid-cols-[1.4fr_1fr]">
        <ChartCard title={`Monthly Transaction Volume (${reportingCurrency})`} filename="monthly_transaction_volume" rows={data.monthly_transactions}>
          {(chartRef) => <div ref={chartRef} className="mt-4 h-80"><ResponsiveContainer><AreaChart data={data.monthly_transactions}><defs><linearGradient id="volume" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="#00a676" stopOpacity="0.5"/><stop offset="100%" stopColor="#00a676" stopOpacity="0.05"/></linearGradient></defs><CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0"/><XAxis dataKey="month"/><YAxis/><Tooltip/><Area dataKey="volume" stroke="#00a676" fill="url(#volume)" /></AreaChart></ResponsiveContainer></div>}
        </ChartCard>
        <Card title="Priority Alerts" actions={<ExportActions filename="priority_alerts" rows={data.alerts} />}>
          <div className="mt-4 space-y-3">{data.alerts.map((alert, i) => <div key={i} className="rounded-md border border-slate-200 p-3"><div className="text-xs uppercase text-coral">{alert.severity} / {alert.category}</div><div className="mt-1 text-sm">{alert.message}</div></div>)}</div>
        </Card>
      </div>
      <div className="grid gap-5 xl:grid-cols-3">
        <ChartCard title={`Cash Flow (${reportingCurrency})`} filename="cash_flow" rows={data.cash_flow}>
          {(chartRef) => <div ref={chartRef} className="mt-4 h-64"><ResponsiveContainer><BarChart data={data.cash_flow}><CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0"/><XAxis dataKey="month"/><YAxis/><Tooltip/><Bar dataKey="incoming" fill="#00a676"/><Bar dataKey="expenses" fill="#f25f5c"/></BarChart></ResponsiveContainer></div>}
        </ChartCard>
        <ChartCard title="FX Trend" filename="fx_trend" rows={data.fx_trends.slice(-35)}>
          {(chartRef) => <div ref={chartRef} className="mt-4 h-64"><ResponsiveContainer><LineChart data={data.fx_trends.slice(-35)}><CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0"/><XAxis dataKey="currency"/><YAxis/><Tooltip/><Line dataKey="rate" stroke="#2563eb" dot={false}/><Line dataKey="volatility" stroke="#f25f5c" dot={false}/></LineChart></ResponsiveContainer></div>}
        </ChartCard>
        <Card title={`Country Payment Exposure (${reportingCurrency})`} actions={<ExportActions filename="country_payment_exposure" rows={data.country_heatmap} />}><div className="mt-4 space-y-3">{data.country_heatmap.map((item) => <div key={item.country}><div className="mb-1 flex justify-between text-sm"><span>{item.country}</span><span>{money(item.volume, reportingCurrency)}</span></div><div className="h-2 rounded bg-slate-100"><div className="h-2 rounded bg-mint" style={{ width: `${Math.min(100, item.volume / 2000)}%` }} /></div></div>)}</div></Card>
      </div>
      <ChartCard title="Anomaly Score Distribution" filename="anomaly_score_distribution" rows={data.anomalies}>
        {(chartRef) => <div ref={chartRef} className="mt-4 h-72"><ResponsiveContainer><BarChart data={data.anomalies}><CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0"/><XAxis dataKey="name" hide/><YAxis/><Tooltip/><Bar dataKey="score" fill="#f25f5c"/></BarChart></ResponsiveContainer></div>}
      </ChartCard>
    </div>
  );
}

function ExportActions({ filename, rows }) {
  return (
    <>
      <button onClick={() => downloadCsv(`${filename}.csv`, rows)} className="rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel">CSV</button>
      <button onClick={() => downloadJson(`${filename}.json`, rows)} className="rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel">JSON</button>
    </>
  );
}

function ChartCard({ title, filename, rows, children }) {
  const chartRef = useRef(null);
  return (
    <Card title={title} actions={
      <>
        <button onClick={() => downloadSvg(`${filename}.svg`, chartRef.current)} className="rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel">SVG</button>
        <button onClick={() => downloadCsv(`${filename}.csv`, rows)} className="rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel">CSV</button>
      </>
    }>
      {children(chartRef)}
    </Card>
  );
}
