import { useState } from 'react';
import {
  ArrowRight,
  Bell,
  CalendarDays,
  Check,
  ChevronRight,
  CircleCheck,
  Clock3,
  MoreHorizontal,
  PawPrint,
  Phone,
  RotateCcw,
  ShieldCheck,
  Stethoscope,
} from 'lucide-react';

const colors = {
  canvas: '#eef1eb',
  ink: '#243129',
  muted: '#68766b',
  line: '#d8e0d5',
  card: '#fbfcf9',
  olive: '#5d7963',
  oliveDark: '#385840',
  oliveSoft: '#e1ebe1',
  ochre: '#8b702c',
  ochreSoft: '#f3e9c9',
  rustSoft: '#faeeea',
  rust: '#9a4939',
};

type Event = {
  id: number;
  title: string;
  pet: string;
  detail: string;
  status: 'overdue' | 'due' | 'upcoming';
};

const initialEvents: Event[] = [
  { id: 1, title: 'Parasite prevention', pet: 'Miso', detail: 'Was due 10 May', status: 'overdue' },
  { id: 2, title: 'Midday water check', pet: 'Miso', detail: 'Today · target 220 ml', status: 'due' },
  { id: 3, title: 'Evening walk', pet: 'Basil', detail: 'Today · 20–30 min', status: 'due' },
];

