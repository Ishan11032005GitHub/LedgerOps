import { useEffect, useMemo, useState } from "react";
import { Activity, AlertTriangle, Brain, CheckCircle2, Landmark, ListChecks, ShieldAlert, TrendingUp } from "lucide-react";
import { Card } from "../components/Card.jsx";
import { api } from "../lib/api.js";

const modes = {
  fx: {
    title: "FX Intelligence Engine",
    label: "Currency exposure",
    icon: Landmark,
    endpoint: "/api/predict/fx",
    summary: "Live currency posture across open invoices, recent rate movement, and conversion timing.",
  },
  fraud: {
    title: "Fraud / Anomaly Detection",
    label: "Payment anomaly",
    icon: ShieldAlert,
    endpoint: "/api/predict/anomaly",
    summary: "Continuous review of unusual payment amount, payer, country, and settlement patterns.",
  },
  cash: {
    title: "Cash Runway Forecasting",
    label: "Runway forecast",
    icon: Activity,
    endpoint: "/api/predict/runway",
    summary: "Runway view based on recent payments, open receivables, payroll, and operating burn.",
  },
  compliance: {
    title: "Compliance Engine",
    label: "Compliance review",
    icon: Brain,
    endpoint: "/api/compliance/current",
    summary: "Payment review for KYC, document completeness, amount match, and escalation needs.",
  },
};
const insightCache = {};

