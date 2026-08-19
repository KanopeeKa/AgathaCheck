import React, { useState } from 'react';
import {
  Bell,
  CalendarDays,
  Check,
  ChevronRight,
  Clock3,
  HeartPulse,
  Home,
  Menu,
  MoreHorizontal,
  PawPrint,
  Phone,
  Plus,
  Settings2,
  ShieldCheck,
  Stethoscope,
  X,
} from 'lucide-react';

// ─── Palette tokens (mirrors AppColorTokens) ────────────────────────────────
// guardianCarePrimary  = olive green – for guardian-care emphasis
// organizationOchre    = golden ochre – ONLY as org-context reserve
const C = {
  // surfaces
  bg: '#f1f3ee',
  surface: '#fbfcf8',
  surfaceVariant: '#eef0e9',

  // primary (olive guardian-care)
  primary: '#5e7c65',        // guardianCarePrimary
  primaryContainer: '#dde9de', // guardianCareLight
  onPrimaryContainer: '#2e5233', // guardianCareActive
  onPrimary: '#ffffff',

  // secondary (org ochre – reserve only)
  secondary: '#8b7226',      // organizationOchre
  secondaryContainer: '#f3e7c3', // organizationOchreLight
  onSecondaryContainer: '#3e3000',

  // neutrals
  outline: '#c5cec4',
  outlineVariant: '#dce4da',
  onSurface: '#1c2720',
  onSurfaceVariant: '#6b7a6e',

  // top-app-bar background
  topBar: '#f7f9f5',

  // overdue / due status (semantic, not warning)
  overdueBg: '#fdf2ee',
  overdueText: '#8b3a2b',
  dueBg: '#eef4ee',
  dueText: '#2e5233',

  // vet mark (org ochre accent)
  vetMark: '#f3e7c3',
  vetMarkText: '#7a6320',

  // toast
  toastBg: '#2e3d33',
};

// ─── Sample data ─────────────────────────────────────────────────────────────

type PetGroup = 'personal' | 'foster' | 'shared';
type Pet = {
  id: string;
  name: string;
  species: string;
  age: string;
  initials: string;
  color: string;
  status: string;
  wellness: number;
  group: PetGroup;
  vetId: string;
};

const PETS: Pet[] = [
  { id: 'p1', name: 'Miso', species: 'Shiba Inu', age: '4 yr', initials: 'MI', color: '#b78a5c', status: 'Doing well', wellness: 82, group: 'personal', vetId: 'v1' },
  { id: 'p2', name: 'Basil', species: 'Tabby cat', age: '2 yr', initials: 'BA', color: '#788e70', status: 'All caught up', wellness: 91, group: 'personal', vetId: 'v1' },
  { id: 'p3', name: 'Clover', species: 'Rabbit', age: '1 yr', initials: 'CL', color: '#a09ccb', status: 'Settling in', wellness: 74, group: 'foster', vetId: 'v2' },
];

type EventStatus = 'overdue' | 'due-today' | 'upcoming';
type DueEvent = {
  id: number;
  status: EventStatus;
  label: string;
  petName: string;
  detail: string;
  tag: string;
  done: boolean;
};

const INITIAL_EVENTS: DueEvent[] = [
  { id: 1, status: 'overdue',    label: 'Parasite prevention',  petName: 'Miso',   detail: 'Was due 10 May',          tag: 'OVERDUE', done: false },
  { id: 2, status: 'due-today',  label: 'Midday water check',   petName: 'Miso',   detail: 'Today · target 220 ml',   tag: 'DUE',     done: false },
  { id: 3, status: 'due-today',  label: 'Evening walk',         petName: 'Basil',  detail: 'Today · 20–30 min',       tag: 'DUE',     done: false },
  { id: 4, status: 'due-today',  label: 'Joint supplement',     petName: 'Miso',   detail: 'Today · 1 chew after dinner', tag: 'DUE', done: false },
  { id: 5, status: 'upcoming',   label: 'Annual wellness exam', petName: 'Basil',  detail: 'Thu 23 May · Cedar Grove', tag: 'VISIT',  done: false },
];

type Vet = { id: string; name: string; role: string; phone: string; initials: string; linkedPets: number };
const VETS: Vet[] = [
  { id: 'v1', name: 'Cedar Grove Veterinary', role: 'Primary care', phone: '(415) 555-0184', initials: 'CG', linkedPets: 2 },
  { id: 'v2', name: 'Dr Lena Ortiz', role: 'Dermatology · Miso', phone: '(415) 555-0127', initials: 'LO', linkedPets: 1 },
];

