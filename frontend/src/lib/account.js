export function readStoredUser() {
  try {
    return JSON.parse(localStorage.getItem("ig_user") || "{}");
  } catch {
    localStorage.removeItem("ig_user");
    return {};
  }
}

function titleCase(value) {
  return String(value || "")
    .replace(/[-_]/g, " ")
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

export function workspaceName(user = readStoredUser()) {
  if (user.workspace_name) return user.workspace_name;
  if (user.workspace) return user.workspace;
  if (user.company) return user.company;

  const domain = String(user.email || "").split("@")[1] || "";
  const root = domain.split(".")[0] || "account";
  if (root.toLowerCase() === "ledgerops") return "LedgerOps workspace";
  return `${titleCase(root)} workspace`;
}

export function accountCommandTitle(user = readStoredUser()) {
  return user.name ? `${user.name}'s finance command center` : "Your finance command center";
}

export function accountSubtitle(user = readStoredUser()) {
  const parts = [workspaceName(user), user.email, user.role].filter(Boolean);
  return parts.join(" | ");
}

export function walletHandle(user = readStoredUser()) {
  const emailName = String(user.email || "").split("@")[0];
  const handle = emailName || String(user.name || "account").toLowerCase();
  return `${handle.replace(/[^a-z0-9._-]/gi, "").toLowerCase() || "account"}@pay`;
}

export function accountStorageKey(user = readStoredUser()) {
  return String(user.email || user.id || "guest").trim().toLowerCase();
}

export function isSeededDemoAccount(user = readStoredUser()) {
  return accountStorageKey(user) === "admin@ledgerops.ai";
}