export default function IntelligencePage({ mode }) {
  const config = modes[mode];
  const Icon = config.icon;
  const [result, setResult] = useState(insightCache[mode] || null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function loadInsight() {
    setLoading(true);
    setError("");
    try {
      const response = await api(config.endpoint, { method: "POST", body: JSON.stringify({}) });
      insightCache[mode] = response;
      setResult(response);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    setResult(insightCache[mode] || null);
    loadInsight();
  }, [mode]);

  const view = useMemo(() => buildView(mode, result), [mode, result]);

  return (
    <div className="space-y-5">
      <Card>
        <div className="flex flex-col justify-between gap-4 lg:flex-row lg:items-center">
          <div className="flex items-center gap-3">
            <div className="grid h-12 w-12 place-items-center rounded-md bg-mint/10 text-mint"><Icon /></div>
            <div>
              <h2 className="text-2xl font-semibold">{config.title}</h2>
              <p className="mt-1 max-w-3xl text-sm leading-6 text-steel">{config.summary}</p>
            </div>
          </div>
          <div className="rounded-md border border-slate-200 bg-panel px-4 py-3 text-sm text-steel">
            {loading ? "Refreshing insight..." : error ? "Insight unavailable" : result?.data_status === "insufficient" ? "Waiting for account activity" : "Updated from current account data"}
          </div>
        </div>
      </Card>

      {error ? (
        <Card title="Insight Unavailable">
          <div className="mt-4 rounded-md bg-coral/10 p-4 text-sm text-coral">{error}</div>
        </Card>
      ) : result?.data_status === "insufficient" ? (
        <Card title="More Account Data Needed">
          <div className="mt-4 rounded-md border border-slate-200 bg-panel p-5">
            <p className="text-sm leading-6 text-steel">{result.reason}</p>
            <div className="mt-4">
              <div className="text-sm font-semibold">Required before analysis</div>
              <div className="mt-2 space-y-2">
                {(result.required || []).map((item) => (
                  <div key={item} className="flex gap-2 text-sm text-steel">
                    <CheckCircle2 size={15} className="mt-0.5 shrink-0 text-mint" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </Card>
      ) : (
        <Card title={!view ? "Loading Insight" : "Decision Summary"}>
          {!view ? (
            <div className="mt-4 grid gap-3 md:grid-cols-3">
              <div className="h-24 animate-pulse rounded-md bg-slate-200" />
              <div className="h-24 animate-pulse rounded-md bg-slate-200" />
              <div className="h-24 animate-pulse rounded-md bg-slate-200" />
            </div>
          ) : (
          <div className="mt-4 space-y-4">
            <div className="grid gap-3 md:grid-cols-3">
              <InsightCard label={view.primaryLabel} value={view.primaryValue} tone={view.tone} />
              <InsightCard label="Risk level" value={view.risk} tone={view.tone} />
              <InsightCard label="Confidence" value={view.confidence} tone="neutral" />
            </div>

            <div className="rounded-md border border-slate-200 p-4">
              <div className="flex items-center gap-2 text-sm font-semibold"><TrendingUp size={17} className="text-mint" /> Recommendation</div>
              <p className="mt-2 text-sm leading-6 text-steel">{view.recommendation}</p>
            </div>

            <div className="grid gap-4 lg:grid-cols-2">
              <Panel title="Key Signals" icon={AlertTriangle} items={view.signals} />
              <Panel title="Next Actions" icon={ListChecks} items={view.actions} />
            </div>
          </div>
          )}
        </Card>
      )}
    </div>
  );
}

function buildView(mode, result) {
  if (!result) return null;

  if (mode === "fx") {
    const risk = result.risk || "Medium";
    return {
      primaryLabel: "Volatility score",
      primaryValue: score(result.volatility_score, 50),
      risk,
      tone: toneFromRisk(risk),
      confidence: "Medium",
      recommendation: result.recommendation || "Stage conversion and review the position within 48 hours.",
      signals: [
        `Trend is ${result.trend || "under review"}.`,
        `${result.source?.currency || "Selected currency"} exposure of ${formatAmount(result.source?.exposure)} is being evaluated against ${result.source?.rate_observations || 0} recent rate observations.`,
        result.note || "Recommendation is for operational planning only.",
      ],
      actions: ["Review open invoices in volatile currencies.", "Avoid converting the full balance in one step.", "Re-run analysis after major rate movement."],
    };
  }

  if (mode === "fraud") {
    const anomaly = Number(result.anomaly_score ?? 0);
    const risk = anomaly >= 70 ? "High" : anomaly >= 40 ? "Medium" : "Low";
    return {
      primaryLabel: "Anomaly score",
      primaryValue: `${anomaly}/100`,
      risk,
      tone: toneFromRisk(risk),
      confidence: "Model-assisted",
      recommendation: anomaly >= 70 ? "Hold for manual verification before settlement." : "Continue monitoring and verify supporting details if needed.",
      signals: [
        ...(result.reasons || ["No unusual payment signals were returned."]),
        result.source?.counterparty ? `Highest-scoring transaction was with ${result.source.counterparty}.` : null,
        result.source?.transactions_analyzed ? `${result.source.transactions_analyzed} recent account transactions were analyzed; the average score was ${result.average_score}/100.` : null,
      ].filter(Boolean),
      actions: ["Verify payer identity.", "Compare amount against invoice tolerance.", "Escalate if timing, country, or payer history looks unusual."],
    };
  }

  if (mode === "cash") {
    const days = Number(result.projected_days ?? 0);
    const risk = result.risk || (days < 35 ? "High" : days < 75 ? "Medium" : "Low");
    return {
      primaryLabel: "Projected runway",
      primaryValue: `${days} days`,
      risk,
      tone: toneFromRisk(risk),
      confidence: "Forecast",
      recommendation: days < 60 ? "Accelerate high-value receivables and pause discretionary spend." : "Runway is acceptable; continue monitoring invoice delays.",
      signals: [
        `Forecast method: ${result.method || "cash-flow model"}.`,
        `${result.source?.incoming_transactions || 0} incoming and ${result.source?.outgoing_transactions || 0} outgoing transactions were included.`,
        `${result.source?.pending_invoices || 0} pending invoices were included.`,
      ],
      actions: ["Follow up on overdue invoices.", "Review large upcoming expenses.", "Re-run after the next payment sync."],
    };
  }

  const complianceRisk = result.status === "pass" ? "Low" : result.status === "review" ? "Medium" : "High";
  return {
    primaryLabel: "Compliance score",
    primaryValue: `${score(result.score, 0)}/100`,
    risk: complianceRisk,
    tone: toneFromRisk(complianceRisk),
    confidence: "Rule-assisted",
    recommendation: result.status === "pass" ? "No material compliance gaps detected." : "Resolve required review items before final settlement.",
    signals: [
      ...(result.recommendations || ["No material compliance gaps detected."]),
      result.source?.counterparty ? `Reviewed the account transaction with ${result.source.counterparty}.` : null,
    ].filter(Boolean),
    actions: ["Attach missing compliance documents.", "Confirm payer identity and invoice match.", "Escalate blocked or high-risk items."],
  };
}

function score(value, fallback) {
  return value ?? fallback;
}

function formatAmount(value) {
  if (value == null) return "from this account";
  return new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 }).format(value);
}

function toneFromRisk(risk) {
  const normalized = String(risk).toLowerCase();
  if (normalized.includes("high") || normalized.includes("blocked")) return "high";
  if (normalized.includes("medium") || normalized.includes("review")) return "medium";
  return "low";
}

function InsightCard({ label, value, tone }) {
  const styles = {
    high: "border-coral/30 bg-coral/10 text-coral",
    medium: "border-amber-200 bg-amber-50 text-amber-700",
    low: "border-mint/30 bg-mint/10 text-mint",
    neutral: "border-slate-200 bg-panel text-ink",
  };
  return (
    <div className={`rounded-md border p-4 ${styles[tone] || styles.neutral}`}>
      <div className="text-xs uppercase tracking-wide opacity-75">{label}</div>
      <div className="mt-2 text-xl font-semibold">{value}</div>
    </div>
  );
}

function Panel({ title, icon: Icon, items }) {
  return (
    <div className="rounded-md border border-slate-200 p-4">
      <div className="flex items-center gap-2 text-sm font-semibold"><Icon size={17} className="text-steel" /> {title}</div>
      <div className="mt-3 space-y-2">
        {items.map((item, index) => (
          <div key={index} className="flex gap-2 text-sm text-steel">
            <CheckCircle2 size={15} className="mt-0.5 shrink-0 text-mint" />
            <span>{item}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
