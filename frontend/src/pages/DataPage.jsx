import { useEffect, useState } from "react";
import { Download } from "lucide-react";
import { Card, Skeleton } from "../components/Card.jsx";
import { api } from "../lib/api.js";
import { accountStorageKey, readStoredUser } from "../lib/account.js";
import { downloadCsv, downloadJson } from "../lib/downloads.js";

const pageCache = {};
const pageRequests = {};

export function prefetchDataPage(type) {
  const key = `${accountStorageKey()}:${type}`;
  if (pageCache[key]) return Promise.resolve(pageCache[key]);
  if (!pageRequests[key]) {
    pageRequests[key] = api(`/api/${type}`)
      .then((result) => {
        pageCache[key] = result;
        return result;
      })
      .finally(() => {
        delete pageRequests[key];
      });
  }
  return pageRequests[key];
}

export default function DataPage({ type }) {
  const user = readStoredUser();
  const cacheKey = `${accountStorageKey()}:${type}`;
  const [rows, setRows] = useState(pageCache[cacheKey] || null);
  const [error, setError] = useState("");
  useEffect(() => {
    const key = `${accountStorageKey()}:${type}`;
    setRows(pageCache[key] || null);
    setError("");
    prefetchDataPage(type).then((result) => {
      setRows(result);
    }).catch((err) => {
      if (!pageCache[key]) setError(err.message);
    });
  }, [type, cacheKey]);
  if (error) return <Card title={`${type.toUpperCase()} unavailable`} helper={error} />;
  if (!rows) return <Skeleton />;
  const preferred = type === "payments" ? ["id", "recipient", "amount", "currency", "status", "rail", "country", "external_ref"] : [];
  const restrictedByRole = user.role === "Viewer" ? new Set(["external_ref", "invoice_id", "customer_id", "metadata_json", "user_id"]) : new Set(["metadata_json", "user_id"]);
  const available = Object.keys(rows[0] || {}).filter((k) => !["hashed_password"].includes(k) && !restrictedByRole.has(k));
  const columns = [...preferred.filter((key) => available.includes(key)), ...available.filter((key) => !preferred.includes(key))].slice(0, 8);
  const title = type.replace("-", " ").toUpperCase();
  return (
    <Card title={title} actions={
      <>
        <button onClick={() => downloadCsv(`${type}.csv`, rows, columns)} className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel"><Download size={13} /> CSV</button>
        <button onClick={() => downloadJson(`${type}.json`, rows.map((row) => Object.fromEntries(columns.map((column) => [column, row[column] ?? null]))))} className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel"><Download size={13} /> JSON</button>
      </>
    }>
      <div className="mt-4 overflow-auto scrollbar-thin">
        <table className="min-w-full text-left text-sm">
          <thead><tr>{columns.map((c) => <th key={c} className="border-b border-slate-200 px-3 py-2 font-medium text-steel">{c}</th>)}</tr></thead>
          <tbody>{rows.map((row, i) => <tr key={row.id || i} className="hover:bg-panel">{columns.map((c) => <td key={c} className="border-b border-slate-100 px-3 py-2">{String(row[c] ?? "")}</td>)}</tr>)}</tbody>
        </table>
      </div>
    </Card>
  );
}
