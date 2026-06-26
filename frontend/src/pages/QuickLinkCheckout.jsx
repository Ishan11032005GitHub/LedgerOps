import { useEffect, useState } from "react";
import { CheckCircle2, CreditCard, LoaderCircle, LockKeyhole, ShieldCheck } from "lucide-react";
import { useParams } from "react-router-dom";
import { api } from "../lib/api.js";
import { formatCurrency } from "../lib/currencies.js";

const blankCard = { cardholder_name: "", card_number: "", expiry_month: "", expiry_year: "", cvc: "" };

function formatCardNumber(value) {
  return value.replace(/\D/g, "").slice(0, 19).replace(/(.{4})/g, "$1 ").trim();
}

export default function QuickLinkCheckout() {
  const { publicId } = useParams();
  const [link, setLink] = useState(null);
  const [card, setCard] = useState(blankCard);
  const [state, setState] = useState("loading");
  const [error, setError] = useState("");

  useEffect(() => {
    api(`/api/payment-app/public/quicklinks/${publicId}`)
      .then((result) => {
        setLink(result);
        setState(result.status === "paid" ? "paid" : "ready");
      })
      .catch((requestError) => {
        setError(requestError.message);
        setState("error");
      });
  }, [publicId]);

  async function pay(event) {
    event.preventDefault();
    setState("paying");
    setError("");
    try {
      const result = await api(`/api/payment-app/public/quicklinks/${publicId}/demo-pay`, {
        method: "POST",
        body: JSON.stringify({
          ...card,
          card_number: card.card_number.replace(/\s/g, ""),
          expiry_month: Number(card.expiry_month),
          expiry_year: Number(card.expiry_year),
        }),
      });
      setLink(result);
      setCard(blankCard);
      setState("paid");
    } catch (requestError) {
      setError(requestError.message);
      setState("ready");
    }
  }

  return (
    <main className="min-h-screen bg-panel px-4 py-10 text-ink">
      <div className="mx-auto max-w-lg">
        <div className="mb-6 text-center">
          <div className="text-2xl font-semibold">LedgerOps</div>
          <div className="mt-1 text-sm text-steel">Secure international card checkout</div>
        </div>
        <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-soft">
          {state === "loading" && <div className="flex items-center justify-center gap-2 py-16 text-steel"><LoaderCircle className="animate-spin" size={20} /> Loading payment link...</div>}
          {state === "error" && <div className="rounded-md bg-red-50 p-4 text-sm text-coral">{error}</div>}
          {link && state !== "loading" && state !== "error" && (
            <>
              <div className="flex items-start justify-between gap-4 border-b border-slate-200 pb-5">
                <div>
                  <div className="text-sm text-steel">{link.title}</div>
                  <div className="mt-1 text-3xl font-semibold">{formatCurrency(link.amount, link.currency)}</div>
                  <div className="mt-1 text-xs capitalize text-steel">{link.purpose_code.replaceAll("_", " ")}</div>
                </div>
                <div className="grid h-11 w-11 shrink-0 place-items-center rounded-md bg-mint/10 text-mint"><CreditCard size={22} /></div>
              </div>

              {state === "paid" ? (
                <div className="py-12 text-center">
                  <CheckCircle2 size={46} className="mx-auto text-mint" />
                  <h1 className="mt-4 text-xl font-semibold">Payment complete</h1>
                  <p className="mt-2 text-sm text-steel">The merchant can now see this settlement in LedgerOps.</p>
                </div>
              ) : link.status !== "active" ? (
                <div className="my-6 rounded-md bg-amber-50 p-4 text-sm text-amber-800">This payment link is {link.status} and cannot accept a payment.</div>
              ) : (
                <form onSubmit={pay} className="mt-5 space-y-4">
                  <div className="rounded-md bg-amber-50 px-3 py-2 text-xs text-amber-800">Demo checkout. Use test card 4242 4242 4242 4242, any future expiry, and any three-digit CVC.</div>
                  <label className="block text-sm font-medium">Name on card
                    <input required value={card.cardholder_name} onChange={(event) => setCard({ ...card, cardholder_name: event.target.value })} autoComplete="cc-name" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
                  </label>
                  <label className="block text-sm font-medium">Card number
                    <div className="relative mt-1">
                      <CreditCard size={17} className="absolute left-3 top-3 text-steel" />
                      <input required inputMode="numeric" value={card.card_number} onChange={(event) => setCard({ ...card, card_number: formatCardNumber(event.target.value) })} autoComplete="cc-number" placeholder="4242 4242 4242 4242" className="w-full rounded-md border border-slate-300 py-2.5 pl-10 pr-3 outline-none focus:border-mint" />
                    </div>
                  </label>
                  <div className="grid grid-cols-3 gap-3">
                    <label className="text-sm font-medium">Month
                      <input required type="number" min="1" max="12" value={card.expiry_month} onChange={(event) => setCard({ ...card, expiry_month: event.target.value })} placeholder="12" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
                    </label>
                    <label className="text-sm font-medium">Year
                      <input required type="number" min={new Date().getFullYear()} value={card.expiry_year} onChange={(event) => setCard({ ...card, expiry_year: event.target.value })} placeholder="2029" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
                    </label>
                    <label className="text-sm font-medium">CVC
                      <input required inputMode="numeric" maxLength={4} value={card.cvc} onChange={(event) => setCard({ ...card, cvc: event.target.value.replace(/\D/g, "").slice(0, 4) })} autoComplete="cc-csc" placeholder="123" className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2.5 outline-none focus:border-mint" />
                    </label>
                  </div>
                  {error && <div className="rounded-md bg-red-50 p-3 text-sm text-coral">{error}</div>}
                  <button disabled={state === "paying"} className="flex w-full items-center justify-center gap-2 rounded-md bg-mint px-4 py-3 font-medium text-white hover:bg-emerald-700 disabled:opacity-60">
                    {state === "paying" ? <LoaderCircle size={18} className="animate-spin" /> : <LockKeyhole size={18} />}
                    {state === "paying" ? "Processing..." : `Pay ${formatCurrency(link.amount, link.currency)}`}
                  </button>
                  <div className="flex items-start gap-2 text-xs text-steel"><ShieldCheck size={15} className="mt-0.5 shrink-0 text-mint" /> Test card details are validated for this simulation and are never stored.</div>
                </form>
              )}
            </>
          )}
        </section>
      </div>
    </main>
  );
}