export function GuardianOperationsMobileState() {
  const events = initialEvents;
  const [completedId, setCompletedId] = useState<number | null>(2);
  const [notice, setNotice] = useState('Water check saved · Miso is all set');
  const [menuOpen, setMenuOpen] = useState(false);

  const announce = (message: string) => {
    setNotice(message);
    window.setTimeout(() => setNotice(''), 2600);
  };

  const toggleEvent = (id: number) => {
    const isCompleted = completedId === id;
    setCompletedId(isCompleted ? null : id);
    announce(isCompleted ? 'Water check reopened' : 'Care item marked complete');
  };

  return (
    <main
      className="min-h-[100dvh] w-full"
      style={{ background: colors.canvas, color: colors.ink, fontFamily: "'DM Sans', ui-sans-serif, system-ui, sans-serif" }}
    >
      <div className="mx-auto min-h-[100dvh] w-full max-w-[430px] overflow-hidden">
        <header className="sticky top-0 z-20 flex h-[72px] items-center justify-between border-b px-5" style={{ background: 'rgba(248,250,246,.94)', borderColor: colors.line }}>
          <div className="flex items-center gap-3">
            <div className="grid h-10 w-10 place-items-center rounded-[14px]" style={{ background: colors.olive }}>
              <PawPrint size={19} color="#f8faf5" strokeWidth={1.8} />
            </div>
            <div>
              <p className="text-[10px] font-bold uppercase tracking-[.16em]" style={{ color: colors.muted }}>Guardian desk</p>
              <h1 className="text-[20px] font-semibold tracking-[-.03em]">Good morning, Mara</h1>
            </div>
          </div>
          <button
            type="button"
            aria-label="Open notifications"
            onClick={() => announce('You are up to date')}
            className="relative grid h-11 w-11 place-items-center rounded-full transition-transform active:scale-95"
            style={{ color: colors.ink }}
          >
            <Bell size={20} strokeWidth={1.7} />
            <span className="absolute right-[9px] top-[8px] h-2 w-2 rounded-full border-2" style={{ background: colors.ochre, borderColor: '#f8faf6' }} />
          </button>
        </header>

        <div className="space-y-4 px-4 pb-10 pt-5">
          <section aria-labelledby="today-heading">
            <div className="mb-4 flex items-end justify-between px-1">
              <div>
                <p className="mb-1 text-[11px] font-bold uppercase tracking-[.14em]" style={{ color: colors.muted }}>Tuesday · 14 May</p>
                <h2 id="today-heading" className="text-[27px] font-medium leading-none tracking-[-.045em]">A steady start.</h2>
              </div>
              <div className="rounded-full px-3 py-1.5 text-[11px] font-semibold" style={{ color: colors.oliveDark, background: colors.oliveSoft }}>
                1 of 3 done
              </div>
            </div>
            <div className="rounded-[22px] border p-4" style={{ background: colors.card, borderColor: colors.line }}>
              <div className="flex items-center gap-3">
                <div className="grid h-11 w-11 place-items-center rounded-[14px] text-[12px] font-bold text-white" style={{ background: '#b7835b' }}>MI</div>
                <div className="min-w-0 flex-1">
                  <p className="text-[15px] font-semibold">Miso</p>
                  <p className="mt-0.5 text-[12px]" style={{ color: colors.muted }}>Shiba Inu · 4 years</p>
                </div>
                <div className="flex items-center gap-1.5 text-[11px] font-semibold" style={{ color: colors.oliveDark }}>
                  <CircleCheck size={15} /> Doing well
                </div>
              </div>
              <div className="mt-4 flex items-center justify-between border-t pt-3" style={{ borderColor: colors.line }}>
                <div className="flex items-center gap-2">
                  <ShieldCheck size={16} style={{ color: colors.olive }} />
                  <span className="text-[12px]" style={{ color: colors.muted }}>Next: water check at midday</span>
                </div>
                <button type="button" onClick={() => announce('Miso’s profile opened')} className="grid h-9 w-9 place-items-center rounded-full transition-transform active:scale-95" style={{ background: colors.oliveSoft, color: colors.oliveDark }} aria-label="Open Miso profile">
                  <ChevronRight size={17} />
                </button>
              </div>
            </div>
          </section>

          <section className="rounded-[22px] border p-4" style={{ background: colors.oliveSoft, borderColor: '#cadacb' }} aria-labelledby="pets-heading">
            <div className="mb-3 flex items-center justify-between">
              <h2 id="pets-heading" className="text-[17px] font-semibold tracking-[-.02em]">My Pets</h2>
              <button type="button" onClick={() => announce('Pet list opened')} className="flex min-h-11 items-center gap-1 rounded-xl px-2 text-[12px] font-semibold" style={{ color: colors.oliveDark }}>
                View all <ChevronRight size={14} />
              </button>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <button type="button" onClick={() => announce('Miso selected')} className="flex min-h-[62px] items-center gap-2.5 rounded-[15px] border p-2 text-left transition-transform active:scale-[.98]" style={{ background: colors.card, borderColor: colors.olive }}>
                <span className="grid h-9 w-9 place-items-center rounded-xl text-[10px] font-bold text-white" style={{ background: '#b7835b' }}>MI</span>
                <span><strong className="block text-[13px]">Miso</strong><small className="text-[11px]" style={{ color: colors.muted }}>Doing well</small></span>
              </button>
              <button type="button" onClick={() => announce('Basil selected')} className="flex min-h-[62px] items-center gap-2.5 rounded-[15px] border p-2 text-left transition-transform active:scale-[.98]" style={{ background: colors.card, borderColor: colors.line }}>
                <span className="grid h-9 w-9 place-items-center rounded-xl text-[10px] font-bold text-white" style={{ background: '#789077' }}>BA</span>
                <span><strong className="block text-[13px]">Basil</strong><small className="text-[11px]" style={{ color: colors.muted }}>All caught up</small></span>
              </button>
            </div>
          </section>

          <section className="rounded-[22px] border p-4" style={{ background: colors.card, borderColor: colors.line }} aria-labelledby="due-heading">
            <div className="mb-1 flex items-center justify-between">
              <h2 id="due-heading" className="text-[17px] font-semibold tracking-[-.02em]">Due and Overdue</h2>
              <button type="button" onClick={() => announce('All care events opened')} className="flex min-h-11 items-center gap-1 rounded-xl px-2 text-[12px] font-semibold" style={{ color: colors.oliveDark }}>All events <ArrowRight size={14} /></button>
            </div>
            <p className="mb-2 text-[12px]" style={{ color: colors.muted }}>{events.length - (completedId ? 1 : 0)} actions still need attention</p>
            {events.map((event) => {
              const complete = completedId === event.id;
              return (
                <div key={event.id} className={`flex items-center gap-3 border-t py-3 ${complete ? 'opacity-100' : ''}`} style={{ borderColor: colors.line }}>
                  <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl" style={{ background: complete ? colors.oliveSoft : event.status === 'overdue' ? colors.rustSoft : '#eef4ee', color: complete ? colors.oliveDark : event.status === 'overdue' ? colors.rust : colors.oliveDark }}>
                    {complete ? <Check size={17} /> : event.status === 'overdue' ? <Clock3 size={17} /> : <CalendarDays size={16} />}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className={`text-[13px] font-semibold ${complete ? 'line-through' : ''}`} style={{ color: complete ? colors.muted : colors.ink }}>{event.title}</p>
                    <p className="mt-0.5 truncate text-[11px]" style={{ color: colors.muted }}>{event.pet} · {event.detail}</p>
                  </div>
                  <button type="button" onClick={() => toggleEvent(event.id)} className="grid h-11 w-11 shrink-0 place-items-center rounded-xl border transition-transform active:scale-95" style={{ background: complete ? colors.olive : colors.card, borderColor: complete ? colors.olive : colors.line, color: complete ? '#fff' : 'transparent' }} aria-label={complete ? `Reopen ${event.title}` : `Mark ${event.title} complete`}>
                    {complete && <Check size={17} />}
                  </button>
                </div>
              );
            })}
            {completedId === 2 && (
              <div className="mt-2 flex items-center justify-between rounded-[15px] border px-3 py-2.5" style={{ background: '#f4f8f2', borderColor: '#cbdcc9' }} role="status">
                <span className="flex items-center gap-2 text-[11px] font-semibold" style={{ color: colors.oliveDark }}><CircleCheck size={15} /> Water check saved</span>
                <button type="button" onClick={() => toggleEvent(2)} className="flex min-h-9 items-center gap-1 rounded-lg px-2 text-[11px] font-bold" style={{ color: colors.oliveDark }}><RotateCcw size={13} /> Undo</button>
              </div>
            )}
          </section>

          <section className="rounded-[22px] border p-4" style={{ background: colors.card, borderColor: colors.line }} aria-labelledby="vets-heading">
            <div className="mb-1 flex items-center justify-between">
              <h2 id="vets-heading" className="text-[17px] font-semibold tracking-[-.02em]">My Vets</h2>
              <button type="button" onClick={() => announce('Vet directory opened')} className="flex min-h-11 items-center gap-1 rounded-xl px-2 text-[12px] font-semibold" style={{ color: colors.oliveDark }}>Manage <ChevronRight size={14} /></button>
            </div>
            <div className="flex items-center gap-3 border-t py-3" style={{ borderColor: colors.line }}>
              <div className="grid h-10 w-10 place-items-center rounded-xl" style={{ background: colors.ochreSoft, color: colors.ochre }}><Stethoscope size={18} /></div>
              <div className="min-w-0 flex-1"><p className="text-[13px] font-semibold">Cedar Grove Veterinary</p><p className="mt-0.5 text-[11px]" style={{ color: colors.muted }}>Primary care · 2 pets</p></div>
              <button type="button" onClick={() => announce('Calling Cedar Grove Veterinary')} className="grid h-11 w-11 place-items-center rounded-xl" style={{ background: colors.oliveSoft, color: colors.oliveDark }} aria-label="Call Cedar Grove Veterinary"><Phone size={16} /></button>
            </div>
            <div className="flex items-center gap-3 border-t pt-3" style={{ borderColor: colors.line }}>
              <div className="grid h-10 w-10 place-items-center rounded-xl text-[10px] font-bold" style={{ background: colors.ochreSoft, color: colors.ochre }}>LO</div>
              <div className="min-w-0 flex-1"><p className="text-[13px] font-semibold">Dr Lena Ortiz</p><p className="mt-0.5 text-[11px]" style={{ color: colors.muted }}>Dermatology · Miso</p></div>
              <button type="button" onClick={() => announce('Calling Dr Lena Ortiz')} className="grid h-11 w-11 place-items-center rounded-xl" style={{ background: colors.oliveSoft, color: colors.oliveDark }} aria-label="Call Dr Lena Ortiz"><Phone size={16} /></button>
            </div>
          </section>
        </div>
      </div>
      {notice && (
        <div className="fixed bottom-4 left-1/2 z-30 flex w-[calc(100%-32px)] max-w-[398px] -translate-x-1/2 items-center gap-2 rounded-2xl px-4 py-3 text-[12px] font-semibold text-white shadow-lg" style={{ background: '#31483a' }} role="status">
          <Check size={16} /> <span className="flex-1">{notice}</span>
          <button type="button" aria-label="Dismiss message" onClick={() => setNotice('')}><MoreHorizontal size={16} /></button>
        </div>
      )}
      {menuOpen && <button type="button" aria-label="Close menu" onClick={() => setMenuOpen(false)} className="fixed inset-0 z-10 bg-[#243129]/20" />}
    </main>
  );
}

export default GuardianOperationsMobileState;