// ─── Sub-components ───────────────────────────────────────────────────────────

function SectionHeader({ title, linkLabel, onLink }: { title: string; linkLabel?: string; onLink?: () => void }) {
  return (
    <div className="fr-section-head">
      <span className="fr-section-title">{title}</span>
      {linkLabel && (
        <button className="fr-text-btn" onClick={onLink} aria-label={linkLabel}>
          {linkLabel}
          <ChevronRight size={13} className="fr-chevron" />
        </button>
      )}
    </div>
  );
}

function PetChip({ pet, active, onClick }: { pet: Pet; active: boolean; onClick: () => void }) {
  return (
    <button
      className={`fr-pet-chip ${active ? 'active' : ''}`}
      onClick={onClick}
      aria-pressed={active}
    >
      <span className="fr-pet-avatar" style={{ background: pet.color }}>{pet.initials}</span>
      <span className="fr-pet-info">
        <b>{pet.name}</b>
        <small>{pet.status}</small>
      </span>
    </button>
  );
}

function SubgroupTitle({ title }: { title: string }) {
  return <div className="fr-subgroup-title">{title}</div>;
}

function PetDetailCard({ pet, onClose }: { pet: Pet; onClose: () => void }) {
  return (
    <div className="fr-pet-detail" role="dialog" aria-label={`${pet.name} profile`}>
      <div className="fr-pet-detail-head">
        <span className="fr-pet-avatar lg" style={{ background: pet.color }}>{pet.initials}</span>
        <div>
          <div className="fr-pet-detail-name">{pet.name}</div>
          <div className="fr-pet-detail-meta">{pet.species} · {pet.age}</div>
          <div className="fr-pet-detail-status" style={{ color: C.primary }}>● {pet.status}</div>
        </div>
        <button className="fr-close-btn" onClick={onClose} aria-label="Close pet profile"><X size={16} /></button>
      </div>
      <div className="fr-wellness-row">
        <div>
          <div className="fr-label-tiny">Wellness signal</div>
          <div className="fr-wellness-score">{pet.wellness}<small> / 100</small></div>
          <div className="fr-label-tiny" style={{ marginTop: 2 }}>Steady this week</div>
        </div>
        <div className="fr-ring">
          <span className="fr-ring-inner">{pet.wellness}%</span>
        </div>
      </div>
      <div className="fr-wellness-bar">
        <div className="fr-wellness-bar-fill" style={{ width: `${pet.wellness}%` }} />
      </div>
    </div>
  );
}

function EventStatusBadge({ status }: { status: EventStatus }) {
  const map: Record<EventStatus, { label: string; cls: string }> = {
    overdue:    { label: 'OVERDUE', cls: 'fr-badge overdue' },
    'due-today': { label: 'DUE',    cls: 'fr-badge due' },
    upcoming:   { label: 'VISIT',   cls: 'fr-badge visit' },
  };
  const { label, cls } = map[status];
  return <span className={cls}>{label}</span>;
}

function EventRow({ event, onToggle }: { event: DueEvent; onToggle: () => void }) {
  return (
    <div className={`fr-event-row ${event.done ? 'done' : ''}`}>
      <EventStatusBadge status={event.status} />
      <div className="fr-event-body">
        <strong>{event.label}</strong>
        <span>{event.petName} · {event.detail}</span>
      </div>
      <button
        className={`fr-check-btn ${event.done ? 'checked' : ''}`}
        onClick={onToggle}
        aria-label={event.done ? `Reopen ${event.label}` : `Complete ${event.label}`}
      >
        {event.done && <Check size={13} />}
      </button>
    </div>
  );
}

function VetRow({ vet, onTap, onCall }: { vet: Vet; onTap: () => void; onCall: () => void }) {
  return (
    <div className="fr-vet-row">
      <button className="fr-vet-mark" onClick={onTap} aria-label={`Open ${vet.name}`}>{vet.initials}</button>
      <div className="fr-vet-body" onClick={onTap} style={{ cursor: 'pointer' }}>
        <strong>{vet.name}</strong>
        <span>{vet.role} · {vet.linkedPets} pet{vet.linkedPets !== 1 ? 's' : ''}</span>
      </div>
      <button className="fr-vet-action" onClick={onCall} aria-label={`Call ${vet.name}`}>
        <Phone size={14} />
      </button>
    </div>
  );
}

