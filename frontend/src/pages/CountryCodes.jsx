import { useMemo, useState } from "react";
import { Flag, Search } from "lucide-react";
import { Card } from "../components/Card.jsx";
import { countryCodes } from "../lib/countryCodes.js";
import { buildTrie, filterRows, trieSuggestions } from "../lib/trie.js";

const columns = ["country", "alpha2", "alpha3"];

export default function CountryCodes() {
  const [query, setQuery] = useState("");
  const [focused, setFocused] = useState(false);
  const trie = useMemo(() => buildTrie(countryCodes, columns), []);
  const visibleCountries = useMemo(() => filterRows(countryCodes, columns, query), [query]);
  const suggestions = useMemo(() => trieSuggestions(trie, query), [trie, query]);

  return (
    <div className="space-y-5">
      <section className="flex items-center gap-4 rounded-lg border border-slate-200 bg-white p-5 shadow-soft">
        <div className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-mint/10 text-mint"><Flag size={24} /></div>
        <div>
          <h2 className="text-xl font-semibold">Country code directory</h2>
          <p className="mt-1 text-sm text-steel">Decode ISO country names and their two-letter and three-letter codes.</p>
        </div>
      </section>

      <Card title="Countries">
        <div className="relative mt-4 max-w-xl">
          <label className="flex items-center gap-2 rounded-md border border-slate-300 bg-white px-3 py-2.5 focus-within:border-mint">
            <Search size={17} className="shrink-0 text-steel" />
            <input
              value={query}
              onBlur={() => window.setTimeout(() => setFocused(false), 120)}
              onChange={(event) => setQuery(event.target.value)}
              onFocus={() => setFocused(true)}
              placeholder="Search by country, two-letter code, or three-letter code"
              className="min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:text-slate-400"
            />
          </label>
          {focused && query.trim() && suggestions.length > 0 && (
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
                  <span>{suggestion.value}</span>
                  <span className="text-xs uppercase text-steel">{suggestion.column === "country" ? "country" : suggestion.column}</span>
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="mt-4 overflow-auto">
          <table className="min-w-full text-left text-sm">
            <thead>
              <tr>
                <th className="border-b border-slate-200 px-3 py-2 font-medium text-steel">COUNTRY</th>
                <th className="border-b border-slate-200 px-3 py-2 font-medium text-steel">2 LETTER CODE</th>
                <th className="border-b border-slate-200 px-3 py-2 font-medium text-steel">3 LETTER CODE</th>
              </tr>
            </thead>
            <tbody>
              {visibleCountries.map((item) => (
                <tr key={item.alpha2} className="hover:bg-panel">
                  <td className="border-b border-slate-100 px-3 py-2.5 font-medium">{item.country}</td>
                  <td className="border-b border-slate-100 px-3 py-2.5">{item.alpha2}</td>
                  <td className="border-b border-slate-100 px-3 py-2.5">{item.alpha3}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {!visibleCountries.length && (
            <div className="rounded-b-md border border-t-0 border-dashed border-slate-300 px-4 py-8 text-center text-sm text-steel">
              No country or code matches “{query}”.
            </div>
          )}
        </div>
        <div className="mt-3 text-xs text-steel">{visibleCountries.length} of {countryCodes.length} countries shown</div>
      </Card>
    </div>
  );
}
