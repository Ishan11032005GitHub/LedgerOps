import { useMemo, useState } from "react";
import { ArrowRight, KeyRound, Mail, ShieldCheck } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../lib/api.js";

export default function PasswordRecovery({ mode = "request", insideAccount = false }) {
  const isReset = mode === "reset";
  const navigate = useNavigate();
  const token = useMemo(() => new URLSearchParams(window.location.search).get("token") || "", []);
  const [email, setEmail] = useState("admin@ledgerops.ai");
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [result, setResult] = useState(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setError("");
    setBusy(true);
    try {
      if (isReset) {
        if (!token) throw new Error("This reset link is missing a recovery token.");
        if (password !== confirmation) throw new Error("New passwords do not match.");
        const response = await api("/api/auth/reset-password", {
          method: "POST",
          body: JSON.stringify({ token, new_password: password }),
        });
        setResult(response);
      } else {
        const response = await api("/api/auth/forgot-password", {
          method: "POST",
          body: JSON.stringify({ email }),
        });
        setResult(response);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  const recoveryCard = (
      <section className={`w-full max-w-lg rounded-lg border bg-white p-7 shadow-soft ${insideAccount ? "border-slate-200" : "border-white/10"}`}>
        <div className="mb-6 flex items-center gap-3">
          <div className="grid h-11 w-11 place-items-center rounded-md bg-mint/10 text-mint">{isReset ? <KeyRound /> : <ShieldCheck />}</div>
          <div>
            <h1 className="text-2xl font-semibold">{isReset ? "Set a new password" : "Recover your account"}</h1>
            <p className="text-sm text-steel">{isReset ? "Choose a new password for your LedgerOps account." : "Enter your email to receive a password reset link."}</p>
          </div>
        </div>

        {!result?.status && (
          <form onSubmit={submit}>
            {isReset ? (
              <>
                <label className="block text-sm font-medium">New password</label>
                <input required minLength={8} type="password" value={password} onChange={(event) => setPassword(event.target.value)} className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
                <label className="mt-4 block text-sm font-medium">Confirm new password</label>
                <input required minLength={8} type="password" value={confirmation} onChange={(event) => setConfirmation(event.target.value)} className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
              </>
            ) : (
              <>
                <label className="block text-sm font-medium">Account email</label>
                <div className="mt-1 flex items-center rounded-md border border-slate-300 px-3 focus-within:border-mint">
                  <Mail size={17} className="text-steel" />
                  <input required type="email" value={email} onChange={(event) => setEmail(event.target.value)} className="w-full px-3 py-2.5 outline-none" />
                </div>
              </>
            )}
            {error && <div className="mt-4 rounded-md bg-coral/10 p-3 text-sm text-coral">{error}</div>}
            <button disabled={busy} className="mt-5 flex w-full items-center justify-center gap-2 rounded-md bg-mint px-4 py-2.5 font-medium text-white hover:bg-emerald-700 disabled:opacity-60">
              {busy ? "Working..." : isReset ? "Reset password" : "Send reset link"} <ArrowRight size={17} />
            </button>
          </form>
        )}

        {!isReset && result && (
          <div className="rounded-md bg-emerald-50 p-4 text-sm text-emerald-800">
            <div>{result.message}</div>
            {result.reset_url && (
              <div className="mt-4">
                <div className="mb-2 text-xs font-medium uppercase text-steel">Local testing only</div>
                <a href={result.reset_url} className="inline-flex rounded-md bg-ink px-4 py-2 font-medium text-white">Open password reset</a>
              </div>
            )}
          </div>
        )}

        {isReset && result?.status === "updated" && (
          <div className="rounded-md bg-emerald-50 p-4 text-sm text-emerald-800">
            <div>{result.message}</div>
            <button type="button" onClick={() => navigate("/login")} className="mt-4 rounded-md bg-ink px-4 py-2 font-medium text-white">Return to sign in</button>
          </div>
        )}

        <div className="mt-5 border-t border-slate-100 pt-4 text-sm">
          <Link to={insideAccount ? "/settings" : "/login"} className="font-medium text-steel hover:text-ink">{insideAccount ? "Back to security settings" : "Back to sign in"}</Link>
        </div>
      </section>
  );

  if (insideAccount) {
    return (
      <div className="space-y-5">
        <div>
          <h2 className="text-xl font-semibold">Password recovery</h2>
          <p className="mt-1 text-sm text-steel">Request a reset link without signing out of your account.</p>
        </div>
        {recoveryCard}
      </div>
    );
  }

  return (
    <main className="grid min-h-screen place-items-center bg-ink px-4 py-8">
      {recoveryCard}
    </main>
  );
}
