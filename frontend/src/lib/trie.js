const MAX_SUGGESTIONS = 8;

function createNode() {
  return { children: new Map(), suggestions: [] };
}

function addSuggestion(node, suggestion) {
  if (!node.suggestions.some((item) => item.value === suggestion.value && item.column === suggestion.column)) {
    node.suggestions.push(suggestion);
    node.suggestions.sort((a, b) => a.value.localeCompare(b.value));
    if (node.suggestions.length > MAX_SUGGESTIONS) node.suggestions.length = MAX_SUGGESTIONS;
  }
}

function insert(root, text, suggestion) {
  const normalized = String(text || "").trim().toLowerCase();
  if (!normalized) return;
  let node = root;
  addSuggestion(node, suggestion);
  for (const character of normalized) {
    if (!node.children.has(character)) node.children.set(character, createNode());
    node = node.children.get(character);
    addSuggestion(node, suggestion);
  }
}

export function buildTrie(rows, columns) {
  const root = createNode();
  rows.forEach((row) => {
    columns.forEach((column) => {
      const value = String(row[column] ?? "").trim();
      if (!value) return;
      const suggestion = { value, column };
      insert(root, value, suggestion);
      value.split(/[\s|/_-]+/).forEach((token) => insert(root, token, suggestion));
    });
  });
  return root;
}

export function trieSuggestions(root, query) {
  const normalized = query.trim().toLowerCase();
  if (!normalized) return [];
  let node = root;
  for (const character of normalized) {
    node = node.children.get(character);
    if (!node) return [];
  }
  return node.suggestions;
}

export function filterRows(rows, columns, query) {
  const normalized = query.trim().toLowerCase();
  if (!normalized) return rows;
  return rows.filter((row) => columns.some((column) => String(row[column] ?? "").toLowerCase().includes(normalized)));
}
