import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import { explainGap } from '../../lib/care/schedule/explainGap.js';
import { pauseSeries } from '../../lib/care/schedule/pauseResumeSeries.js';
import { rescheduleOccurrence } from '../../lib/care/schedule/rescheduleOccurrence.js';
import { skipOccurrence } from '../../lib/care/schedule/skipOccurrence.js';
import {
  SCHEDULE_EVENT_PAUSED,
  SCHEDULE_EVENT_RESCHEDULED,
  SCHEDULE_EVENT_SKIPPED,
} from '../../lib/care/schedule/scheduleEventLedger.js';
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
  let entryStatus = entry.status || 'active';
  let pausedSince = entry.paused_since ?? null;

  const pool = {
    query: async (sql, params) => {
      if (sql.includes('FROM care_schedule_events')) {
        const fromDate = params[1];
        const toDate = params[2];
        const rows = ledgerEvents
          .filter((event) => event.health_entry_id === params[0])
          .filter((event) => {
            if (!fromDate && !toDate) return true;
            const dates = [event.from_date, event.to_date, event.effective_from].filter(Boolean);
            if (dates.length === 0) return true;
            return dates.some((d) => {
              if (fromDate && d < fromDate) return false;
              if (toDate && d > toDate) return false;
              return true;
            })
              || (
                event.from_date && event.to_date
                && (!fromDate || event.to_date >= fromDate)
                && (!toDate || event.from_date <= toDate)
              );
          })
          .sort((a, b) => {
            const at = new Date(a.occurred_at).getTime() - new Date(b.occurred_at).getTime();
            if (at !== 0) return at;
            return String(a.id).localeCompare(String(b.id));
          });
        return { rows };
      }

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

      if (sql.includes("UPDATE health_occurrences SET status = 'skipped'")) {
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

      if (sql.includes('UPDATE health_occurrences SET scheduled_date = $1')) {
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

      if (sql.includes("UPDATE health_entries SET status = 'paused'")) {
        entryStatus = 'paused';
        pausedSince = params[0];
        return {
          rows: [{
            ...entry,
            status: 'paused',
            paused_since: new Date(params[0]),
          }],
        };
      }

      if (sql.includes('INSERT INTO care_schedule_events')) {
        const event = {
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
          created_at: params[11],
        };
        ledgerEvents.push(event);
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
    get entryState() {
      return { status: entryStatus, paused_since: pausedSince };
    },
    get nextDueDate() {
      return nextDueDate;
    },
  };
}

describe('explainGap', () => {
  it('returns empty events when the ledger has no rows', async () => {
    const entry = makeEntry();
    const harness = createHarness(entry, []);

    const result = await explainGap(harness.pool, { entry });

    expect(result).toEqual({ events: [] });
  });

  it('returns skip event facts after skipOccurrence writes the ledger', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ scheduled_date: new Date('2026-09-01') });
    const harness = createHarness(entry, [occ]);

    await skipOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      notes: 'Travel day',
      todayIso: '2026-09-01',
    });

    const result = await explainGap(harness.pool, { entry });

    expect(result.events).toHaveLength(1);
    expect(result.events[0]).toMatchObject({
      event_type: SCHEDULE_EVENT_SKIPPED,
      occurrence_id: occ.id,
      from_date: '2026-09-01',
      to_date: null,
      reason_note: 'Travel day',
      policy_version: SCHEDULE_POLICY_VERSION,
    });
    expect(result.events[0].reason_code).toBeNull();
  });

  it('returns pause event facts after pauseSeries writes the ledger', async () => {
    const entry = makeEntry();
    const harness = createHarness(entry, []);

    await pauseSeries(harness.pool, {
      entry,
      userId: 'user-1',
      pausedFrom: '2026-09-05',
      reasonCode: 'vet_hold',
      reasonNote: 'Post-surgery rest',
    });

    const result = await explainGap(harness.pool, { entry });

    expect(result.events).toHaveLength(1);
    expect(result.events[0]).toMatchObject({
      event_type: SCHEDULE_EVENT_PAUSED,
      occurrence_id: null,
      from_date: '2026-09-05',
      to_date: null,
      reason_code: 'vet_hold',
      reason_note: 'Post-surgery rest',
      policy_version: SCHEDULE_POLICY_VERSION,
    });
  });

  it('returns reschedule event facts with original and new dates', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ scheduled_date: new Date('2026-09-01') });
    const harness = createHarness(entry, [occ]);

    await rescheduleOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      newScheduledDate: '2026-09-08',
      reasonCode: 'conflict',
      reasonNote: 'Moved to next week',
    });

    const result = await explainGap(harness.pool, { entry });

    expect(result.events).toHaveLength(1);
    expect(result.events[0]).toMatchObject({
      event_type: SCHEDULE_EVENT_RESCHEDULED,
      occurrence_id: occ.id,
      from_date: '2026-09-01',
      to_date: '2026-09-08',
      reason_code: 'conflict',
      reason_note: 'Moved to next week',
      policy_version: SCHEDULE_POLICY_VERSION,
    });
  });

  it('filters events to the requested date window', async () => {
    const entry = makeEntry();
    const day1 = makeOccurrence({ scheduled_date: new Date('2026-08-30') });
    const day2 = makeOccurrence({ scheduled_date: new Date('2026-09-10') });
    const harness = createHarness(entry, [day1, day2]);

    await skipOccurrence(harness.pool, {
      entry,
      occurrenceId: day1.id,
      userId: 'user-1',
      todayIso: '2026-09-01',
    });
    await skipOccurrence(harness.pool, {
      entry,
      occurrenceId: day2.id,
      userId: 'user-1',
      todayIso: '2026-09-10',
    });

    const result = await explainGap(harness.pool, {
      entry,
      fromDate: '2026-09-01',
      toDate: '2026-09-15',
    });

    expect(result.events).toHaveLength(1);
    expect(result.events[0]).toMatchObject({
      event_type: SCHEDULE_EVENT_SKIPPED,
      occurrence_id: day2.id,
      from_date: '2026-09-10',
    });
  });
});
