import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Bot, Maximize2, Minimize2, X } from "lucide-react";
import Copilot from "../pages/Copilot.jsx";

export default function FloatingCopilot() {
  const [open, setOpen] = useState(false);
  const [fullscreen, setFullscreen] = useState(false);

  function close() {
    setOpen(false);
    setFullscreen(false);
  }

  return (
    <>
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: 16, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 12, scale: 0.98 }}
            transition={{ duration: 0.16, ease: "easeOut" }}
            className={`fixed z-40 overflow-hidden border shadow-2xl ${
              fullscreen
                ? "inset-4 rounded-lg border-slate-200 bg-white"
                : "bottom-24 right-5 h-[min(620px,calc(100vh-130px))] w-[min(420px,calc(100vw-40px))] rounded-xl border-slate-200 bg-white"
            }`}
          >
            <div className="flex h-12 items-center justify-between border-b border-slate-200 bg-white px-3">
              <button
                type="button"
                title={fullscreen ? "Exit full screen" : "Open full screen"}
                onClick={() => setFullscreen((value) => !value)}
                className="grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-steel hover:text-ink"
              >
                {fullscreen ? <Minimize2 size={16} /> : <Maximize2 size={16} />}
              </button>
              <div className="text-sm font-medium text-ink">AI Finance Copilot</div>
              <button
                type="button"
                title="Close copilot"
                onClick={close}
                className="grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-steel hover:text-ink"
              >
                <X size={17} />
              </button>
            </div>
            <div className="h-[calc(100%-3rem)]">
              <Copilot embedded compact={!fullscreen} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <button
        type="button"
        title="Open AI copilot"
        onClick={() => {
          if (open) close();
          else setOpen(true);
        }}
        className="fixed bottom-5 right-5 z-50 grid h-14 w-14 place-items-center rounded-full bg-mint text-white shadow-2xl transition hover:bg-emerald-700 focus:outline-none focus:ring-4 focus:ring-emerald-200"
      >
        {open ? <X size={23} /> : <Bot size={24} />}
      </button>
    </>
  );
}
