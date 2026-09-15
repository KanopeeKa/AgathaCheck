import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import {
  skipMissedOccurrences,
  skipOccurrence,
} from '../../lib/care/schedule/skipOccurrence.js';
import { SCHEDULE_EVENT_SKIPPED } from '../../lib/care/schedule/scheduleEventLedger.js';
import { SCHEDULE_POLICY_VERSION } from '../../lib/care/schedule/schedulePolicy.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'daily',
    frequency_interval: 1,
    start_date: new Date('2026-09-01'),
    next_due_date: new Date('2026-09-01'),
    recurrence_anchor: 'from_completion',
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

function createHarness(entry, initialOccurrences = [], todayIso = '2026-09-01') {
  const occurrences = [...initialOccurrences];
  const ledgerEvents = [];
  const insertedDates = [];
  let nextDueDate = '2026-09-01';

  const pool = {
    query: async (sql, params) => {
      if (
        sql.includes('SELECT * FROM health_occurrences')
        && sql.includes("status = 'pending'")
        && sql.includes('WHERE id = $1')
      ) {
        const row = occurrences.find(
          (o) => o.id === params[0] && o.health_entry_id === params[1] && o.status === 'pending',
        );
        return { rows: row ? [row] : [] };
      }

      if (
        sql.includes('UPDATE health_occurrences SET status = \'skipped\'')
      ) {
        const idx = occurrences.findIndex(
          (o) => o.id === params[3] && o.health_entry_id === params[4] && o.status === 'pending',
        );
        if (idx < 0) return { rows: [] };
        occurrences[idx] = {
          ...occurrences[idx],
          status: 'skipped',
          marked_at: params[0],
          marked_by_user_id: params[1],
          notes: params[2],
        };
        return { rows: [occurrences[idx]] };
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
        sql.includes('SELECT id FROM health_occurrences')
        && sql.includes('ANY($1::uuid[])')
        && sql.includes('ORDER BY scheduled_date ASC')
      ) {
        const ids = params[0];
        const rows = occurrences
          .filter((o) => ids.includes(o.id) && o.health_entry_id === params[1] && o.status === 'pending')
          .sort((a, b) => a.scheduled_date - b.scheduled_date)
          .map((o) => ({ id: o.id }));
        return { rows };
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
        return { rows: [] };
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
    occurrences,
    ledgerEvents,
    insertedDates,
    get nextDueDate() {
      return nextDueDate;
    },
  };
}

describe('skipOccurrence', () => {
  it('returns null for non-pending occurrences', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ status: 'skipped' });
    const harness = createHarness(entry, [occ]);

    const result = await skipOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
    });

    expect(result).toBeNull();
    expect(harness.ledgerEvents).toHaveLength(0);
  });

  it('marks occurrence skipped and writes care_schedule_events ledger row', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ scheduled_date: new Date('2026-09-01') });
    const harness = createHarness(entry, [occ]);

    const result = await skipOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      notes: 'Not needed today',
      todayIso: '2026-09-01',
    });

    expect(result).not.toBeNull();
    expect(result.occurrence.status).toBe('skipped');
    expect(harness.ledgerEvents).toHaveLength(1);
    expect(harness.ledgerEvents[0]).toMatchObject({
      health_entry_id: entry.id,
      health_occurrence_id: occ.id,
      event_type: SCHEDULE_EVENT_SKIPPED,
      from_date: '2026-09-01',
      reason_note: 'Not needed today',
      actor_user_id: 'user-1',
      idempotency_key: `skipped:${occ.id}`,
      policy_version: SCHEDULE_POLICY_VERSION,
    });
  });

  it('advances series after skipping the only pending occurrence', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence();
    const harness = createHarness(entry, [occ]);

    await skipOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      todayIso: '2026-09-01',
    });

    expect(harness.insertedDates).toEqual(['2026-09-02']);
    expect(harness.nextDueDate).toBe('2026-09-02');
  });

  it('does not advance when another pending slot remains on the same day', async () => {
    const entry = makeEntry({ schedule_times: ['08:00', '18:00'] });
    const morning = makeOccurrence({
      scheduled_date: new Date('2026-09-01'),
      scheduled_time: '08:00:00',
    });
    const evening = makeOccurrence({
      scheduled_date: new Date('2026-09-01'),
      scheduled_time: '18:00:00',
    });
    const harness = createHarness(entry, [morning, evening]);

    await skipOccurrence(harness.pool, {
      entry,
      occurrenceId: morning.id,
      userId: 'user-1',
      todayIso: '2026-09-01',
    });

    expect(harness.insertedDates).toEqual([]);
    expect(harness.ledgerEvents).toHaveLength(1);
  });
});

describe('skipMissedOccurrences', () => {
  it('skips missed occurrences in chronological order with ledger rows', async () => {
    const entry = makeEntry();
    const day1 = makeOccurrence({
      id: 'occ-day-1',
      scheduled_date: new Date('2026-08-30'),
    });
    const day2 = makeOccurrence({
      id: 'occ-day-2',
      scheduled_date: new Date('2026-08-31'),
    });
    const harness = createHarness(entry, [day2, day1], '2026-09-01');

    const result = await skipMissedOccurrences(harness.pool, {
      entry,
      userId: 'user-1',
      occurrenceIds: [day2.id, day1.id],
      todayIso: '2026-09-01',
    });

    expect(result.count).toBe(2);
    expect(result.skipped).toEqual([day1.id, day2.id]);
    expect(harness.ledgerEvents).toHaveLength(2);
    expect(harness.ledgerEvents.map((e) => e.from_date)).toEqual(['2026-08-30', '2026-08-31']);
  });

  it('returns empty result when no ids provided', async () => {
    const entry = makeEntry();
    const harness = createHarness(entry, []);

    const result = await skipMissedOccurrences(harness.pool, {
      entry,
      userId: 'user-1',
      occurrenceIds: [],
    });

    expect(result).toEqual({ skipped: [], count: 0 });
  });
});
