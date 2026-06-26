import { useEffect, useMemo, useState } from "react";
import { Check, Edit3, MessageSquare, Plus, Send, Sparkles, Trash2 } from "lucide-react";
import { api } from "../lib/api.js";
import { accountStorageKey } from "../lib/account.js";

const STORAGE_KEY = `ig_copilot_sessions:${accountStorageKey()}`;
const ACTIVE_KEY = `ig_copilot_active_session:${accountStorageKey()}`;

function makeSession(title = "New finance chat") {
  return {
    id: crypto.randomUUID(),
    title,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    messages: [],
  };
}

function loadSessions() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]");
    return saved.length ? saved : [makeSession("Risk review")];
  } catch {
    return [makeSession("Risk review")];
  }
}

export default function Copilot({ embedded = false, compact = false }) {
  const [sessions, setSessions] = useState(loadSessions);
  const [activeId, setActiveId] = useState(() => localStorage.getItem(ACTIVE_KEY) || sessions[0]?.id);
  const [question, setQuestion] = useState("");
  const [loading, setLoading] = useState(false);
  const [editingId, setEditingId] = useState("");
  const [draftTitle, setDraftTitle] = useState("");

  const activeSession = useMemo(() => sessions.find((session) => session.id === activeId) || sessions[0], [sessions, activeId]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(sessions));
  }, [sessions]);

  useEffect(() => {
    if (activeSession?.id) localStorage.setItem(ACTIVE_KEY, activeSession.id);
  }, [activeSession?.id]);

  function updateSession(id, updater) {
    setSessions((prev) => prev.map((session) => session.id === id ? { ...updater(session), updatedAt: new Date().toISOString() } : session));
  }

  function newChat() {
    const session = makeSession();
    setSessions((prev) => [session, ...prev]);
    setActiveId(session.id);
    setQuestion("");
  }

  function startRename(session) {
    setEditingId(session.id);
    setDraftTitle(session.title);
  }

  function saveRename(id) {
    const title = draftTitle.trim() || "Untitled chat";
    updateSession(id, (session) => ({ ...session, title }));
    setEditingId("");
    setDraftTitle("");
  }

  function deleteSession(id) {
    setSessions((prev) => {
      const remaining = prev.filter((session) => session.id !== id);
      if (!remaining.length) {
        const replacement = makeSession();
        setActiveId(replacement.id);
        setQuestion("");
        setEditingId("");
        return [replacement];
      }
      if (id === activeSession?.id) {
        setActiveId(remaining[0].id);
        setQuestion("");
      }
      if (id === editingId) {
        setEditingId("");
        setDraftTitle("");
      }
      return remaining;
    });
  }

  async function ask(e) {
    e.preventDefault();
    const q = question.trim();
    if (!q || !activeSession) return;
    const userMessage = { id: crypto.randomUUID(), role: "user", text: q, createdAt: new Date().toISOString() };
    updateSession(activeSession.id, (session) => ({
      ...session,
      title: session.messages.length ? session.title : titleFromQuestion(q),
      messages: [...session.messages, userMessage],
    }));
    setQuestion("");
    setLoading(true);
    try {
      const history = activeSession.messages.slice(-8).map(({ role, text }) => ({ role, text }));
      const result = await api("/api/copilot", { method: "POST", body: JSON.stringify({ question: q, history }) });
      const assistantMessage = {
        id: crypto.randomUUID(),
        role: "assistant",
        text: result.answer,
        confidence: result.confidence,
        sources: result.sources,
        model: result.model,
        notice: result.notice,
        createdAt: new Date().toISOString(),
      };
      updateSession(activeSession.id, (session) => ({ ...session, messages: [...session.messages, assistantMessage] }));
    } catch (err) {
      const errorMessage = {
        id: crypto.randomUUID(),
        role: "assistant",
        text: `I could not reach the finance copilot service: ${err.message}`,
        createdAt: new Date().toISOString(),
      };
      updateSession(activeSession.id, (session) => ({ ...session, messages: [...session.messages, errorMessage] }));
    } finally {
      setLoading(false);
    }
  }

  if (compact) {
    return (
      <div className="flex h-full min-h-0 flex-col overflow-hidden bg-white text-ink">
        <section className="flex min-h-0 flex-1 flex-col">
          <header className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
            <div>
              <div className="text-sm font-semibold">AI Finance Copilot</div>
              <div className="text-xs text-steel">{activeSession?.title}</div>
            </div>
            <button onClick={() => activeSession && startRename(activeSession)} className="flex items-center gap-2 rounded-md border border-slate-300 px-3 py-2 text-sm font-medium hover:bg-panel">
              <Edit3 size={15} /> Rename
            </button>
          </header>
          <div className="min-h-0 flex-1 overflow-auto p-5 scrollbar-thin">
            {!activeSession?.messages.length ? (
              <div className="mx-auto flex h-full max-w-2xl flex-col items-center justify-center text-center">
                <div className="grid h-12 w-12 place-items-center rounded-full bg-mint/10 text-mint"><Sparkles /></div>
                <h2 className="mt-4 text-xl font-semibold">Ask about cash, invoices, risk, or FX</h2>
                <p className="mt-2 text-sm leading-6 text-steel">Ask follow-up questions about your finance workspace.</p>
                <div className="mt-5 grid w-full gap-2">
                  {["Which invoices are dangerous?", "Summarize cash runway risk", "Which clients need review?"].map((prompt) => (
                    <button key={prompt} onClick={() => setQuestion(prompt)} className="rounded-md border border-slate-200 p-3 text-left text-sm hover:bg-panel">{prompt}</button>
                  ))}
                </div>
              </div>
            ) : (
              <div className="space-y-4">
                {activeSession.messages.map((message) => (
                  <div key={message.id} className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}>
                    <div className={`max-w-[82%] rounded-lg px-4 py-3 text-sm leading-6 ${message.role === "user" ? "bg-mint text-white" : "bg-panel text-ink"}`}>
                      {message.text}
                      {message.role === "assistant" && <ResponseMeta message={message} />}
                    </div>
                  </div>
                ))}
                {loading && <div className="max-w-[82%] rounded-lg bg-panel px-4 py-3 text-sm text-steel">Analyzing finance data...</div>}
              </div>
            )}
          </div>
          <form onSubmit={ask} className="border-t border-slate-200 p-4">
            <div className="flex gap-2">
              <input value={question} onChange={(e) => setQuestion(e.target.value)} placeholder='Ex. "Which invoices are dangerous?"' className="min-w-0 flex-1 rounded-md border border-slate-300 px-3 py-3 outline-none focus:border-mint" />
              <button title="Ask copilot" disabled={!question.trim() || loading} className="grid h-12 w-12 place-items-center rounded-md bg-mint text-white hover:bg-emerald-700 disabled:opacity-60"><Send size={18} /></button>
            </div>
          </form>
        </section>
      </div>
    );
  }

  return (
    <div className={`grid overflow-hidden bg-white ${embedded ? "h-full min-h-0 lg:grid-cols-[260px_1fr]" : "h-[calc(100vh-150px)] min-h-[620px] rounded-lg border border-slate-200 shadow-soft lg:grid-cols-[300px_1fr]"}`}>
      <aside className="flex min-h-0 flex-col border-r border-slate-200 bg-panel">
        <div className="border-b border-slate-200 p-4">
          <button onClick={newChat} className="flex w-full items-center justify-center gap-2 rounded-md bg-ink px-4 py-2.5 text-sm font-medium text-white hover:bg-slate-800">
            <Plus size={17} /> New chat
          </button>
        </div>
        <div className="min-h-0 flex-1 overflow-auto p-3 scrollbar-thin">
          <div className="mb-2 px-2 text-xs font-medium uppercase tracking-wide text-steel">Sessions</div>
          <div className="space-y-1">
            {sessions.map((session) => (
              <div key={session.id} className={`group rounded-md border ${session.id === activeSession?.id ? "border-mint bg-white" : "border-transparent hover:bg-white"}`}>
                {editingId === session.id ? (
                  <div className="flex items-center gap-2 p-2">
                    <input value={draftTitle} onChange={(e) => setDraftTitle(e.target.value)} onKeyDown={(e) => { if (e.key === "Enter") saveRename(session.id); }} className="min-w-0 flex-1 rounded border border-slate-300 px-2 py-1 text-sm outline-none focus:border-mint" autoFocus />
                    <button title="Save name" onClick={() => saveRename(session.id)} className="grid h-8 w-8 place-items-center rounded bg-mint text-white"><Check size={15} /></button>
                  </div>
                ) : (
                  <button onClick={() => setActiveId(session.id)} className="flex w-full items-center gap-2 px-3 py-2 text-left">
                    <MessageSquare size={16} className="shrink-0 text-steel" />
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-medium">{session.title}</div>
                      <div className="text-xs text-steel">{session.messages.length} messages</div>
                    </div>
                    <span className="flex shrink-0 items-center gap-1 opacity-100 lg:opacity-0 lg:group-hover:opacity-100 lg:group-focus-within:opacity-100">
                      <span onClick={(e) => { e.stopPropagation(); startRename(session); }} className="grid h-7 w-7 place-items-center rounded text-steel hover:bg-panel" role="button" title="Rename chat">
                        <Edit3 size={14} />
                      </span>
                      <span onClick={(e) => { e.stopPropagation(); deleteSession(session.id); }} className="grid h-7 w-7 place-items-center rounded text-steel hover:bg-coral/10 hover:text-coral" role="button" title="Delete chat">
                        <Trash2 size={14} />
                      </span>
                    </span>
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>
      </aside>

      <section className="flex min-h-0 flex-col">
        <header className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
          <div>
            <div className="text-sm font-semibold">AI Finance Copilot</div>
            <div className="text-xs text-steel">{activeSession?.title}</div>
          </div>
          <button onClick={() => activeSession && startRename(activeSession)} className="flex items-center gap-2 rounded-md border border-slate-300 px-3 py-2 text-sm font-medium hover:bg-panel">
            <Edit3 size={15} /> Rename
          </button>
        </header>

        <div className="min-h-0 flex-1 overflow-auto p-5 scrollbar-thin">
          {!activeSession?.messages.length ? (
            <div className="mx-auto flex h-full max-w-2xl flex-col items-center justify-center text-center">
              <div className="grid h-12 w-12 place-items-center rounded-full bg-mint/10 text-mint"><Sparkles /></div>
              <h2 className="mt-4 text-2xl font-semibold">Ask about cash, invoices, risk, or FX</h2>
              <p className="mt-2 text-sm leading-6 text-steel">Start a session, ask follow-up questions, and rename chats as your analysis evolves.</p>
              <div className="mt-5 grid gap-2 sm:grid-cols-2">
                {["Which invoices are dangerous?", "Summarize cash runway risk", "Which clients need review?", "Should we convert EUR now?"].map((prompt) => (
                  <button key={prompt} onClick={() => setQuestion(prompt)} className="rounded-md border border-slate-200 p-3 text-left text-sm hover:bg-panel">{prompt}</button>
                ))}
              </div>
            </div>
          ) : (
            <div className="mx-auto max-w-4xl space-y-4">
              {activeSession.messages.map((message) => (
                <div key={message.id} className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}>
                  <div className={`max-w-[78%] rounded-lg px-4 py-3 text-sm leading-6 ${message.role === "user" ? "bg-mint text-white" : "bg-panel text-ink"}`}>
                    {message.text}
                    {message.role === "assistant" && <ResponseMeta message={message} />}
                  </div>
                </div>
              ))}
              {loading && <div className="max-w-[78%] rounded-lg bg-panel px-4 py-3 text-sm text-steel">Analyzing finance data...</div>}
            </div>
          )}
        </div>

        <form onSubmit={ask} className="border-t border-slate-200 p-4">
          <div className="mx-auto flex max-w-4xl gap-2">
            <input value={question} onChange={(e) => setQuestion(e.target.value)} placeholder='Ex. "Which invoices are dangerous?"' className="min-w-0 flex-1 rounded-md border border-slate-300 px-3 py-3 outline-none focus:border-mint" />
            <button title="Ask copilot" disabled={!question.trim() || loading} className="grid h-12 w-12 place-items-center rounded-md bg-mint text-white hover:bg-emerald-700 disabled:opacity-60"><Send size={18} /></button>
          </div>
        </form>
      </section>
    </div>
  );
}

function titleFromQuestion(question) {
  const cleaned = question.replace(/[?!.]+$/, "").trim();
  return cleaned.length > 42 ? `${cleaned.slice(0, 39)}...` : cleaned || "New finance chat";
}

function ResponseMeta({ message }) {
  if (!message.confidence && !message.sources?.length && !message.notice) return null;
  return (
    <div className="mt-3 border-t border-slate-200 pt-2 text-[11px] leading-5 text-steel">
      {message.confidence && <div><span className="font-medium text-ink">Confidence:</span> {message.confidence}</div>}
      {message.model && <div><span className="font-medium text-ink">Model:</span> {message.model}</div>}
      {!!message.sources?.length && <div><span className="font-medium text-ink">Account data:</span> {message.sources.join(", ")}</div>}
      {message.notice && <div className="mt-1">{message.notice}</div>}
    </div>
  );
}
