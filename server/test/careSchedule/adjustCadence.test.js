import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate } from '../../lib/calendarDate.js';
import { adjustCadence } from '../../lib/care/schedule/adjustCadence.js';
import { SCHEDULE_EVENT_CADENCE_ADJUSTED } from '../../lib/care/schedule/scheduleEventLedger.js';
import { SCHEDULE_POLICY_VERSION } from '../../lib/care/schedule/schedulePolicy.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'daily',
    frequency_interval: 1,
    frequency_days: null,
    start_date: new Date('2026-09-01'),
    next_due_date: new Date('2026-09-05'),
    recurrence_anchor: 'from_completion',
    care_family: 'medication',
    status: 'active',
    schedule_times: null,
    repeat_end_date: null,
    ...overrides,
  };
}

function makeOccurrence(overrides = {}) {
  return {
    id: uuidv4(),
    health_entry_id: 'he-1',
    scheduled_date: new Date('2026-09-01'),
    scheduled_time: null,
    status: 'pending',
    completed_on: null,
    marked_at: null,
    marked_by_user_id: null,
    notes: '',
    ...overrides,
  };
}

function createHarness(initialEntry, initialOccurrences = [], todayIso = '2026-09-05') {
  let entry = { ...initialEntry };
  const occurrences = [...initialOccurrences];
  const ledgerEvents = [];
  const insertedDates = [];
  let nextDueDate = dateToIsoDate(initialEntry.next_due_date) || '2026-09-05';

  const pool = {
    query: async (sql, params) => {
      if (
        sql.includes('DELETE FROM health_occurrences')
        && sql.includes("status = 'pending'")
        && sql.includes('scheduled_date >=')
      ) {
        const effectiveFrom = params[1];
        for (let i = occurrences.length - 1; i >= 0; i -= 1) {
          const occ = occurrences[i];
          if (
            occ.health_entry_id === params[0]
            && occ.status === 'pending'
            && dateToIsoDate(occ.scheduled_date) >= effectiveFrom
          ) {
            occurrences.splice(i, 1);
          }
        }
        return { rows: [] };
      }

      if (
        sql.includes('UPDATE health_entries SET')
        && sql.includes('frequency = $1')
        && sql.includes('recurrence_anchor = $4')
      ) {
        if (entry.status !== 'active') return { rows: [] };
        entry = {
          ...entry,
          frequency: params[0],
          frequency_interval: params[1],
          frequency_days: params[2],
          recurrence_anchor: params[3],
        };
        return { rows: [entry] };
      }

      if (
        sql.includes('SELECT 1 FROM health_occurrences')
        && sql.includes('scheduled_date < $2')
      ) {
        const hasPending = occurrences.some(
          (o) => o.health_entry_id === params[0]
            && o.status === 'pending'
            && dateToIsoDate(o.scheduled_date) < params[1],
        );
        return { rows: hasPending ? [{ '?column?': 1 }] : [] };
      }

      if (sql.includes('INSERT INTO care_schedule_events')) {
        ledgerEvents.push({
          id: params[0],
          health_entry_id: params[1],
          health_occurrence_id: params[2],
          event_type: params[3],
          from_date: params[4],
          to_date: params[5],
          from_anchor: params[6],
          to_anchor: params[7],
          reason_code: params[8],
          reason_note: params[9],
          actor_user_id: params[10],
          occurred_at: params[11],
          effective_from: params[12],
          idempotency_key: params[13],
          policy_version: params[14],
        });
        return { rows: [] };
      }

      if (
        sql.includes('SELECT scheduled_date FROM health_occurrences')
        && sql.includes("status = 'pending'")
        && sql.includes('LIMIT 1')
      ) {
        const pending = occurrences
          .filter((o) => o.health_entry_id === entry.id && o.status === 'pending')
          .sort((a, b) => a.scheduled_date - b.scheduled_date);
        return {
          rows: pending.length > 0 ? [{ scheduled_date: pending[0].scheduled_date }] : [],
        };
      }

      if (
        sql.includes('SELECT scheduled_date, completed_on FROM health_occurrences')
        && sql.includes("status IN ('completed', 'skipped')")
      ) {
        const closed = occurrences
          .filter((o) => o.health_entry_id === entry.id && ['completed', 'skipped'].includes(o.status))
          .sort((a, b) => b.scheduled_date - a.scheduled_date);
        return {
          rows: closed.length > 0
            ? [{
              scheduled_date: closed[0].scheduled_date,
              completed_on: closed[0].completed_on,
            }]
            : [],
        };
      }

      if (sql.includes('SELECT id FROM health_occurrences') && sql.includes("status = 'pending'")) {
        const dup = occurrences.find((o) =>
          o.health_entry_id === params[0]
          && dateToIsoDate(o.scheduled_date) === params[1]
          && o.status === 'pending'
          && (
            (params[2] == null && o.scheduled_time == null)
            || String(o.scheduled_time).slice(0, 5) === String(params[2]).slice(0, 5)
          ));
        return { rows: dup ? [{ id: dup.id }] : [] };
      }

      if (sql.includes('INSERT INTO health_occurrences')) {
        insertedDates.push(params[2]);
        occurrences.push(makeOccurrence({
          id: params[0],
          health_entry_id: params[1],
          scheduled_date: new Date(params[2]),
          scheduled_time: params[3],
        }));
        return { rows: [] };
      }

      if (
        sql.includes('SELECT scheduled_date, scheduled_time FROM health_occurrences')
        && sql.includes("status = 'pending'")
      ) {
        const pending = occurrences
          .filter((o) => o.health_entry_id === params[0] && o.status === 'pending')
          .sort((a, b) => a.scheduled_date - b.scheduled_date);
        return {
          rows: pending.length > 0
            ? [{
              scheduled_date: pending[0].scheduled_date,
              scheduled_time: pending[0].scheduled_time,
            }]
            : [],
        };
      }

      if (sql.includes('UPDATE health_entries SET next_due_date')) {
        nextDueDate = params[0];
        return { rows: [] };
      }

      if (sql.includes('SELECT next_due_date FROM health_entries WHERE id = $1')) {
        return { rows: [{ next_due_date: nextDueDate ? new Date(nextDueDate) : null }] };
      }

      if (sql.includes('SELECT * FROM health_entries WHERE id = $1')) {
        return { rows: [entry] };
      }

      if (sql.includes('SELECT 1 FROM health_occurrences WHERE health_entry_id = $1 AND status = \'pending\'')) {
        const pending = occurrences.some(
          (o) => o.health_entry_id === params[0] && o.status === 'pending',
        );
        return { rows: pending ? [{ '?column?': 1 }] : [] };
      }

      return { rows: [] };
    },
  };

  return {
    pool,
    get entry() {
      return entry;
    },
    occurrences,
    ledgerEvents,
    insertedDates,
    get nextDueDate() {
      return nextDueDate;
    },
    todayIso,
  };
}

