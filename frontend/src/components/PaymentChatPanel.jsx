import { useEffect, useMemo, useState } from "react";
import { Bell, BellOff, Send } from "lucide-react";
import { api } from "../lib/api.js";

const contactColors = ["bg-mint", "bg-blue-600", "bg-coral", "bg-amber-500"];

function notificationLabel(permission) {
  if (permission === "granted") return "Notifications on";
  if (permission === "denied") return "Notifications blocked";
  if (permission === "unsupported") return "Unavailable";
  return "Enable alerts";
}

function notifyPaymentChat(title, body) {
  if (!("Notification" in window) || Notification.permission !== "granted") return false;
  new Notification(title, { body });
  return true;
}

export default function PaymentChatPanel({ onActivity }) {
  const [status, setStatus] = useState(null);
  const [contacts, setContacts] = useState([]);
  const [activeContact, setActiveContact] = useState(null);
  const [messages, setMessages] = useState([]);
  const [chatText, setChatText] = useState("");
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("Invoice settlement");
  const [loading, setLoading] = useState("");
  const [notice, setNotice] = useState("");
  const [permission, setPermission] = useState(() => ("Notification" in window ? Notification.permission : "unsupported"));

  const activeCurrency = status?.currency || activeContact?.currency || "INR";
  const activeBalance = status?.available_balance ?? null;
  const amountReady = Number(amount) > 0;

  async function loadContacts() {
    const [statusData, contactData] = await Promise.all([
      api("/api/payment-app/status"),
      api("/api/payment-app/demo/contacts"),
    ]);
    const coloredContacts = (contactData || []).map((contact, index) => ({
      ...contact,
      currency: statusData.currency || contact.currency || "INR",
      color: contactColors[index % contactColors.length],
    }));
    setStatus(statusData);
    setContacts(coloredContacts);
    setActiveContact((current) => coloredContacts.find((contact) => contact.id === current?.id) || coloredContacts[0] || null);
  }

  async function loadMessages(contact = activeContact, shouldNotify = false) {
    if (!contact?.id) return;
    const records = await api(`/api/payment-app/demo/messages/${contact.id}`);
    setMessages((previous) => {
      const latest = records.at(-1);
      const previousLatest = previous.at(-1);
      if (shouldNotify && previous.length && latest?.id !== previousLatest?.id && latest?.direction === "incoming") {
        const shown = notifyPaymentChat(`New message from ${contact.name}`, latest.text);
        setNotice(shown ? "Browser notification sent." : `New message from ${contact.name}`);
      }
      return records;
    });
  }

  useEffect(() => {
    loadContacts().catch((error) => setNotice(error.message));
  }, []);

  useEffect(() => {
    if (!activeContact?.id) return undefined;
    loadMessages(activeContact, false).catch((error) => setNotice(error.message));
    const timer = window.setInterval(() => {
      loadMessages(activeContact, true).catch(() => {});
    }, 2000);
    return () => window.clearInterval(timer);
  }, [activeContact?.id]);

  async function enableNotifications() {
    if (!("Notification" in window)) {
      setPermission("unsupported");
      return;
    }
    const nextPermission = await Notification.requestPermission();
    setPermission(nextPermission);
  }

  async function sendChatText(event) {
    event.preventDefault();
    const text = chatText.trim();
    if (!text || !activeContact?.id) return;
    setLoading("message");
    setNotice("");
    try {
      await api("/api/payment-app/demo/messages", {
        method: "POST",
        body: JSON.stringify({ recipient_id: activeContact.id, text }),
      });
      setChatText("");
      await loadMessages(activeContact, false);
    } catch (error) {
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  async function moneyAction(kind) {
    if (!activeContact?.id || !amountReady) return;
    setLoading(kind);
    setNotice("");
    try {
      const endpoint = kind === "pay" ? "/api/payment-app/pay" : "/api/payment-app/request";
      const value = Number(amount);
      const payload = kind === "pay"
        ? {
            recipient_name: activeContact.name,
            recipient_handle: activeContact.handle,
            amount: value,
            currency: activeCurrency,
            note,
            rail: "LedgerOps Demo",
            payment_method_id: null,
            idempotency_key: crypto.randomUUID(),
          }
        : {
            payer_name: activeContact.name,
            payer_handle: activeContact.handle,
            amount: value,
            currency: activeCurrency,
            note,
          };
      const result = await api(endpoint, { method: "POST", body: JSON.stringify(payload) });
      setAmount("");
      await Promise.all([loadContacts(), loadMessages(activeContact, false), onActivity?.()]);
      setNotice(kind === "pay" ? `Payment sent to ${result.recipient}.` : `Request sent to ${result.payer}.`);
    } catch (error) {
      setNotice(error.message);
    } finally {
      setLoading("");
    }
  }

  const shownMessages = useMemo(() => messages.slice(-80), [messages]);

  return (
    <div className="rounded-lg border border-slate-200 bg-white shadow-soft">
      <div className="border-b border-slate-200 p-5">
        <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
          <div>
            <h3 className="text-base font-semibold text-ink">Payment chat</h3>
            <p className="mt-1 text-sm text-steel">
              {activeBalance === null ? "Live conversation history for payment follow-ups." : `${activeCurrency} ${activeBalance.toLocaleString()} available`}
            </p>
          </div>
          <button
            type="button"
            onClick={enableNotifications}
            disabled={permission === "granted" || permission === "unsupported"}
            className="inline-flex items-center justify-center gap-2 rounded-md border border-slate-300 px-3 py-2 text-sm font-medium hover:bg-panel disabled:opacity-60"
          >
            {permission === "granted" ? <Bell size={15} /> : <BellOff size={15} />}
            {notificationLabel(permission)}
          </button>
        </div>

        {contacts.length > 0 ? (
          <div className="mt-4 flex gap-2 overflow-auto pb-1 scrollbar-thin">
            {contacts.map((contact) => (
              <button
                key={contact.id || contact.handle}
                type="button"
                onClick={() => setActiveContact(contact)}
                className={`flex min-w-[118px] flex-col items-center rounded-md border p-3 text-xs ${contact.id === activeContact?.id ? "border-mint bg-emerald-50" : "border-slate-200 hover:bg-panel"}`}
              >
                <span className={`grid h-10 w-10 place-items-center rounded-full text-sm font-semibold text-white ${contact.color}`}>{contact.initial || contact.name.slice(0, 1)}</span>
                <span className="mt-2 max-w-full truncate font-medium">{contact.name.split(" ")[0]}</span>
              </button>
            ))}
          </div>
        ) : (
          <div className="mt-4 rounded-md border border-dashed border-slate-300 p-4 text-sm text-steel">
            Payment chat is available for the two demo accounts after signing in as Asha or Rohan.
          </div>
        )}
      </div>

      {activeContact && (
        <>
          <div className="flex items-center gap-3 border-b border-slate-200 px-5 py-4">
            <div className={`grid h-10 w-10 place-items-center rounded-full font-semibold text-white ${activeContact.color}`}>{activeContact.initial || activeContact.name.slice(0, 1)}</div>
            <div className="min-w-0">
              <div className="truncate text-sm font-semibold">{activeContact.name}</div>
              <div className="truncate text-xs text-steel">{activeContact.handle} | {activeCurrency}</div>
            </div>
            <span className="ml-auto rounded-full bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700">Live</span>
          </div>

          <div className="max-h-[360px] min-h-[260px] overflow-auto bg-panel/70 p-5 scrollbar-thin">
            {notice && (
              <div className="mb-3 rounded-md border border-mint/30 bg-emerald-50 px-3 py-2 text-xs font-medium text-emerald-700">
                {notice}
              </div>
            )}
            <div className="space-y-3">
              {!shownMessages.length && (
                <div className="rounded-lg border border-dashed border-slate-300 bg-white px-4 py-6 text-center text-sm text-steel">
                  No messages yet. Send a note, request money, or pay this contact.
                </div>
              )}
              {shownMessages.map((message) => {
                const incoming = message.direction === "incoming";
                const timestamp = message.createdAt ? new Date(message.createdAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : "";
                return (
                  <div key={message.id} className={`flex ${incoming ? "justify-start" : "justify-end"}`}>
                    <div className={`max-w-[82%] rounded-lg px-4 py-3 text-sm shadow-sm ${incoming ? "bg-white text-ink" : "bg-mint text-white"}`}>
                      <div className="font-medium">{message.text}</div>
                      {message.note && <div className={`mt-1 text-xs ${incoming ? "text-steel" : "text-white/80"}`}>{message.note}</div>}
                      <div className={`mt-1 text-[11px] ${incoming ? "text-steel" : "text-white/70"}`}>{timestamp}</div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="border-t border-slate-200 bg-white p-5">
            <form onSubmit={sendChatText} className="flex gap-2">
              <input
                value={chatText}
                onChange={(event) => setChatText(event.target.value)}
                placeholder={`Message ${activeContact.name}`}
                className="min-w-0 flex-1 rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint"
              />
              <button title="Send message" disabled={!chatText.trim() || loading === "message"} className="grid h-11 w-11 place-items-center rounded-md bg-ink text-white disabled:cursor-not-allowed disabled:opacity-50">
                <Send size={17} />
              </button>
            </form>
            <div className="mt-3 grid grid-cols-[88px_1fr] overflow-hidden rounded-md border border-slate-300">
              <div className="border-r border-slate-200 bg-panel px-3 py-2.5 text-sm font-medium text-steel">{activeCurrency}</div>
              <input
                value={amount}
                onChange={(event) => setAmount(event.target.value)}
                inputMode="decimal"
                placeholder="Amount"
                className="min-w-0 px-3 py-2.5 outline-none"
              />
            </div>
            <input
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="Add a note"
              className="mt-2 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint"
            />
            <div className="mt-3 grid grid-cols-2 gap-2">
              <button disabled={loading !== "" || !amountReady} type="button" onClick={() => moneyAction("request")} className="rounded-md border border-slate-300 px-4 py-2.5 text-sm font-medium hover:bg-panel disabled:cursor-not-allowed disabled:opacity-50">
                {loading === "request" ? "Requesting..." : "Request"}
              </button>
              <button disabled={loading !== "" || !amountReady} type="button" onClick={() => moneyAction("pay")} className="rounded-md bg-mint px-4 py-2.5 text-sm font-medium text-white hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-50">
                {loading === "pay" ? "Paying..." : "Pay"}
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
