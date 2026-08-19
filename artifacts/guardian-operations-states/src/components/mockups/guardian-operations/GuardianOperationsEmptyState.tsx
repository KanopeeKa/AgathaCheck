import React, { useState } from 'react';
import {
  Bell,
  CalendarDays,
  Check,
  ChevronRight,
  HeartPulse,
  Menu,
  PawPrint,
  Plus,
  ShieldCheck,
  Stethoscope,
  X,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

type EmptySectionProps = {
  title: string;
  icon: React.ReactNode;
  children: React.ReactNode;
  action?: string;
  onAction?: () => void;
  tint?: string;
};

function EmptySection({
  title,
  icon,
  children,
  action,
  onAction,
  tint = '#edf1e8',
}: EmptySectionProps) {
  return (
    <section className="overflow-hidden rounded-[22px] border border-[#dbe3d7] bg-[#fbfcf8] shadow-[0_5px_20px_rgba(44,67,48,0.045)]">
      <div className="flex items-center justify-between border-b border-[#e5ebe1] px-5 py-4">
        <div className="flex items-center gap-3">
          <span
            className="grid h-9 w-9 place-items-center rounded-xl text-[#5e7c65]"
            style={{ backgroundColor: tint }}
            aria-hidden="true"
          >
            {icon}
          </span>
          <h2 className="text-[15px] font-semibold tracking-[-0.01em] text-[#1f2d23]">{title}</h2>
        </div>
        {action && onAction ? (
          <button
            type="button"
            onClick={onAction}
            className="inline-flex min-h-11 items-center gap-1 rounded-lg px-2 text-[12px] font-semibold text-[#52715a] transition-colors hover:bg-[#edf1e8] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#5e7c65]"
          >
            {action}
            <ChevronRight size={14} strokeWidth={2.3} />
          </button>
        ) : null}
      </div>
      <div className="px-5 py-5">{children}</div>
    </section>
  );
}

function SoftEmptyIcon({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-[#eef3eb] text-[#6b876f]">
      {children}
    </div>
  );
}

export default function GuardianOperationsEmptyState() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [showPetForm, setShowPetForm] = useState(false);
  const [petName, setPetName] = useState('');
  const [savedPet, setSavedPet] = useState('');
  const [notice, setNotice] = useState('');

  const announce = (message: string) => {
    setNotice(message);
    window.setTimeout(() => setNotice(''), 2600);
  };

  const addPet = () => {
    const name = petName.trim();
    if (!name) {
      announce('Enter a pet name to continue');
      return;
    }
    setSavedPet(name);
    setShowPetForm(false);
    setPetName('');
    announce(`${name} is ready to add`);
  };
  const navItems: Array<[string, LucideIcon]> = [
    ['Home', PawPrint],
    ['Health log', HeartPulse],
    ['Appointments', CalendarDays],
  ];

  return (
    <main className="min-h-[100dvh] bg-[#f1f4ef] font-sans text-[#1f2d23]">
      <header className="sticky top-0 z-20 border-b border-[#dce5da] bg-[#f8faf6]/95 backdrop-blur">
        <div className="mx-auto flex h-16 w-full max-w-[1180px] items-center justify-between px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setMenuOpen((open) => !open)}
              aria-label="Open navigation"
              aria-expanded={menuOpen}
              className="grid h-11 w-11 place-items-center rounded-xl text-[#42574a] transition-colors hover:bg-[#eaf0e8] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#5e7c65]"
            >
              <Menu size={21} />
            </button>
            <div className="grid h-9 w-9 place-items-center rounded-xl bg-[#5e7c65] text-[#f7faf4]">
              <PawPrint size={18} strokeWidth={2.2} />
            </div>
            <span className="text-[17px] font-semibold tracking-[-0.02em] text-[#26352a]">Agatha Track</span>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => announce('You are all caught up')}
              aria-label="Notifications"
              className="relative grid h-11 w-11 place-items-center rounded-xl text-[#53685a] transition-colors hover:bg-[#eaf0e8] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#5e7c65]"
            >
              <Bell size={19} />
            </button>
            <button
              type="button"
              onClick={() => announce('Profile menu opened')}
              className="grid h-9 w-9 place-items-center rounded-full bg-[#d9e5d7] text-[11px] font-bold tracking-[0.04em] text-[#35543b] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#5e7c65]"
              aria-label="Open profile menu"
            >
              AR
            </button>
          </div>
        </div>
      </header>

      {menuOpen ? (
        <div className="fixed inset-0 z-30 bg-[#203027]/20" onClick={() => setMenuOpen(false)}>
          <aside
            className="h-full w-[min(82vw,300px)] bg-[#304238] p-5 text-[#f3f6ef] shadow-2xl"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="mb-8 flex items-center justify-between">
              <span className="text-sm font-semibold tracking-[0.08em] text-[#e9efe6]">OPERATIONS DESK</span>
              <button type="button" onClick={() => setMenuOpen(false)} aria-label="Close navigation" className="grid h-10 w-10 place-items-center rounded-xl text-[#cad7ca] hover:bg-white/10">
                <X size={18} />
              </button>
            </div>
            <nav className="space-y-2" aria-label="Primary navigation">
              {navItems.map(([label, Icon]) => (
                <button
                  type="button"
                  key={label}
                  onClick={() => {
                    setMenuOpen(false);
                    announce(`${label} is coming into view`);
                  }}
                  className={`flex min-h-12 w-full items-center gap-3 rounded-2xl px-4 text-left text-sm ${label === 'Home' ? 'bg-[#dce9dd] font-semibold text-[#2e5233]' : 'text-[#d3ded3] hover:bg-white/10'}`}
                >
                  <Icon size={18} />
                  {label}
                </button>
              ))}
            </nav>
          </aside>
        </div>
      ) : null}

      <div className="mx-auto w-full max-w-[1180px] px-4 py-8 sm:px-6 sm:py-10 lg:px-8">
        <div className="mb-7 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
          <div>
            <p className="mb-2 text-[11px] font-bold uppercase tracking-[0.16em] text-[#708174]">Guardian operations desk</p>
            <h1 className="text-[clamp(28px,4vw,40px)] font-medium leading-[1.06] tracking-[-0.045em] text-[#25352a]">
              A good place to begin.
            </h1>
            <p className="mt-3 max-w-[500px] text-[14px] leading-6 text-[#6d7d70]">
              Add your first pet and we’ll keep their care details close, clear, and easy to act on.
            </p>
          </div>
          <div className="flex items-center gap-2 self-start rounded-full border border-[#dce5da] bg-[#f8faf6] px-3 py-2 text-[12px] text-[#6c7c70] sm:self-auto">
            <ShieldCheck size={15} className="text-[#5e7c65]" />
            Private guardian view
          </div>
        </div>

        <div className="space-y-4">
          <EmptySection
            title="My Pets"
            icon={<PawPrint size={18} />}
            action={savedPet ? 'Add another' : undefined}
            onAction={() => setShowPetForm(true)}
            tint="#dfeade"
          >
            {savedPet ? (
              <div className="flex items-center justify-between gap-4 rounded-2xl border border-[#cbdcca] bg-[#f4f8f1] p-4">
                <div className="flex items-center gap-3">
                  <div className="grid h-11 w-11 place-items-center rounded-2xl bg-[#6f8e73] text-[#f7faf4]"><PawPrint size={19} /></div>
                  <div>
                    <p className="font-semibold text-[#29412f]">{savedPet}</p>
                    <p className="mt-0.5 text-xs text-[#708174]">Ready for care details</p>
                  </div>
                </div>
                <Check size={19} className="text-[#5e7c65]" aria-label="Added" />
              </div>
            ) : (
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
                <SoftEmptyIcon><PawPrint size={22} /></SoftEmptyIcon>
                <div className="min-w-0 flex-1">
                  <p className="font-medium text-[#304337]">No pets added yet</p>
                  <p className="mt-1 max-w-[530px] text-[13px] leading-5 text-[#718074]">Start with one pet. You can add health details, reminders, and care contacts as you go.</p>
                </div>
                <button
                  type="button"
                  onClick={() => setShowPetForm(true)}
                  className="inline-flex min-h-12 shrink-0 items-center justify-center gap-2 rounded-xl bg-[#5e7c65] px-4 text-[13px] font-semibold text-white shadow-[0_3px_8px_rgba(63,94,68,0.18)] transition-transform hover:-translate-y-0.5 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#3e5e45]"
                >
                  <Plus size={16} /> Add your first pet
                </button>
              </div>
            )}
          </EmptySection>

          <div className="grid gap-4 lg:grid-cols-2">
            <EmptySection title="Due and Overdue" icon={<CalendarDays size={18} />} action="View all" onAction={() => announce('There are no care events yet')} tint="#edf1e8">
              <div className="flex items-center gap-4">
                <SoftEmptyIcon><Check size={22} /></SoftEmptyIcon>
                <div>
                  <p className="font-medium text-[#304337]">Nothing needs your attention</p>
                  <p className="mt-1 text-[13px] leading-5 text-[#718074]">Care reminders will appear here once a pet is added.</p>
                </div>
              </div>
            </EmptySection>
            <EmptySection title="My Vets" icon={<Stethoscope size={18} />} action="Manage veterinarians" onAction={() => announce('Vet directory opened')} tint="#f3e7c3">
              <div className="flex items-center gap-4">
                <SoftEmptyIcon><Stethoscope size={21} /></SoftEmptyIcon>
                <div>
                  <p className="font-medium text-[#304337]">No vets connected</p>
                  <p className="mt-1 text-[13px] leading-5 text-[#718074]">Your care team can live here when you’re ready.</p>
                </div>
              </div>
            </EmptySection>
          </div>
        </div>
      </div>

      {showPetForm ? (
        <div className="fixed inset-0 z-40 grid place-items-center bg-[#24372b]/35 p-4" role="dialog" aria-modal="true" aria-labelledby="pet-dialog-title">
          <div className="w-full max-w-[420px] rounded-[24px] border border-[#dbe4d8] bg-[#fbfcf8] p-6 shadow-2xl">
            <div className="mb-6 flex items-start justify-between gap-4">
              <div>
                <p className="mb-1 text-[11px] font-bold uppercase tracking-[0.14em] text-[#718074]">First step</p>
                <h2 id="pet-dialog-title" className="text-xl font-semibold tracking-[-0.025em] text-[#26382b]">Who are you caring for?</h2>
              </div>
              <button type="button" onClick={() => setShowPetForm(false)} aria-label="Close add pet dialog" className="grid h-10 w-10 place-items-center rounded-xl text-[#6b7d6e] hover:bg-[#edf1e8]"><X size={18} /></button>
            </div>
            <label htmlFor="pet-name" className="mb-2 block text-[12px] font-semibold text-[#526657]">Pet name</label>
            <input
              id="pet-name"
              autoFocus
              value={petName}
              onChange={(event) => setPetName(event.target.value)}
              onKeyDown={(event) => { if (event.key === 'Enter') addPet(); }}
              placeholder="For example, Miso"
              className="h-12 w-full rounded-xl border border-[#cbd8c9] bg-[#f8faf6] px-3 text-sm text-[#26382b] outline-none placeholder:text-[#9aa79b] focus:border-[#5e7c65] focus:ring-2 focus:ring-[#dce9dd]"
            />
            <button type="button" onClick={addPet} className="mt-5 flex min-h-12 w-full items-center justify-center gap-2 rounded-xl bg-[#5e7c65] text-sm font-semibold text-white hover:bg-[#52715a] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#3e5e45]">
              <Plus size={17} /> Add pet
            </button>
          </div>
        </div>
      ) : null}

      {notice ? (
        <div className="fixed bottom-5 left-1/2 z-50 flex -translate-x-1/2 items-center gap-2 rounded-xl bg-[#304238] px-4 py-3 text-[13px] font-medium text-[#f3f6ef] shadow-xl" role="status">
          <Check size={15} className="text-[#c9ddc9]" />
          {notice}
        </div>
      ) : null}
    </main>
  );
}