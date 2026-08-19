import React, { useMemo, useState } from 'react';
import {
  ArrowLeft,
  CalendarDays,
  Check,
  ChevronRight,
  HeartPulse,
  Menu,
  Phone,
  Plus,
  ShieldCheck,
  Stethoscope,
  X,
} from 'lucide-react';

type Pet = {
  id: string;
  name: string;
  species: string;
  age: string;
  initials: string;
  color: string;
  status: string;
  wellness: number;
  next: string;
  vet: string;
};

type CareItem = {
  id: number;
  title: string;
  detail: string;
  kind: 'due' | 'overdue' | 'visit';
  completed: boolean;
};

const pets: Pet[] = [
  { id: 'miso', name: 'Miso', species: 'Shiba Inu', age: '4 years', initials: 'MI', color: '#b77d55', status: 'Doing well', wellness: 82, next: 'Parasite prevention', vet: 'Cedar Grove Veterinary' },
  { id: 'basil', name: 'Basil', species: 'Tabby cat', age: '2 years', initials: 'BA', color: '#758d78', status: 'All caught up', wellness: 91, next: 'Evening walk', vet: 'Cedar Grove Veterinary' },
  { id: 'clover', name: 'Clover', species: 'Rabbit', age: '1 year', initials: 'CL', color: '#958bba', status: 'Settling in', wellness: 74, next: 'Weight check', vet: 'Dr Lena Ortiz' },
];

const initialCare: CareItem[] = [
  { id: 1, title: 'Parasite prevention', detail: 'Was due 10 May · Miso', kind: 'overdue', completed: false },
  { id: 2, title: 'Midday water check', detail: 'Today · target 220 ml · Miso', kind: 'due', completed: false },
  { id: 3, title: 'Evening walk', detail: 'Today · 20–30 min · Basil', kind: 'due', completed: false },
  { id: 4, title: 'Annual wellness exam', detail: 'Thu 23 May · Cedar Grove · Basil', kind: 'visit', completed: false },
];

const vets = [
  { initials: 'CG', name: 'Cedar Grove Veterinary', role: 'Primary care · 2 pets', phone: '(415) 555-0184' },
  { initials: 'LO', name: 'Dr Lena Ortiz', role: 'Dermatology · 1 pet', phone: '(415) 555-0127' },
];

function PetAvatar({ pet, large = false }: { pet: Pet; large?: boolean }) {
  return (
    <span
      className={`grid shrink-0 place-items-center font-bold tracking-[.05em] text-white ${large ? 'h-16 w-16 rounded-[18px] text-base' : 'h-10 w-10 rounded-[13px] text-[11px]'}`}
      style={{ backgroundColor: pet.color }}
      aria-hidden="true"
    >
      {pet.initials}
    </span>
  );
}

function SectionTitle({ title, action, onAction }: { title: string; action: string; onAction: () => void }) {
  return (
    <div className="mb-3 flex items-center justify-between gap-3">
      <h2 className="text-[17px] font-semibold tracking-[-0.02em] text-[#1f2c24]">{title}</h2>
      <button onClick={onAction} className="inline-flex min-h-11 items-center gap-1 rounded-lg px-2 text-[13px] font-semibold text-[#55745e] transition hover:bg-[#e1ebdf] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]" type="button">
        {action}<ChevronRight size={14} />
      </button>
    </div>
  );
}

function StatusPill({ kind }: { kind: CareItem['kind'] }) {
  const styles = {
    overdue: 'bg-[#fdf1ed] text-[#8b3a2b]',
    due: 'bg-[#e8f1e7] text-[#34583d]',
    visit: 'bg-[#f3e7c3] text-[#75601f]',
  };
  const label = kind === 'overdue' ? 'OVERDUE' : kind === 'visit' ? 'VISIT' : 'DUE';
  return <span className={`rounded-md px-2 py-1 text-[9px] font-bold tracking-[.1em] ${styles[kind]}`}>{label}</span>;
}

