export function Card({ title, value, helper, actions, children }) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-soft">
      {(title || actions) && (
        <div className="flex items-center justify-between gap-3">
          {title && <div className="text-sm font-medium text-steel">{title}</div>}
          {actions && <div className="flex shrink-0 items-center gap-2">{actions}</div>}
        </div>
      )}
      {value && <div className="mt-2 text-2xl font-semibold tracking-normal">{value}</div>}
      {helper && <div className="mt-1 text-sm text-steel">{helper}</div>}
      {children}
    </section>
  );
}

export function Skeleton() {
  return <div className="h-36 animate-pulse rounded-lg bg-slate-200" />;
}
