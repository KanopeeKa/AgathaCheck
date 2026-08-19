import React, { useState } from 'react';
import { Check, ChevronRight, Phone, Plus, X } from 'lucide-react';
import { C } from './GuardianOperationsStyles';

// ─── Data types ───────────────────────────────────────────────────────────────

export type PetGroup = 'personal' | 'foster' | 'shared';
export type Pet = {
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

export const PETS: Pet[] = [
  { id: 'p1', name: 'Miso',   species: 'Shiba Inu', age: '4 yr', initials: 'MI', color: '#b78a5c', status: 'Doing well',    wellness: 82, group: 'personal', vetId: 'v1' },
  { id: 'p2', name: 'Basil',  species: 'Tabby cat', age: '2 yr', initials: 'BA', color: '#788e70', status: 'All caught up', wellness: 91, group: 'personal', vetId: 'v1' },
  { id: 'p3', name: 'Clover', species: 'Rabbit',    age: '1 yr', initials: 'CL', color: '#a09ccb', status: 'Settling in',   wellness: 74, group: 'foster',   vetId: 'v2' },
];

export type EventStatus = 'overdue' | 'due-today' | 'upcoming';
export type DueEvent = {
  id: number;
  status: EventStatus;
  label: string;
  petName: string;
  detail: string;
  tag: string;
  done: boolean;
};

export const INITIAL_EVENTS: DueEvent[] = [
  { id: 1, status: 'overdue',   label: 'Parasite prevention',  petName: 'Miso',  detail: 'Was due 10 May',              tag: 'OVERDUE', done: false },
  { id: 2, status: 'due-today', label: 'Midday water check',   petName: 'Miso',  detail: 'Today · target 220 ml',       tag: 'DUE',     done: false },
  { id: 3, status: 'due-today', label: 'Evening walk',         petName: 'Basil', detail: 'Today · 20–30 min',           tag: 'DUE',     done: false },
  { id: 4, status: 'due-today', label: 'Joint supplement',     petName: 'Miso',  detail: 'Today · 1 chew after dinner', tag: 'DUE',     done: false },
  { id: 5, status: 'upcoming',  label: 'Annual wellness exam', petName: 'Basil', detail: 'Thu 23 May · Cedar Grove',    tag: 'VISIT',   done: false },
];

export type Vet = { id: string; name: string; role: string; phone: string; initials: string; linkedPets: number };
export const VETS: Vet[] = [
  { id: 'v1', name: 'Cedar Grove Veterinary', role: 'Primary care',       phone: '(415) 555-0184', initials: 'CG', linkedPets: 2 },
  { id: 'v2', name: 'Dr Lena Ortiz',          role: 'Dermatology · Miso', phone: '(415) 555-0127', initials: 'LO', linkedPets: 1 },
];

// ─── Primitive sub-components ─────────────────────────────────────────────────

export function SectionHeader({ title, linkLabel, onLink }: { title: string; linkLabel?: string; onLink?: () => void }) {
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

export function SubgroupTitle({ title }: { title: string }) {
  return <div className="fr-subgroup-title">{title}</div>;
}

export function PetChip({ pet, active, onClick }: { pet: Pet; active: boolean; onClick: () => void }) {
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

export function PetDetailCard({ pet, onClose }: { pet: Pet; onClose: () => void }) {
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

export function EventStatusBadge({ status }: { status: EventStatus }) {
  const map: Record<EventStatus, { label: string; cls: string }> = {
    overdue:     { label: 'OVERDUE', cls: 'fr-badge overdue' },
    'due-today': { label: 'DUE',     cls: 'fr-badge due' },
    upcoming:    { label: 'VISIT',   cls: 'fr-badge visit' },
  };
  const { label, cls } = map[status];
  return <span className={cls}>{label}</span>;
}

export function EventRow({ event, onToggle }: { event: DueEvent; onToggle: () => void }) {
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

export function VetRow({ vet, onTap, onCall }: { vet: Vet; onTap: () => void; onCall: () => void }) {
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

export function MyPetsSection({ onToast }: { onToast: (msg: string) => void }) {
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

export function DueAndOverdueSection({ onToast }: { onToast: (msg: string) => void }) {
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
              if (e.key === 'Enter')  { setShowComposer(false); onToast('Event added'); }
              if (e.key === 'Escape') { setShowComposer(false); }
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

export function MyVetsSection({ onToast }: { onToast: (msg: string) => void }) {
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
