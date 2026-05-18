import { useEffect, useState } from "react";
import { Card, Skeleton } from "../components/Card.jsx";
import { api } from "../lib/api.js";

export default function DataPage({ type }) {
  const [rows, setRows] = useState(null);
  useEffect(() => {
    if (type === "settings") setRows([
      { setting: "API mode", value: "Payment-app ready test mode" },
      { setting: "Primary payment provider", value: "Stripe-compatible connector" },
      { setting: "Webhook retries", value: "3 attempts" },
      { setting: "Deployment", value: "Docker, Render, Vercel ready" },
    ]);
    else api(`/api/${type}`).then(setRows);
  }, [type]);
  if (!rows) return <Skeleton />;
  const preferred = type === "payments" ? ["id", "recipient", "amount", "currency", "status", "rail", "country", "external_ref"] : [];
  const available = Object.keys(rows[0] || {}).filter((k) => !["hashed_password", "metadata_json"].includes(k));
  const columns = [...preferred.filter((key) => available.includes(key)), ...available.filter((key) => !preferred.includes(key))].slice(0, 8);
  return (
    <Card title={type.replace("-", " ").toUpperCase()}>
      <div className="mt-4 overflow-auto scrollbar-thin">
        <table className="min-w-full text-left text-sm">
          <thead><tr>{columns.map((c) => <th key={c} className="border-b border-slate-200 px-3 py-2 font-medium text-steel">{c}</th>)}</tr></thead>
          <tbody>{rows.map((row, i) => <tr key={row.id || i} className="hover:bg-panel">{columns.map((c) => <td key={c} className="border-b border-slate-100 px-3 py-2">{String(row[c] ?? "")}</td>)}</tr>)}</tbody>
        </table>
      </div>
    </Card>
  );
}