export function GuardianOperationsExpandedPet() {
  const [selectedPetId, setSelectedPetId] = useState<string | null>('miso');
  const [care, setCare] = useState(initialCare);
  const [toast, setToast] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);
  const [note, setNote] = useState('');
  const selectedPet = useMemo(() => pets.find((pet) => pet.id === selectedPetId) ?? pets[0], [selectedPetId]);

  const announce = (message: string) => {
    setToast(message);
    window.setTimeout(() => setToast(''), 2400);
  };

  const toggleCare = (id: number) => {
    setCare((items) => items.map((item) => (item.id === id ? { ...item, completed: !item.completed } : item)));
    const item = care.find((entry) => entry.id === id);
    if (item) announce(item.completed ? 'Care item reopened' : 'Care item marked complete');
  };

  return (
    <main className="min-h-[100dvh] bg-[#eef1eb] font-sans text-[#1f2c24]">
      <header className="sticky top-0 z-20 border-b border-[#d8e1d6] bg-[#f7f9f4]/95 px-4 backdrop-blur md:px-8">
        <div className="mx-auto flex h-16 max-w-[1180px] items-center justify-between">
          <div className="flex items-center gap-3">
            <button type="button" aria-label="Open navigation" onClick={() => setMenuOpen(true)} className="grid h-11 w-11 place-items-center rounded-full transition hover:bg-[#e4ebe1] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]">
              <Menu size={21} />
            </button>
            <div className="grid h-9 w-9 place-items-center rounded-xl bg-[#5e7c65] text-white"><HeartPulse size={19} /></div>
            <span className="text-[20px] tracking-[-0.03em]">Agatha Track</span>
          </div>
          <button type="button" onClick={() => announce('Profile settings opened')} className="grid h-10 w-10 place-items-center rounded-full bg-[#5e7c65] text-xs font-bold tracking-wide text-white focus:outline-none focus:ring-2 focus:ring-[#5e7c65]" aria-label="Open profile settings">AR</button>
        </div>
      </header>

      {menuOpen && (
        <div className="fixed inset-0 z-40 bg-[#1f2c24]/30" onClick={() => setMenuOpen(false)}>
          <aside onClick={(event) => event.stopPropagation()} className="flex h-full w-[290px] flex-col bg-[#2f4035] p-5 text-[#edf1e9] shadow-xl">
            <div className="flex items-center justify-between border-b border-white/10 pb-5">
              <span className="font-semibold">Agatha Track</span>
              <button type="button" onClick={() => setMenuOpen(false)} aria-label="Close navigation" className="grid h-10 w-10 place-items-center rounded-full hover:bg-white/10"><X size={19} /></button>
            </div>
            <p className="mt-7 text-[10px] font-bold uppercase tracking-[.16em] text-[#9aa99d]">Workspace</p>
            <button type="button" onClick={() => { setMenuOpen(false); announce('Operations Desk selected'); }} className="mt-3 flex min-h-12 items-center gap-3 rounded-full bg-[#dde9de] px-4 text-left text-sm font-semibold text-[#2e5233]"><HeartPulse size={18} /> Operations Desk</button>
            <button type="button" onClick={() => { setMenuOpen(false); announce('Health log opened'); }} className="mt-1 flex min-h-12 items-center gap-3 rounded-full px-4 text-left text-sm text-[#d4ddd4] hover:bg-white/10"><CalendarDays size={18} /> Health log</button>
            <button type="button" onClick={() => { setMenuOpen(false); announce('Appointments opened'); }} className="flex min-h-12 items-center gap-3 rounded-full px-4 text-left text-sm text-[#d4ddd4] hover:bg-white/10"><Stethoscope size={18} /> Appointments</button>
            <div className="mt-auto border-t border-white/10 pt-5 text-xs text-[#9aa99d]">Signed in as <strong className="text-[#edf1e9]">Ari Rivera</strong></div>
          </aside>
        </div>
      )}

      <div className="mx-auto max-w-[1180px] px-4 py-7 md:px-8 md:py-10">
        <div className="mb-7 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="mb-2 text-[11px] font-bold uppercase tracking-[.16em] text-[#6c7b70]">Tuesday, 14 May</p>
            <h1 className="text-[clamp(28px,4vw,39px)] font-normal leading-[1.05] tracking-[-.045em]">Good morning, Ari<span className="text-[#5e7c65]">.</span></h1>
          </div>
          <div className="text-right text-xs text-[#6c7b70]"><strong className="block text-sm font-semibold text-[#1f2c24]">Your care overview</strong>3 pets · 4 actions in view</div>
        </div>

        <div className="flex flex-col gap-4">
          <section className="rounded-[22px] border border-[#c9d8c8] bg-[#dce9dc] p-5 md:p-6">
            <SectionTitle title="My Pets" action="Manage pets" onAction={() => announce('Pet manager opened')} />
            {selectedPetId && <div className="mb-4 rounded-[18px] border border-[#c5d6c5] bg-[#fbfcf8] p-4 md:p-5">
              <div className="flex items-start gap-3">
                <PetAvatar pet={selectedPet} large />
                <div className="min-w-0">
                  <p className="text-[22px] font-semibold tracking-[-.035em]">{selectedPet.name}</p>
                  <p className="mt-1 text-xs text-[#6c7b70]">{selectedPet.species} · {selectedPet.age}</p>
                  <p className="mt-2 flex items-center gap-1.5 text-xs font-semibold text-[#55745e]"><span className="h-2 w-2 rounded-full bg-[#5e7c65]" />{selectedPet.status}</p>
                </div>
                <button type="button" onClick={() => { setSelectedPetId(null); announce('Pet detail collapsed'); }} className="ml-auto inline-flex min-h-11 shrink-0 items-center gap-1 rounded-lg px-2 text-xs font-semibold text-[#55745e] hover:bg-[#e7f0e5] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]"><ArrowLeft size={15} /> <span className="hidden sm:inline">Back to pets</span><span className="sm:hidden">Back</span></button>
              </div>
              <div className="mt-5 grid gap-4 border-t border-[#e0e8dd] pt-4 sm:grid-cols-[1fr_auto] sm:items-end">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-[.13em] text-[#718074]">Wellness signal</p>
                  <div className="mt-1 flex items-baseline gap-1"><strong className="text-[31px] tracking-[-.06em]">{selectedPet.wellness}</strong><span className="text-sm text-[#718074]">/ 100</span></div>
                  <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-[#dce6da]"><div className="h-full rounded-full bg-[#5e7c65] transition-all duration-500" style={{ width: `${selectedPet.wellness}%` }} /></div>
                  <p className="mt-2 text-xs text-[#6c7b70]">Steady this week · next: {selectedPet.next}</p>
                </div>
                <div className="flex gap-2">
                  <button type="button" onClick={() => announce(`Health log for ${selectedPet.name} opened`)} className="inline-flex min-h-11 items-center gap-2 rounded-xl bg-[#5e7c65] px-3 text-xs font-semibold text-white transition hover:bg-[#4d6b55] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]"><HeartPulse size={15} /> Health log</button>
                  <button type="button" onClick={() => announce(`Appointment options for ${selectedPet.name} opened`)} className="grid h-11 w-11 place-items-center rounded-xl border border-[#b9cdb9] bg-[#f7faf5] text-[#55745e] hover:bg-[#edf4eb] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]" aria-label={`Open appointments for ${selectedPet.name}`}><CalendarDays size={16} /></button>
                </div>
              </div>
              <div className="mt-4 rounded-xl bg-[#f1f5ef] px-3 py-3 text-xs text-[#526257]"><span className="font-semibold text-[#2e5233]">Care note</span><span className="mx-2 text-[#a1b2a2]">·</span>Keep water bowl near the cool tile after midday walks.</div>
            </div>}
            <div className="flex flex-wrap gap-2">
              {pets.map((pet) => (
                <button key={pet.id} type="button" aria-pressed={selectedPetId === pet.id} onClick={() => { setSelectedPetId(pet.id); announce(`${pet.name}'s care record opened`); }} className={`flex min-h-12 items-center gap-2 rounded-[14px] border px-3 py-2 text-left transition focus:outline-none focus:ring-2 focus:ring-[#5e7c65] ${selectedPetId === pet.id ? 'border-[#5e7c65] bg-[#fbfcf8] shadow-[0_0_0_2px_rgba(94,124,101,.12)]' : 'border-[#c9d8c8] bg-[#edf3ea] hover:bg-[#f5f8f2]'}`}>
                  <PetAvatar pet={pet} /><span><strong className="block text-xs">{pet.name}</strong><small className="block text-[11px] text-[#6c7b70]">{pet.status}</small></span>
                </button>
              ))}
            </div>
            <button type="button" onClick={() => announce('Add pet form opened')} className="mt-3 inline-flex min-h-11 items-center gap-2 rounded-xl px-2 text-xs font-semibold text-[#55745e] hover:bg-[#e5efe3] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]"><Plus size={15} /> Add a pet</button>
          </section>

          <div className="grid gap-4 lg:grid-cols-2">
            <section className="rounded-[22px] border border-[#d7e1d5] bg-[#fbfcf8] p-5 md:p-6">
              <SectionTitle title="Due and Overdue" action="All events" onAction={() => announce('Full event list opened')} />
              <p className="mb-2 text-xs text-[#6c7b70]">{care.filter((item) => !item.completed).length} actions pending</p>
              {care.map((item) => (
                <div key={item.id} className={`grid grid-cols-[auto_1fr_auto] items-center gap-3 border-t border-[#e1e7df] py-3 ${item.completed ? 'opacity-55' : ''}`}>
                  <StatusPill kind={item.kind} />
                  <div className="min-w-0"><p className={`truncate text-[13px] font-semibold ${item.completed ? 'line-through' : ''}`}>{item.title}</p><p className="mt-1 truncate text-[11px] text-[#6c7b70]">{item.detail}</p></div>
                  <button type="button" onClick={() => toggleCare(item.id)} aria-label={item.completed ? `Reopen ${item.title}` : `Mark ${item.title} complete`} className={`grid h-11 w-11 place-items-center rounded-xl border transition focus:outline-none focus:ring-2 focus:ring-[#5e7c65] ${item.completed ? 'border-[#5e7c65] bg-[#5e7c65] text-white' : 'border-[#d2ddd0] bg-[#fbfcf8] text-transparent hover:border-[#5e7c65]'}`}><Check size={15} /></button>
                </div>
              ))}
              <div className="mt-2 flex gap-2 border-t border-[#e1e7df] pt-3">
                <input value={note} onChange={(event) => setNote(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter' && note.trim()) { announce('Care item added'); setNote(''); } }} placeholder="Add a care reminder" className="min-h-11 min-w-0 flex-1 rounded-xl border border-[#d2ddd0] bg-[#f7faf5] px-3 text-xs outline-none placeholder:text-[#89968b] focus:border-[#5e7c65] focus:ring-2 focus:ring-[#dce9dc]" />
                <button type="button" onClick={() => { if (note.trim()) { announce('Care item added'); setNote(''); } }} className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-[#e1ebdf] text-[#55745e] hover:bg-[#d4e5d2] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]" aria-label="Add care reminder"><Plus size={17} /></button>
              </div>
            </section>

            <section className="rounded-[22px] border border-[#d7e1d5] bg-[#fbfcf8] p-5 md:p-6">
              <SectionTitle title="My Vets" action="Manage veterinarians" onAction={() => announce('Vet directory opened')} />
              <p className="mb-2 text-xs text-[#6c7b70]">Care network · {vets.length} contacts</p>
              {vets.map((vet) => (
                <div key={vet.name} className="flex items-center gap-3 border-t border-[#e1e7df] py-3">
                  <button type="button" onClick={() => announce(`${vet.name} profile opened`)} className="grid h-11 w-11 shrink-0 place-items-center rounded-[14px] bg-[#f3e7c3] text-xs font-bold text-[#75601f] focus:outline-none focus:ring-2 focus:ring-[#8b7226]">{vet.initials}</button>
                  <button type="button" onClick={() => announce(`${vet.name} profile opened`)} className="min-w-0 flex-1 text-left"><strong className="block truncate text-[13px]">{vet.name}</strong><span className="mt-1 block text-[11px] text-[#6c7b70]">{vet.role}</span></button>
                  <button type="button" onClick={() => announce(`Calling ${vet.name} at ${vet.phone}`)} aria-label={`Call ${vet.name}`} className="grid h-11 w-11 shrink-0 place-items-center rounded-xl border border-[#d2ddd0] text-[#55745e] hover:bg-[#e8f1e7] focus:outline-none focus:ring-2 focus:ring-[#5e7c65]"><Phone size={16} /></button>
                </div>
              ))}
              <div className="mt-2 flex items-start gap-2 rounded-xl bg-[#f6f0dc] px-3 py-3 text-xs text-[#75601f]"><ShieldCheck size={15} className="mt-0.5 shrink-0" /><span>Vet details are shared only with your care circle.</span></div>
            </section>
          </div>
        </div>
      </div>

      {toast && <div role="status" aria-live="polite" className="fixed bottom-5 left-1/2 z-50 -translate-x-1/2 rounded-xl bg-[#2e3d33] px-4 py-3 text-xs font-semibold text-white shadow-lg">{toast}</div>}
    </main>
  );
}

export default GuardianOperationsExpandedPet;