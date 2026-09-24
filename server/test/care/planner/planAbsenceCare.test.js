import { addCalendarDaysIso } from '../../../lib/calendarDate.js';
import { planAbsenceCare } from '../../../lib/care/planner/planAbsenceCare.js';

const absence = { id: 'abs-1', starts_on: '2026-06-06', ends_on: '2026-06-10' };
const today = '2026-06-01';

function weeklyEntry(overrides = {}) {
  return {
    id: 'entry-1',
    status: 'active',
    frequency: 'monthly',
    frequency_interval: 1,
    recurrence_anchor: 'from_completion',
    care_source: 'guardian_defined',
    care_family: 'grooming',
    start_date: '2026-01-01',
    ...overrides,
  };
}

function petWithEntries(entries) {
  return {
    pet_id: 'pet-1',
    entries,
  };
}

describe('planAbsenceCare (BR-1…BR-7)', () => {
  it('BR-1: only moves the open occurrence (single suggestion per entry)', () => {
    const entry = weeklyEntry();
    const open = {
      occurrence_id: 'occ-open',
      scheduled_date: '2026-06-08',
    };
    const result = planAbsenceCare({
      absence,
      today,
      pets: [petWithEntries([{ entry, open_occurrence: open, last_closed_date: '2026-05-25' }])],
    });
    expect(result.pets[0].suggestions).toHaveLength(1);
    expect(result.pets[0].suggestions[0].occurrence_id).toBe('occ-open');
  });

  it('BR-6: fixed entries become carer tasks, not suggestions', () => {
    const entry = weeklyEntry({ care_source: 'vet_instruction' });
    const open = { occurrence_id: 'occ-1', scheduled_date: '2026-06-08' };
    const result = planAbsenceCare({
      absence,
      today,
      pets: [petWithEntries([{
        entry,
        open_occurrence: open,
        last_closed_date: null,
        materialized_in_window: 1,
      }])],
    });
    expect(result.pets[0].suggestions).toHaveLength(0);
    expect(result.pets[0].carer_tasks.count).toBe(1);
    expect(result.pets[0].carer_tasks.by_entry[0].reason).toBe('fixed');
  });

  it('BR-4: picks largest reduction, earlier over later, smallest k', () => {
    const entry = weeklyEntry();
    const open = { occurrence_id: 'occ-1', scheduled_date: '2026-06-08' };
    const result = planAbsenceCare({
      absence,
      today,
      pets: [petWithEntries([{ entry, open_occurrence: open, last_closed_date: '2026-05-20' }])],
    });
    const suggestion = result.pets[0].suggestions[0];
    expect(suggestion.in_window_after).toBeLessThan(suggestion.in_window_before);
    expect(suggestion.to_date).toBe('2026-06-05');
    expect(suggestion.direction).toBe('earlier');
  });

  it('BR-5: chain-aware move clears estimated in-window hops (next hop outside window)', () => {
    const entry = weeklyEntry({ frequency: 'weekly', frequency_interval: 1 });
    const open = { occurrence_id: 'occ-1', scheduled_date: '2026-06-01' };
    const result = planAbsenceCare({
      absence,
      today: '2026-05-28',
      pets: [petWithEntries([{ entry, open_occurrence: open, last_closed_date: '2026-05-25' }])],
    });
    expect(result.pets[0].carer_tasks.count).toBe(1);
    expect(result.pets[0].suggestions).toHaveLength(0);
  });

  it('BR-7: overdue before absence start gets overdue rationale', () => {
    const entry = weeklyEntry();
    const open = { occurrence_id: 'occ-1', scheduled_date: '2026-06-03' };
    const result = planAbsenceCare({
      absence: { id: 'abs-1', starts_on: '2026-06-10', ends_on: '2026-06-14' },
      today: '2026-06-05',
      pets: [petWithEntries([{ entry, open_occurrence: open, last_closed_date: '2026-05-20' }])],
    });
    const suggestion = result.pets[0].suggestions[0];
    expect(suggestion.rationale_code).toBe('overdue_do_before_departure');
    expect(suggestion.to_date).toBe('2026-06-09');
  });

  it('BR-7: in-progress absence with overdue open gets no planner suggestion', () => {
    const entry = weeklyEntry();
    const open = { occurrence_id: 'occ-1', scheduled_date: '2026-05-28' };
    const result = planAbsenceCare({
      absence,
      today: '2026-06-07',
      pets: [petWithEntries([{
        entry,
        open_occurrence: open,
        last_closed_date: '2026-05-20',
        materialized_in_window: 1,
      }])],
    });
    expect(result.pets[0].suggestions).toHaveLength(0);
    expect(result.pets[0].carer_tasks.count).toBeGreaterThan(0);
  });

  it('is deterministic for the same input', () => {
    const payload = {
      absence,
      today,
      pets: [petWithEntries([{
        entry: weeklyEntry(),
        open_occurrence: { occurrence_id: 'occ-1', scheduled_date: '2026-06-08' },
        last_closed_date: '2026-05-20',
      }])],
    };
    const a = planAbsenceCare(payload);
    const b = planAbsenceCare(payload);
    expect(a).toEqual(b);
  });
});

describe('planAbsenceCare carer_task entries', () => {
  it('daily rhythm counts as carer_task without suggestions', () => {
    const entry = weeklyEntry({ frequency: 'daily' });
    const result = planAbsenceCare({
      absence,
      today,
      pets: [petWithEntries([{
        entry,
        open_occurrence: { occurrence_id: 'occ-1', scheduled_date: '2026-06-07' },
        last_closed_date: null,
        materialized_in_window: 4,
      }])],
    });
    expect(result.pets[0].suggestions).toHaveLength(0);
    expect(result.pets[0].carer_tasks.by_entry[0].reason).toBe('carer_task');
  });
});
