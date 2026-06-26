import { useEffect, useState } from "react";
import { Download, Search } from "lucide-react";
import { Card, Skeleton } from "../components/Card.jsx";
import { api } from "../lib/api.js";
import { accountStorageKey, readStoredUser } from "../lib/account.js";
import { downloadCsv, downloadJson } from "../lib/downloads.js";
import { buildTrie, filterRows, trieSuggestions } from "../lib/trie.js";

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
  const [query, setQuery] = useState("");
  const [focused, setFocused] = useState(false);
  const [error, setError] = useState("");
  useEffect(() => {
    const key = `${accountStorageKey()}:${type}`;
    setRows(pageCache[key] || null);
    setQuery("");
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
  const entityLabel = type === "customers" ? "clients" : type.replace("-", " ");
  const title = entityLabel.toUpperCase();
  const searchable = type === "payments" || type === "invoices";
  const normalizedQuery = query.trim().toLowerCase();
  const visibleRows = filterRows(rows, columns, query);
  const trie = searchable ? buildTrie(rows, columns) : null;
  const suggestions = searchable ? trieSuggestions(trie, query) : [];
  return (
    <Card title={title} actions={
      <>
        <button onClick={() => downloadCsv(`${type}.csv`, visibleRows, columns)} className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel"><Download size={13} /> CSV</button>
        <button onClick={() => downloadJson(`${type}.json`, visibleRows.map((row) => Object.fromEntries(columns.map((column) => [column, row[column] ?? null]))))} className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-panel"><Download size={13} /> JSON</button>
      </>
    }>
      {searchable && (
        <div className="relative mt-4 max-w-xl">
          <label className="flex items-center gap-2 rounded-md border border-slate-300 bg-white px-3 py-2.5 text-sm focus-within:border-emerald-500">
            <Search size={17} className="shrink-0 text-steel" />
            <input
              value={query}
              onBlur={() => window.setTimeout(() => setFocused(false), 120)}
              onChange={(event) => setQuery(event.target.value)}
              onFocus={() => setFocused(true)}
              placeholder={type === "payments" ? "Search payments by recipient, amount, status, rail, country, or reference" : "Search invoices by invoice number, amount, currency, status, or date"}
              className="min-w-0 flex-1 bg-transparent outline-none placeholder:text-slate-400"
            />
          </label>
          {focused && normalizedQuery && suggestions.length > 0 && (
            <div className="absolute left-0 right-0 top-full z-20 mt-2 overflow-hidden rounded-md border border-slate-200 bg-white shadow-soft">
              {suggestions.map((suggestion) => (
                <button
                  key={`${suggestion.column}:${suggestion.value}`}
                  type="button"
                  onClick={() => {
                    setQuery(suggestion.value);
                    setFocused(false);
                  }}
                  className="flex w-full items-center justify-between gap-3 px-3 py-2 text-left text-sm hover:bg-panel"
                >
                  <span className="truncate">{suggestion.value}</span>
                  <span className="shrink-0 text-xs uppercase tracking-normal text-steel">{suggestion.column}</span>
                </button>
              ))}
            </div>
          )}
        </div>
      )}
      <div className="mt-4 overflow-auto scrollbar-thin">
        {visibleRows.length ? (
          <table className="min-w-full text-left text-sm">
            <thead><tr>{columns.map((c) => <th key={c} className="border-b border-slate-200 px-3 py-2 font-medium text-steel">{c}</th>)}</tr></thead>
            <tbody>{visibleRows.map((row, i) => <tr key={row.id || i} className="hover:bg-panel">{columns.map((c) => <td key={c} className="border-b border-slate-100 px-3 py-2">{String(row[c] ?? "")}</td>)}</tr>)}</tbody>
          </table>
        ) : (
          <div className="rounded-md border border-dashed border-slate-300 px-4 py-8 text-center text-sm text-steel">
            {normalizedQuery ? `No ${entityLabel} match "${query}".` : `No ${entityLabel} available yet.`}
          </div>
        )}
      </div>
    </Card>
  );
}
