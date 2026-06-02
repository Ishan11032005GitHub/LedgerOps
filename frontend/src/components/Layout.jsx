import { useEffect, useState } from "react";
import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { Bot, CircleDollarSign, Gauge, LineChart, LogOut, PlugZap, Receipt, SearchCheck, Settings, ShieldAlert, Users, WalletCards } from "lucide-react";
import { prefetchDashboard } from "../pages/Dashboard.jsx";
import { prefetchDataPage } from "../pages/DataPage.jsx";

const nav = [
  ["Dashboard", "/", Gauge, prefetchDashboard],
  ["Payments", "/payments", CircleDollarSign, () => prefetchDataPage("payments")],
  ["Payment App", "/payment-app", PlugZap],
  ["Invoices", "/invoices", Receipt, () => prefetchDataPage("invoices")],
  ["Customers", "/customers", Users, () => prefetchDataPage("customers")],
  ["FX Intelligence", "/fx", LineChart],
  ["Fraud Detection", "/fraud", ShieldAlert],
  ["Cash Forecast", "/cash", WalletCards],
  ["Compliance", "/compliance", SearchCheck],
  ["AI Copilot", "/copilot", Bot],
  ["Settings", "/settings", Settings],
];

function readUser() {
  try {
    return JSON.parse(localStorage.getItem("ig_user") || "{}");
  } catch {
    localStorage.removeItem("ig_user");
    return {};
  }
}

export default function Layout() {
  const navigate = useNavigate();
  const location = useLocation();
  const [user, setUser] = useState(readUser);

  useEffect(() => {
    function handleUserUpdated(event) {
      setUser(event.detail || readUser());
    }
    window.addEventListener("ig-user-updated", handleUserUpdated);
    return () => window.removeEventListener("ig-user-updated", handleUserUpdated);
  }, []);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "auto" });
  }, [location.pathname]);

  function logout() {
    localStorage.clear();
    navigate("/login");
  }
  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[280px_1fr]">
      <aside className="bg-ink text-white p-5 lg:min-h-screen">
        <div className="mb-8">
          <div className="text-2xl font-semibold">InfinityGuard AI</div>
          <div className="text-sm text-white/60 mt-1">Payments risk operating system</div>
        </div>
        <nav className="grid gap-1">
          {nav.map(([label, path, Icon, prefetch]) => (
            <NavLink key={path} to={path} end={path === "/"} onPointerEnter={() => prefetch?.().catch(() => {})} onFocus={() => prefetch?.().catch(() => {})} className={({ isActive }) => `relative flex items-center gap-3 rounded-md px-3 py-2.5 text-sm transition-colors duration-150 ${isActive ? "bg-white text-ink shadow-soft" : "text-white/75 hover:bg-white/[0.07] hover:text-white"}`}>
              {({ isActive }) => (
                <>
                  {isActive && <motion.span layoutId="activeNav" className="absolute left-0 h-6 w-1 rounded-r bg-mint" transition={{ type: "spring", stiffness: 400, damping: 35 }} />}
                  <Icon size={18} />
                  {label}
                </>
              )}
            </NavLink>
          ))}
        </nav>
      </aside>
      <main className="min-w-0">
        <header className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-200 bg-white/95 px-5 py-4 backdrop-blur">
          <div>
            <div className="text-sm text-steel">Connected payments, cash, FX, fraud, and compliance intelligence</div>
            <h1 className="text-xl font-semibold">Finance command center</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="hidden text-right sm:block">
              <div className="text-sm font-medium">{user.name || "Guest"}</div>
              <div className="text-xs text-steel">{user.role || "Viewer"}</div>
            </div>
            <button title="Log out" onClick={logout} className="grid h-10 w-10 place-items-center rounded-md border border-slate-200 bg-white text-steel hover:text-coral">
              <LogOut size={18} />
            </button>
          </div>
        </header>
        <AnimatePresence mode="sync" initial={false}>
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, y: 5 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -3 }}
            transition={{ duration: 0.14, ease: "easeOut" }}
            className="p-5 lg:p-8"
          >
            <Outlet />
          </motion.div>
        </AnimatePresence>
      </main>
    </div>
  );
}
