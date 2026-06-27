import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ArrowRight, RefreshCw, ShieldCheck } from "lucide-react";
import { api, login, signup } from "../lib/api.js";

export default function Login({ mode = "login" }) {
  const isSignup = mode === "signup";
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [otp, setOtp] = useState("");
  const [needsMfa, setNeedsMfa] = useState(false);
  const [role, setRole] = useState("Finance Manager");
  const [accountType, setAccountType] = useState("company");
  const [workspaceName, setWorkspaceName] = useState("");
  const [error, setError] = useState("");
  const [demoLoading, setDemoLoading] = useState("");
  const [demoResetting, setDemoResetting] = useState(false);
  const [demoMessage, setDemoMessage] = useState("");
  const [demoAccounts, setDemoAccounts] = useState([]);
  const navigate = useNavigate();

  async function loadDemoAccounts() {
    const accounts = await api("/api/payment-app/demo/public-accounts");
    setDemoAccounts(accounts);
    return accounts;
  }

  useEffect(() => {
    if (!isSignup) loadDemoAccounts().catch(() => setDemoAccounts([]));
  }, [isSignup]);

  function demoAccount(email, fallbackName) {
    return demoAccounts.find((account) => account.email === email) || {
      email,
      name: fallbackName,
      balance: null,
      currency: "INR",
    };
  }

  function balanceLabel(account) {
    if (account.balance == null) return "Loading current balance...";
    try {
      return `${new Intl.NumberFormat("en-IN", {
        style: "currency",
        currency: account.currency || "INR",
        maximumFractionDigits: 2,
      }).format(account.balance)} current balance`;
    } catch {
      return `${account.currency || "INR"} ${Number(account.balance).toLocaleString("en-IN")} current balance`;
    }
  }

  async function submit(e) {
    e.preventDefault();
    setError("");
    try {
      if (isSignup) await signup({ name, email, password, role, account_type: accountType, workspace_name: accountType === "company" ? workspaceName : "" });
      else await login(email, password, otp);
      navigate("/");
    } catch (err) {
      setError(err.message);
      if (err.message.toLowerCase().includes("mfa")) setNeedsMfa(true);
    }
  }
  async function chooseDemo(demoEmail) {
    setEmail(demoEmail);
    setPassword("DemoPass123");
    setError("");
    setDemoLoading(demoEmail);
    try {
      await login(demoEmail, "DemoPass123");
      navigate("/");
    } catch (err) {
      setError(err.message);
    } finally {
      setDemoLoading("");
    }
  }
  async function resetDemo() {
    setError("");
    setDemoMessage("");
    setDemoResetting(true);
    try {
      await api("/api/payment-app/demo/public-reset", { method: "POST" });
      const accounts = await loadDemoAccounts();
      const summary = accounts.map((account) => `${account.name}: ${balanceLabel(account).replace(" current balance", "")}`).join(" | ");
      setDemoMessage(`Demo restored. ${summary}`);
    } catch (err) {
      setError(err.message);
    } finally {
      setDemoResetting(false);
    }
  }
  const asha = demoAccount("asha.demo@ledgerops.ai", "Asha Mehta");
  const rohan = demoAccount("rohan.demo@ledgerops.ai", "Rohan Kapoor");
  return (
    <main className="grid min-h-screen place-items-center bg-ink px-4 py-8">
      <form onSubmit={submit} className="w-full max-w-xl rounded-lg border border-white/10 bg-white p-7 shadow-soft">
        <div className="mb-6 flex items-center gap-3">
          <div className="grid h-11 w-11 place-items-center rounded-md bg-mint/10 text-mint"><ShieldCheck /></div>
          <div>
            <h1 className="text-2xl font-semibold">{isSignup ? "Create your LedgerOps workspace" : "Welcome back"}</h1>
            <p className="text-sm text-steel">Connect your payment app, detect risky receivables, and operate finance from one command center.</p>
          </div>
        </div>
        {isSignup && (
          <>
            <div className="mb-4 grid gap-2 sm:grid-cols-2">
              <button type="button" onClick={() => setAccountType("company")} className={`rounded-md border px-3 py-3 text-left ${accountType === "company" ? "border-mint bg-mint/5" : "border-slate-200 hover:bg-panel"}`}>
                <span className="block text-sm font-semibold">Company account</span>
                <span className="mt-1 block text-xs text-steel">Workspace with multiple users and roles.</span>
              </button>
              <button type="button" onClick={() => setAccountType("individual")} className={`rounded-md border px-3 py-3 text-left ${accountType === "individual" ? "border-mint bg-mint/5" : "border-slate-200 hover:bg-panel"}`}>
                <span className="block text-sm font-semibold">Individual account</span>
                <span className="mt-1 block text-xs text-steel">Personal payments and daily-use finance.</span>
              </button>
            </div>
            {accountType === "company" && (
              <>
                <label className="text-sm font-medium">Company / workspace name</label>
                <input value={workspaceName} onChange={(e) => setWorkspaceName(e.target.value)} placeholder="Ex. Acme Finance Workspace" className="mt-1 mb-4 w-full rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint" />
              </>
            )}
            <label className="text-sm font-medium">Full name</label>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Ex. Avery Shah" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint" />
            {accountType === "company" && (
              <>
                <label className="mt-4 block text-sm font-medium">Role</label>
                <select value={role} onChange={(e) => setRole(e.target.value)} className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint">
                  <option>Admin</option>
                  <option>Finance Manager</option>
                  <option>Viewer</option>
                </select>
              </>
            )}
          </>
        )}
        <label className={`${isSignup ? "mt-4 block" : ""} text-sm font-medium`}>Email</label>
        <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder={isSignup ? "Ex. founder@company.com" : "Ex. admin@ledgerops.ai"} className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint" />
        <div className="mt-4 flex items-center justify-between gap-3">
          <label className="text-sm font-medium">Password</label>
          {!isSignup && <Link to="/forgot-password" className="text-sm font-medium text-mint hover:text-emerald-700">Forgot password?</Link>}
        </div>
        <input required minLength={isSignup ? 10 : 1} type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder={isSignup ? "Create a strong password" : "Enter your password"} className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint" />
        {!isSignup && needsMfa && (
          <label className="mt-4 block text-sm font-medium">Authenticator code
            <input autoFocus required inputMode="numeric" pattern="\d{6}" maxLength={6} value={otp} onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))} placeholder="000000" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 outline-none focus:border-mint" />
          </label>
        )}
        {error && <div className="mt-3 rounded-md bg-coral/10 p-3 text-sm text-coral">{error}</div>}
        <button className="mt-5 flex w-full items-center justify-center gap-2 rounded-md bg-mint px-4 py-2.5 font-medium text-white hover:bg-emerald-700">
          {isSignup ? "Create account" : "Sign in"} <ArrowRight size={17} />
        </button>
        {!isSignup && (
          <div className="mt-5 rounded-md border border-slate-200 bg-panel p-4">
            <div className="text-xs font-medium uppercase tracking-wide text-steel">Two-account money-flow demo</div>
            <div className="mt-3 grid gap-2 sm:grid-cols-2">
              <button disabled={Boolean(demoLoading)} type="button" onClick={() => chooseDemo("asha.demo@ledgerops.ai")} className="rounded-md border border-slate-300 bg-white px-3 py-2 text-left hover:border-mint disabled:opacity-60">
                <span className="block text-sm font-semibold">{demoLoading === "asha.demo@ledgerops.ai" ? "Opening..." : "Enter as Asha Mehta"}</span>
                <span className="block text-xs text-steel">{balanceLabel(asha)}</span>
              </button>
              <button disabled={Boolean(demoLoading)} type="button" onClick={() => chooseDemo("rohan.demo@ledgerops.ai")} className="rounded-md border border-slate-300 bg-white px-3 py-2 text-left hover:border-mint disabled:opacity-60">
                <span className="block text-sm font-semibold">{demoLoading === "rohan.demo@ledgerops.ai" ? "Opening..." : "Enter as Rohan Kapoor"}</span>
                <span className="block text-xs text-steel">{balanceLabel(rohan)}</span>
              </button>
            </div>
            <div className="mt-2 text-xs text-steel">Choose an account to sign in immediately. Use another browser or incognito window for the second account.</div>
            <div className="mt-3 rounded-md border border-slate-200 bg-white p-3">
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <div className="text-sm font-semibold">Start fresh</div>
                  <div className="text-xs text-steel">Reset balances, demo payments, requests, and chat before signing in.</div>
                </div>
                <button disabled={demoResetting || Boolean(demoLoading)} type="button" onClick={resetDemo} className="inline-flex items-center justify-center gap-2 rounded-md border border-slate-300 px-3 py-2 text-sm font-medium hover:bg-panel disabled:opacity-60">
                  <RefreshCw size={15} /> {demoResetting ? "Resetting..." : "Reset demo"}
                </button>
              </div>
              {demoMessage && <div className="mt-2 rounded-md bg-emerald-50 px-3 py-2 text-xs font-medium text-emerald-700">{demoMessage}</div>}
            </div>
          </div>
        )}
        <div className="mt-4 grid gap-2 sm:grid-cols-[1fr_auto] sm:items-center">
          <div className="text-sm text-steel">{isSignup ? "Already have an account?" : "New to LedgerOps?"}</div>
          <Link className="inline-flex items-center justify-center rounded-md border border-slate-300 px-4 py-2 text-sm font-medium text-ink hover:bg-panel" to={isSignup ? "/login" : "/signup"}>
            {isSignup ? "Go to sign in" : "Create account"}
          </Link>
        </div>
        {!isSignup && <div className="mt-4 text-xs text-steel">Open the second account in an incognito window or another browser to test both sides.</div>}
      </form>
    </main>
  );
}
