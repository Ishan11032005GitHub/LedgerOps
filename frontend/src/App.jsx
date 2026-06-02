import { Navigate, Route, Routes } from "react-router-dom";
import Layout from "./components/Layout.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import DataPage from "./pages/DataPage.jsx";
import IntelligencePage from "./pages/IntelligencePage.jsx";
import Login from "./pages/Login.jsx";
import PasswordRecovery from "./pages/PasswordRecovery.jsx";
import Copilot from "./pages/Copilot.jsx";
import PaymentApp from "./pages/PaymentApp.jsx";
import Settings from "./pages/Settings.jsx";

function Protected({ children }) {
  return localStorage.getItem("ig_access_token") ? children : <Navigate to="/login" replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Login mode="signup" />} />
      <Route path="/forgot-password" element={<PasswordRecovery />} />
      <Route path="/reset-password" element={<PasswordRecovery mode="reset" />} />
      <Route path="/index.html" element={<Navigate to="/" replace />} />
      <Route element={<Protected><Layout /></Protected>}>
        <Route index element={<Dashboard />} />
        <Route path="/payments" element={<DataPage type="payments" />} />
        <Route path="/payment-app" element={<PaymentApp />} />
        <Route path="/invoices" element={<DataPage type="invoices" />} />
        <Route path="/customers" element={<DataPage type="customers" />} />
        <Route path="/fx" element={<IntelligencePage mode="fx" />} />
        <Route path="/fraud" element={<IntelligencePage mode="fraud" />} />
        <Route path="/cash" element={<IntelligencePage mode="cash" />} />
        <Route path="/compliance" element={<IntelligencePage mode="compliance" />} />
        <Route path="/copilot" element={<Copilot />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/settings/recovery" element={<PasswordRecovery insideAccount />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