// ─── Section cards ────────────────────────────────────────────────────────────

function MyPetsSection({ onToast }: { onToast: (msg: string) => void }) {
  const [activePetId, setActivePetId] = useState<string | null>(null);

  const personalPets = PETS.filter(p => p.group === 'personal');
  const fosterPets   = PETS.filter(p => p.group === 'foster');
  const sharedPets   = PETS.filter(p => p.group === 'shared');
  const showPersonalSubgroup = personalPets.length > 0 && (fosterPets.length > 0 || sharedPets.length > 0);
  const detailPet = activePetId ? PETS.find(p => p.id === activePetId) : null;

  const handlePetTap = (pet: Pet) => {
    setActivePetId(prev => prev === pet.id ? null : pet.id);
    onToast(`${pet.name}'s profile opened`);
  };

  return (
    <div className="fr-card fr-card-primary">
      <SectionHeader title="My Pets" linkLabel="Manage pets" onLink={() => onToast('Pet manager opened')} />

      {detailPet && (
        <PetDetailCard pet={detailPet} onClose={() => setActivePetId(null)} />
      )}

      {showPersonalSubgroup && <SubgroupTitle title="My Pets" />}
      <div className="fr-pet-strip">
        {personalPets.map(pet => (
          <PetChip key={pet.id} pet={pet} active={activePetId === pet.id} onClick={() => handlePetTap(pet)} />
        ))}
      </div>

      {fosterPets.length > 0 && (
        <>
          <SubgroupTitle title="Fostered Pets" />
          <div className="fr-pet-strip">
            {fosterPets.map(pet => (
              <PetChip key={pet.id} pet={pet} active={activePetId === pet.id} onClick={() => handlePetTap(pet)} />
            ))}
          </div>
        </>
      )}

      {sharedPets.length > 0 && (
        <>
          <SubgroupTitle title="Shared Pets" />
          <div className="fr-pet-strip">
            {sharedPets.map(pet => (
              <PetChip key={pet.id} pet={pet} active={activePetId === pet.id} onClick={() => handlePetTap(pet)} />
            ))}
          </div>
        </>
      )}
    </div>
  );
}

function DueAndOverdueSection({ onToast }: { onToast: (msg: string) => void }) {
  const [events, setEvents] = useState(INITIAL_EVENTS);
  const [showComposer, setShowComposer] = useState(false);

  const toggleEvent = (id: number) => {
    setEvents(evs => evs.map(e => e.id === id ? { ...e, done: !e.done } : e));
    const ev = events.find(e => e.id === id);
    if (ev) onToast(ev.done ? 'Event reopened' : 'Event marked complete');
  };

  const remaining = events.filter(e => !e.done).length;

  return (
    <div className="fr-card">
      <SectionHeader
        title="Due and Overdue"
        linkLabel="All events"
        onLink={() => onToast('Full event list opened')}
      />
      <div className="fr-section-sub">{remaining} action{remaining !== 1 ? 's' : ''} pending</div>

      {events.map(ev => (
        <EventRow key={ev.id} event={ev} onToggle={() => toggleEvent(ev.id)} />
      ))}

      {showComposer ? (
        <div className="fr-composer">
          <input
            autoFocus
            placeholder="e.g. Flea treatment · Miso · 18:00"
            className="fr-composer-input"
            onKeyDown={e => {
              if (e.key === 'Enter') { setShowComposer(false); onToast('Event added'); }
              if (e.key === 'Escape') setShowComposer(false);
            }}
          />
          <button className="fr-composer-add" onClick={() => { setShowComposer(false); onToast('Event added'); }}>Add</button>
          <button className="fr-composer-cancel" onClick={() => setShowComposer(false)} aria-label="Cancel"><X size={13} /></button>
        </div>
      ) : (
        <button className="fr-add-btn" onClick={() => setShowComposer(true)}>
          <Plus size={14} className="fr-add-icon" /> Add an event
        </button>
      )}
    </div>
  );
}

function MyVetsSection({ onToast }: { onToast: (msg: string) => void }) {
  return (
    <div className="fr-card">
      <SectionHeader
        title="My Vets"
        linkLabel="Manage veterinarians"
        onLink={() => onToast('Vet directory opened')}
      />
      <div className="fr-section-sub">Care network · {VETS.length} contacts</div>

      {VETS.map(vet => (
        <VetRow
          key={vet.id}
          vet={vet}
          onTap={() => onToast(`${vet.name} profile opened`)}
          onCall={() => onToast(`Calling ${vet.name} · ${vet.phone}`)}
        />
      ))}
    </div>
  );
}

