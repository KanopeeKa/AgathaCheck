import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import { rescheduleOccurrence } from '../../lib/care/schedule/rescheduleOccurrence.js';
import { SCHEDULE_EVENT_RESCHEDULED } from '../../lib/care/schedule/scheduleEventLedger.js';
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

function createHarness(entry, initialOccurrences = []) {
  const occurrences = [...initialOccurrences];
  const ledgerEvents = [];
  const insertedDates = [];
  let nextDueDate = '2026-09-01';
  let advanceSeriesCalled = false;
  let syncNextDueCalled = false;

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
        sql.includes('UPDATE health_occurrences SET scheduled_date = $1')
      ) {
        const idx = occurrences.findIndex(
          (o) => o.id === params[1] && o.health_entry_id === params[2] && o.status === 'pending',
        );
        if (idx < 0) return { rows: [] };
        occurrences[idx] = {
          ...occurrences[idx],
          scheduled_date: new Date(params[0]),
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

      if (sql.includes('INSERT INTO health_occurrences')) {
        advanceSeriesCalled = true;
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
        && sql.includes('ORDER BY scheduled_date ASC')
      ) {
        const pending = occurrences
          .filter((o) => o.health_entry_id === params[0] && o.status === 'pending')
          .sort((a, b) => a.scheduled_date - b.scheduled_date);
        return { rows: pending.length ? [pending[0]] : [] };
      }

      if (sql.includes('UPDATE health_entries SET next_due_date')) {
        syncNextDueCalled = true;
        nextDueDate = params[0];
        return { rows: [] };
      }

      if (sql.includes('SELECT next_due_date FROM health_entries WHERE id = $1')) {
        return { rows: [{ next_due_date: nextDueDate ? new Date(nextDueDate) : null }] };
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
    get advanceSeriesCalled() {
      return advanceSeriesCalled;
    },
    get syncNextDueCalled() {
      return syncNextDueCalled;
    },
  };
}

describe('rescheduleOccurrence', () => {
  it('returns null for non-pending occurrences', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ status: 'completed' });
    const harness = createHarness(entry, [occ]);

    const result = await rescheduleOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      newScheduledDate: '2026-09-05',
    });

    expect(result).toBeNull();
    expect(harness.ledgerEvents).toHaveLength(0);
  });

  it('moves one pending occurrence to the new scheduled date', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ scheduled_date: new Date('2026-09-01') });
    const harness = createHarness(entry, [occ]);

    const result = await rescheduleOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      newScheduledDate: '2026-09-05',
      reasonCode: 'vet_visit',
      reasonNote: 'Conflict with appointment',
    });

    expect(result).not.toBeNull();
    expect(result.occurrence.scheduled_date).toEqual(new Date('2026-09-05'));
    expect(harness.occurrences[0].scheduled_date).toEqual(new Date('2026-09-05'));
  });

  it('writes care_schedule_events with original date preserved as from_date', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ scheduled_date: new Date('2026-09-01') });
    const harness = createHarness(entry, [occ]);

    await rescheduleOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      newScheduledDate: '2026-09-05',
      reasonCode: 'vet_visit',
      reasonNote: 'Conflict with appointment',
    });

    expect(harness.ledgerEvents).toHaveLength(1);
    expect(harness.ledgerEvents[0]).toMatchObject({
      health_entry_id: entry.id,
      health_occurrence_id: occ.id,
      event_type: SCHEDULE_EVENT_RESCHEDULED,
      from_date: '2026-09-01',
      to_date: '2026-09-05',
      reason_code: 'vet_visit',
      reason_note: 'Conflict with appointment',
      actor_user_id: 'user-1',
      idempotency_key: `rescheduled:${occ.id}:2026-09-05`,
      policy_version: SCHEDULE_POLICY_VERSION,
    });
  });

  it('syncs next_due_date without advancing the series', async () => {
    const entry = makeEntry({
      frequency: 'weekly',
      frequency_interval: 1,
      next_due_date: new Date('2026-09-01'),
    });
    const occ = makeOccurrence({ scheduled_date: new Date('2026-09-01') });
    const harness = createHarness(entry, [occ]);

    const result = await rescheduleOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      newScheduledDate: '2026-09-08',
    });

    expect(harness.advanceSeriesCalled).toBe(false);
    expect(harness.insertedDates).toEqual([]);
    expect(harness.syncNextDueCalled).toBe(true);
    expect(harness.nextDueDate).toBe('2026-09-08');
    expect(result.nextDueDate).toBe('2026-09-08');
  });
});