describe('adjustCadence', () => {
  it('returns null for once entries', async () => {
    const entry = makeEntry({ frequency: 'once' });
    const harness = createHarness(entry, []);

    const result = await adjustCadence(harness.pool, {
      entry,
      userId: 'user-1',
      effectiveFrom: '2026-09-05',
      frequency: 'daily',
    });

    expect(result).toBeNull();
    expect(harness.ledgerEvents).toHaveLength(0);
  });

  it('removes pending occurrences on or after effective_from and updates entry cadence', async () => {
    const entry = makeEntry();
    const pastPending = makeOccurrence({
      id: 'occ-before',
      scheduled_date: new Date('2026-09-04'),
    });
    const futurePending = makeOccurrence({
      id: 'occ-after',
      scheduled_date: new Date('2026-09-06'),
    });
    const harness = createHarness(entry, [pastPending, futurePending]);

    const result = await adjustCadence(harness.pool, {
      entry,
      userId: 'user-1',
      effectiveFrom: '2026-09-05',
      frequency: 'weekly',
      todayIso: harness.todayIso,
    });

    expect(result).not.toBeNull();
    expect(harness.entry.frequency).toBe('weekly');
    expect(harness.occurrences.find((o) => o.id === 'occ-after')).toBeUndefined();
    expect(harness.occurrences.find((o) => o.id === 'occ-before')).toBeDefined();
    expect(harness.insertedDates).toEqual([]);
    expect(harness.nextDueDate).toBe('2026-09-04');
  });

  it('materialises at effective_from when no earlier pending occurrences remain', async () => {
    const entry = makeEntry();
    const futurePending = makeOccurrence({
      scheduled_date: new Date('2026-09-06'),
    });
    const harness = createHarness(entry, [futurePending]);

    await adjustCadence(harness.pool, {
      entry,
      userId: 'user-1',
      effectiveFrom: '2026-09-05',
      frequency: 'weekly',
      todayIso: harness.todayIso,
    });

    expect(harness.insertedDates).toEqual(['2026-09-05']);
    expect(harness.nextDueDate).toBe('2026-09-05');
  });

  it('leaves past closed occurrences immutable', async () => {
    const entry = makeEntry();
    const completed = makeOccurrence({
      id: 'occ-done',
      scheduled_date: new Date('2026-09-01'),
      status: 'completed',
      completed_on: new Date('2026-09-01'),
    });
    const futurePending = makeOccurrence({
      scheduled_date: new Date('2026-09-06'),
    });
    const harness = createHarness(entry, [completed, futurePending]);

    await adjustCadence(harness.pool, {
      entry,
      userId: 'user-1',
      effectiveFrom: '2026-09-05',
      frequency: 'weekly',
      todayIso: harness.todayIso,
    });

    const closed = harness.occurrences.find((o) => o.id === 'occ-done');
    expect(closed.status).toBe('completed');
    expect(closed.scheduled_date).toEqual(new Date('2026-09-01'));
    expect(closed.completed_on).toEqual(new Date('2026-09-01'));
  });

  it('writes care_schedule_events with anchor change and effective_from', async () => {
    const entry = makeEntry({ recurrence_anchor: 'from_completion' });
    const harness = createHarness(entry, [
      makeOccurrence({ scheduled_date: new Date('2026-09-06') }),
    ]);

    await adjustCadence(harness.pool, {
      entry,
      userId: 'user-1',
      effectiveFrom: '2026-09-05',
      recurrenceAnchor: 'from_due_date',
      reasonCode: 'clinical_cadence',
      reasonNote: 'Switch to fixed interval',
      todayIso: harness.todayIso,
    });

    expect(harness.ledgerEvents).toHaveLength(1);
    expect(harness.ledgerEvents[0]).toMatchObject({
      health_entry_id: entry.id,
      event_type: SCHEDULE_EVENT_CADENCE_ADJUSTED,
      from_anchor: 'from_completion',
      to_anchor: 'from_due_date',
      effective_from: '2026-09-05',
      reason_code: 'clinical_cadence',
      reason_note: 'Switch to fixed interval',
      actor_user_id: 'user-1',
      idempotency_key: `cadence_adjusted:${entry.id}:2026-09-05`,
      policy_version: SCHEDULE_POLICY_VERSION,
    });
  });
});