// ─── Shell + layout ───────────────────────────────────────────────────────────

export default function GuardianOperationsFlutterReady() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeNav, setActiveNav] = useState('Home');
  const [toast, setToast] = useState('');

  const showToast = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(''), 2400);
  };

  const navItems: [string, typeof Home][] = [
    ['Home', Home],
    ['Health log', HeartPulse],
    ['Appointments', CalendarDays],
    ['Pet profiles', PawPrint],
  ];

  return (
    <div className="fr-root">
      <style>{`
        /* ── Reset & root ── */
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        .fr-root {
          min-height: 100vh;
          background: ${C.bg};
          color: ${C.onSurface};
          font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
          font-size: 14px;
          display: flex;
          flex-direction: column;
          position: relative;
        }

        /* ── Top app bar (M3 compact) ── */
        .fr-topbar {
          height: 64px;
          background: ${C.topBar};
          border-bottom: 1px solid ${C.outlineVariant};
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 16px;
          gap: 8px;
          position: sticky;
          top: 0;
          z-index: 10;
        }
        .fr-topbar-left { display: flex; align-items: center; gap: 8px; }
        .fr-topbar-icon {
          width: 48px; height: 48px;
          display: grid; place-items: center;
          background: none; border: none;
          color: ${C.onSurface}; cursor: pointer;
          border-radius: 50%;
          transition: background 0.15s;
        }
        .fr-topbar-icon:hover, .fr-topbar-icon:focus-visible {
          background: rgba(30,50,35,0.08);
          outline: none;
        }
        .fr-topbar-icon:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }
        .fr-brand-mark {
          width: 32px; height: 32px;
          border-radius: 10px;
          background: ${C.primary};
          color: ${C.onPrimary};
          display: grid; place-items: center;
        }
        .fr-topbar-title {
          font-size: 22px;
          font-weight: 400;
          letter-spacing: 0;
          color: ${C.onSurface};
        }
        .fr-topbar-right { display: flex; align-items: center; gap: 4px; }
        .fr-nav-badge {
          position: relative;
        }
        .fr-nav-badge::after {
          content: '';
          position: absolute;
          top: 10px; right: 10px;
          width: 8px; height: 8px;
          border-radius: 50%;
          background: ${C.secondary};
          border: 2px solid ${C.topBar};
        }
        .fr-avatar-btn {
          width: 36px; height: 36px;
          border-radius: 50%;
          background: ${C.primary};
          color: ${C.onPrimary};
          border: none; cursor: pointer;
          font-size: 11px; font-weight: 700;
          display: grid; place-items: center;
          letter-spacing: .04em;
        }
        .fr-avatar-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

        /* ── Navigation drawer (mobile overlay) ── */
        .fr-drawer-overlay {
          position: fixed; inset: 0; background: rgba(0,0,0,.32); z-index: 20;
          animation: fr-fade-in 0.18s ease;
        }
        .fr-drawer {
          position: fixed; top: 0; left: 0; bottom: 0;
          width: 280px; background: #2e3e35;
          color: #edf0e8; padding: 0; z-index: 21;
          display: flex; flex-direction: column;
          animation: fr-slide-in 0.22s cubic-bezier(.32,.75,.5,1);
        }
        @keyframes fr-fade-in { from { opacity: 0 } to { opacity: 1 } }
        @keyframes fr-slide-in { from { transform: translateX(-100%) } to { transform: translateX(0) } }
        .fr-drawer-header {
          height: 64px; display: flex; align-items: center; gap: 12px; padding: 0 16px;
          border-bottom: 1px solid rgba(255,255,255,.08);
        }
        .fr-drawer-mark {
          width: 32px; height: 32px; border-radius: 10px;
          background: ${C.secondary}; color: ${C.onSecondaryContainer};
          display: grid; place-items: center;
        }
        .fr-drawer-app { font-size: 16px; font-weight: 600; letter-spacing: -.01em; }
        .fr-drawer-close {
          margin-left: auto; width: 40px; height: 40px;
          background: none; border: none; color: #c0c9c0; cursor: pointer;
          border-radius: 50%; display: grid; place-items: center;
        }
        .fr-drawer-section { padding: 12px 12px 4px; font-size: 11px; letter-spacing: .12em; text-transform: uppercase; color: #8e9e90; }
        .fr-drawer-nav {
          display: flex; align-items: center; gap: 12px;
          width: 100%; border: none; background: transparent;
          color: #c0c9c0; padding: 14px 16px; border-radius: 28px;
          text-align: left; font: 500 14px system-ui; cursor: pointer;
          margin: 1px 8px; width: calc(100% - 16px);
          transition: background 0.14s;
        }
        .fr-drawer-nav:hover { background: rgba(255,255,255,.06); }
        .fr-drawer-nav.active { background: ${C.primaryContainer}; color: ${C.onPrimaryContainer}; font-weight: 600; }
        .fr-drawer-nav.active svg { color: ${C.primary}; }
        .fr-drawer-foot {
          margin-top: auto; padding: 16px; border-top: 1px solid rgba(255,255,255,.08);
          display: flex; align-items: center; gap: 12px;
        }
        .fr-drawer-foot-name { font-size: 13px; font-weight: 600; }
        .fr-drawer-foot-role { font-size: 11px; color: #8e9e90; margin-top: 2px; }

        /* ── Scrollable content ── */
        .fr-scroll {
          flex: 1; overflow-y: auto;
          padding: 16px;
          display: flex; justify-content: center;
        }
        .fr-content {
          width: 100%; max-width: 1180px;
        }

        /* ── Welcome row ── */
        .fr-welcome {
          display: flex; align-items: flex-end; justify-content: space-between;
          gap: 12px; margin-bottom: 16px; flex-wrap: wrap;
        }
        .fr-welcome-kicker {
          font-size: 11px; font-weight: 700; letter-spacing: .12em;
          text-transform: uppercase; color: ${C.onSurfaceVariant}; margin-bottom: 6px;
        }
        .fr-welcome-h1 {
          font-size: clamp(24px, 3.5vw, 36px);
          font-weight: 400; letter-spacing: -.03em;
          color: ${C.onSurface}; line-height: 1.08;
        }
        .fr-welcome-h1 em { font-style: normal; color: ${C.primary}; }
        .fr-welcome-meta { font-size: 12px; color: ${C.onSurfaceVariant}; text-align: right; }
        .fr-welcome-meta b { display: block; color: ${C.onSurface}; font-weight: 600; font-size: 13px; }

        /* ── Section cards (M3 geometry) ── */
        .fr-card {
          background: ${C.surface};
          border: 1px solid ${C.outlineVariant};
          border-radius: 20px;
          padding: 20px 20px 6px;
          margin-bottom: 0;
        }
        .fr-card-primary {
          background: ${C.primaryContainer};
          border-color: ${C.outline};
        }

        /* ── Layout: pets top, secondary sections below ── */
        .fr-layout {
          display: flex; flex-direction: column; gap: 16px;
        }
        .fr-secondary {
          display: flex; flex-direction: column; gap: 16px;
        }
        @media (min-width: 900px) {
          .fr-secondary { flex-direction: row; }
          .fr-secondary > * { flex: 1; min-width: 0; }
        }

        /* ── Section header ── */
        .fr-section-head {
          display: flex; align-items: center; justify-content: space-between;
          margin-bottom: 10px;
        }
        .fr-section-title {
          font-size: 16px; font-weight: 600; letter-spacing: -.01em;
          color: ${C.onSurface};
        }
        .fr-section-sub {
          font-size: 12px; color: ${C.onSurfaceVariant};
          margin-bottom: 12px; margin-top: -6px;
        }

        /* ── Text button (M3 TextButton) ── */
        .fr-text-btn {
          display: inline-flex; align-items: center; gap: 2px;
          min-height: 48px; min-width: 48px; padding: 0 4px;
          background: none; border: none;
          color: ${C.primary}; font: 600 13px system-ui; cursor: pointer;
          border-radius: 8px;
          transition: background 0.15s;
        }
        .fr-text-btn:hover, .fr-text-btn:focus-visible {
          background: ${C.primaryContainer};
          outline: none;
        }
        .fr-text-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 1px; }
        .fr-chevron { flex-shrink: 0; }

        /* ── Subgroup title ── */
        .fr-subgroup-title {
          font-size: 12px; font-weight: 600; letter-spacing: .01em;
          color: ${C.onSurfaceVariant}; padding-bottom: 8px;
        }

        /* ── Pet chip strip ── */
        .fr-pet-strip {
          display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px;
        }
        .fr-pet-chip {
          display: flex; align-items: center; gap: 10px;
          min-height: 48px; padding: 8px 14px 8px 8px;
          background: ${C.surface}; border: 1px solid ${C.outlineVariant};
          border-radius: 14px; cursor: pointer; text-align: left;
          font: 500 13px system-ui; color: ${C.onSurface};
          transition: background 0.14s, border-color 0.14s;
        }
        .fr-pet-chip:hover { background: ${C.surfaceVariant}; }
        .fr-pet-chip.active {
          background: ${C.surface};
          border-color: ${C.primary};
          box-shadow: 0 0 0 2px ${C.primary}22;
        }
        .fr-pet-chip:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }
        .fr-pet-chip b { display: block; font-size: 13px; font-weight: 600; }
        .fr-pet-chip small { display: block; font-size: 11px; color: ${C.onSurfaceVariant}; margin-top: 2px; }

        .fr-pet-avatar {
          width: 36px; height: 36px; border-radius: 12px;
          display: grid; place-items: center;
          color: #fff; font-size: 10px; font-weight: 700; letter-spacing: .04em;
          flex-shrink: 0;
        }
        .fr-pet-avatar.lg {
          width: 52px; height: 52px; border-radius: 16px; font-size: 14px;
        }

        /* ── Pet detail card ── */
        .fr-pet-detail {
          background: ${C.surface};
          border: 1px solid ${C.outlineVariant};
          border-radius: 16px;
          padding: 16px;
          margin-bottom: 14px;
          position: relative;
        }
        .fr-pet-detail-head {
          display: flex; align-items: flex-start; gap: 14px; margin-bottom: 14px;
        }
        .fr-pet-detail-name { font-size: 20px; font-weight: 600; letter-spacing: -.03em; }
        .fr-pet-detail-meta { font-size: 12px; color: ${C.onSurfaceVariant}; margin-top: 3px; }
        .fr-pet-detail-status { font-size: 12px; margin-top: 4px; }
        .fr-close-btn {
          margin-left: auto; width: 40px; height: 40px;
          border: none; background: none; cursor: pointer;
          color: ${C.onSurfaceVariant}; border-radius: 50%;
          display: grid; place-items: center;
          flex-shrink: 0;
          transition: background 0.14s;
        }
        .fr-close-btn:hover { background: ${C.surfaceVariant}; }
        .fr-close-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

        .fr-wellness-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
        .fr-label-tiny { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .1em; color: ${C.onSurfaceVariant}; margin-bottom: 4px; }
        .fr-wellness-score { font-size: 30px; font-weight: 700; letter-spacing: -.05em; color: ${C.onSurface}; }
        .fr-wellness-score small { font-size: 13px; color: ${C.onSurfaceVariant}; font-weight: 400; letter-spacing: 0; }

        .fr-ring {
          width: 64px; height: 64px; border-radius: 50%;
          background: conic-gradient(${C.primary} 0 82%, ${C.outlineVariant} 82%);
          display: grid; place-items: center; position: relative;
        }
        .fr-ring::after {
          content: ''; position: absolute; inset: 7px;
          border-radius: 50%; background: ${C.surface};
        }
        .fr-ring-inner {
          position: relative; z-index: 1;
          font-size: 12px; font-weight: 700; color: ${C.primary};
        }
        .fr-wellness-bar {
          height: 4px; border-radius: 8px; background: ${C.outlineVariant}; overflow: hidden;
        }
        .fr-wellness-bar-fill { height: 100%; background: ${C.primary}; border-radius: 8px; transition: width 0.5s ease; }

        /* ── Due & Overdue event rows ── */
        .fr-event-row {
          display: grid;
          grid-template-columns: 68px 1fr 44px;
          align-items: center; gap: 10px;
          border-top: 1px solid ${C.outlineVariant};
          padding: 12px 0;
        }
        .fr-event-row.done strong { text-decoration: line-through; color: ${C.onSurfaceVariant}; }
        .fr-event-body strong { display: block; font-size: 13px; font-weight: 600; color: ${C.onSurface}; }
        .fr-event-body span { display: block; font-size: 11px; color: ${C.onSurfaceVariant}; margin-top: 2px; }

        .fr-badge {
          display: inline-block; padding: 4px 6px;
          border-radius: 6px; font-size: 9px; font-weight: 700;
          letter-spacing: .08em; text-transform: uppercase;
          white-space: nowrap;
        }
        .fr-badge.overdue { background: ${C.overdueBg}; color: ${C.overdueText}; }
        .fr-badge.due     { background: ${C.dueBg};     color: ${C.dueText}; }
        .fr-badge.visit   { background: ${C.secondaryContainer}; color: ${C.secondary}; }

        .fr-check-btn {
          width: 44px; height: 44px;
          border: 1px solid ${C.outlineVariant};
          border-radius: 12px; background: ${C.surface};
          color: transparent; display: grid; place-items: center;
          cursor: pointer; flex-shrink: 0;
          transition: background 0.14s, border-color 0.14s;
        }
        .fr-check-btn.checked { background: ${C.primary}; border-color: ${C.primary}; color: #fff; }
        .fr-check-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

        /* ── Composer ── */
        .fr-add-btn {
          display: flex; align-items: center; gap: 6px;
          width: calc(100% - 0px); margin: 8px 0;
          min-height: 48px; padding: 0 16px;
          border: 1px dashed ${C.outline};
          border-radius: 12px; background: transparent;
          color: ${C.onSurfaceVariant}; font: 500 13px system-ui; cursor: pointer;
          transition: background 0.14s;
        }
        .fr-add-btn:hover { background: ${C.primaryContainer}; }
        .fr-add-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }
        .fr-add-icon { color: ${C.primary}; flex-shrink: 0; }

        .fr-composer {
          display: flex; gap: 8px; align-items: center;
          border-top: 1px solid ${C.outlineVariant}; padding: 10px 0 4px;
          margin-top: 4px;
        }
        .fr-composer-input {
          flex: 1; min-width: 0;
          height: 44px; padding: 0 12px;
          border: 1px solid ${C.outline}; border-radius: 12px;
          background: ${C.surface}; font: 13px system-ui;
          color: ${C.onSurface}; outline: none;
        }
        .fr-composer-input:focus { border-color: ${C.primary}; box-shadow: 0 0 0 2px ${C.primary}22; }
        .fr-composer-add {
          height: 44px; padding: 0 16px;
          background: ${C.primary}; color: #fff;
          border: none; border-radius: 12px;
          font: 600 13px system-ui; cursor: pointer;
        }
        .fr-composer-cancel {
          width: 44px; height: 44px;
          background: ${C.surfaceVariant}; color: ${C.onSurfaceVariant};
          border: none; border-radius: 12px; cursor: pointer;
          display: grid; place-items: center;
        }

        /* ── Vet rows ── */
        .fr-vet-row {
          display: grid;
          grid-template-columns: 44px 1fr 44px;
          align-items: center; gap: 12px;
          border-top: 1px solid ${C.outlineVariant};
          padding: 12px 0;
        }
        .fr-vet-mark {
          width: 44px; height: 44px;
          border-radius: 14px;
          background: ${C.vetMark}; color: ${C.vetMarkText};
          font: 700 11px system-ui; letter-spacing: .04em;
          display: grid; place-items: center;
          border: none; cursor: pointer;
          transition: opacity 0.14s;
        }
        .fr-vet-mark:hover { opacity: .8; }
        .fr-vet-mark:focus-visible { outline: 2px solid ${C.secondary}; outline-offset: 2px; }
        .fr-vet-body strong { display: block; font-size: 13px; font-weight: 600; color: ${C.onSurface}; }
        .fr-vet-body span { display: block; font-size: 11px; color: ${C.onSurfaceVariant}; margin-top: 2px; }
        .fr-vet-action {
          width: 44px; height: 44px;
          border-radius: 12px;
          background: ${C.primaryContainer}; color: ${C.primary};
          border: none; cursor: pointer;
          display: grid; place-items: center;
          transition: background 0.14s;
        }
        .fr-vet-action:hover { background: ${C.outline}; }
        .fr-vet-action:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

        /* ── Toast ── */
        .fr-toast {
          position: fixed; bottom: 20px; left: 50%;
          transform: translateX(-50%);
          background: ${C.toastBg}; color: #fff;
          padding: 11px 16px; border-radius: 12px;
          font-size: 12px; font-weight: 500;
          display: flex; align-items: center; gap: 8px;
          z-index: 100; pointer-events: none;
          white-space: nowrap;
          box-shadow: 0 6px 20px rgba(0,0,0,.25);
          animation: fr-toast-in 0.2s ease;
        }
        @keyframes fr-toast-in { from { opacity: 0; transform: translateX(-50%) translateY(8px); } to { opacity: 1; transform: translateX(-50%) translateY(0); } }

        /* ── Responsive ── */
        @media (max-width: 480px) {
          .fr-welcome-meta { display: none; }
          .fr-event-row { grid-template-columns: 60px 1fr 44px; }
        }
      `}</style>

      {/* Top App Bar */}
      <header className="fr-topbar">
        <div className="fr-topbar-left">
          <button
            className="fr-topbar-icon"
            onClick={() => setMenuOpen(true)}
            aria-label="Open navigation menu"
          >
            <Menu size={24} />
          </button>
          <div className="fr-brand-mark" aria-hidden="true">
            <PawPrint size={17} />
          </div>
          <span className="fr-topbar-title">AgathaTrack</span>
        </div>
        <div className="fr-topbar-right">
          <button
            className="fr-topbar-icon fr-nav-badge"
            onClick={() => showToast('No new notifications')}
            aria-label="Notifications"
          >
            <Bell size={22} />
          </button>
          <button
            className="fr-avatar-btn"
            onClick={() => showToast('Profile menu opened')}
            aria-label="Open profile menu"
          >
            JM
          </button>
        </div>
      </header>

      {/* Navigation drawer */}
      {menuOpen && (
        <>
          <div className="fr-drawer-overlay" onClick={() => setMenuOpen(false)} />
          <nav className="fr-drawer" aria-label="Main navigation">
            <div className="fr-drawer-header">
              <div className="fr-drawer-mark"><PawPrint size={16} /></div>
              <span className="fr-drawer-app">AgathaTrack</span>
              <button className="fr-drawer-close" onClick={() => setMenuOpen(false)} aria-label="Close navigation">
                <X size={20} />
              </button>
            </div>
            <div className="fr-drawer-section">Guardian desk</div>
            {navItems.map(([label, Icon]) => (
              <button
                key={label}
                className={`fr-drawer-nav ${activeNav === label ? 'active' : ''}`}
                onClick={() => { setActiveNav(label); setMenuOpen(false); showToast(`${label} selected`); }}
              >
                <Icon size={20} strokeWidth={1.8} />
                {label}
              </button>
            ))}
            <div className="fr-drawer-section" style={{ marginTop: 12 }}>Account</div>
            <button className="fr-drawer-nav" onClick={() => { setMenuOpen(false); showToast('Settings opened'); }}>
              <Settings2 size={20} strokeWidth={1.8} />
              Settings
            </button>
            <div className="fr-drawer-foot">
              <div className="fr-pet-avatar" style={{ background: C.primary, width: 40, height: 40, borderRadius: '50%' }}>JM</div>
              <div>
                <div className="fr-drawer-foot-name">Jordan Miller</div>
                <div className="fr-drawer-foot-role">Guardian account</div>
              </div>
            </div>
          </nav>
        </>
      )}

      {/* Scrollable main content */}
      <main className="fr-scroll">
        <div className="fr-content">

          {/* Welcome row */}
          <div className="fr-welcome">
            <div>
              <div className="fr-welcome-kicker">
                <ShieldCheck size={11} style={{ verticalAlign: '-1px', marginRight: 4, color: C.primary }} />
                Tuesday · 14 May 2024 · Guardian view
              </div>
              <h1 className="fr-welcome-h1">Good morning, <em>Jordan.</em></h1>
            </div>
            <div className="fr-welcome-meta">
              <b>3 items to review</b>
              Miso's care plan · last synced 09:42
            </div>
          </div>

          {/* Three sections */}
          <div className="fr-layout">
            {/* My Pets — emphasized primary card */}
            <MyPetsSection onToast={showToast} />

            {/* Secondary: Due & Overdue + My Vets (side-by-side on wide) */}
            <div className="fr-secondary">
              <DueAndOverdueSection onToast={showToast} />
              <MyVetsSection onToast={showToast} />
            </div>
          </div>

        </div>
      </main>

      {/* Toast */}
      {toast && (
        <div className="fr-toast" role="status" aria-live="polite">
          <Clock3 size={13} style={{ color: C.secondary, flexShrink: 0 }} />
          {toast}
        </div>
      )}
    </div>
  );
}
