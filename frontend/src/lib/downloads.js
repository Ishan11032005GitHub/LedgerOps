function downloadBlob(filename, content, type) {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

function normalizeValue(value) {
  if (value == null) return "";
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

export function toCsv(rows, columns) {
  const fields = columns || Array.from(rows.reduce((set, row) => {
    Object.keys(row || {}).forEach((key) => set.add(key));
    return set;
  }, new Set()));
  const escape = (value) => `"${normalizeValue(value).replaceAll('"', '""')}"`;
  return [fields.join(","), ...rows.map((row) => fields.map((field) => escape(row?.[field])).join(","))].join("\n");
}

export function downloadCsv(filename, rows, columns) {
  downloadBlob(filename, toCsv(rows, columns), "text/csv;charset=utf-8");
}

export function downloadJson(filename, data) {
  downloadBlob(filename, JSON.stringify(data, null, 2), "application/json;charset=utf-8");
}

export function downloadSvg(filename, container) {
  const svg = container?.querySelector("svg");
  if (!svg) return false;
  const clone = svg.cloneNode(true);
  clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
  const xml = new XMLSerializer().serializeToString(clone);
  downloadBlob(filename, xml, "image/svg+xml;charset=utf-8");
  return true;
}
