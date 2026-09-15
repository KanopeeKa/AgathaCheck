import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import { completeOccurrence } from '../../lib/care/schedule/completeOccurrence.js';
import {
  COMPLETION_TIMING_EARLY,
  COMPLETION_TIMING_LATE,
  COMPLETION_TIMING_ON_TIME,
  deriveCompletionTiming,
} from '../../lib/care/schedule/completionTiming.js';
import { occurrenceToMap } from '../../lib/occurrenceScheduling.js';

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
    completion_timing: null,
    marked_at: null,
    marked_by_user_id: null,
    notes: '',
    ...overrides,
  };
}

function createHarness(entry, initialOccurrences = [], todayIso = '2026-09-01') {
  const occurrences = [...initialOccurrences];
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
        sql.includes('UPDATE health_occurrences SET status = \'completed\'')
        && sql.includes('completion_timing')
      ) {
        const idx = occurrences.findIndex(
          (o) => o.id === params[5] && o.health_entry_id === params[6] && o.status === 'pending',
        );
        if (idx < 0) return { rows: [] };
        occurrences[idx] = {
          ...occurrences[idx],
          status: 'completed',
          completed_on: new Date(params[0]),
          marked_at: params[1],
          marked_by_user_id: params[2],
          notes: params[3],
          completion_timing: params[4],
        };
        return { rows: [occurrences[idx]] };
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

  return { pool, occurrences, insertedDates, get nextDueDate() { return nextDueDate; } };
}

describe('deriveCompletionTiming', () => {
  it('classifies early, on_time, and late completions', () => {
    expect(deriveCompletionTiming('2026-09-05', '2026-09-03')).toBe(COMPLETION_TIMING_EARLY);
    expect(deriveCompletionTiming('2026-09-05', '2026-09-05')).toBe(COMPLETION_TIMING_ON_TIME);
    expect(deriveCompletionTiming('2026-09-05', '2026-09-07')).toBe(COMPLETION_TIMING_LATE);
  });
});

describe('completeOccurrence', () => {
  it('returns null for non-pending occurrences', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ status: 'completed' });
    const harness = createHarness(entry, [occ]);

    const result = await completeOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      completedOn: '2026-09-01',
    });

    expect(result).toBeNull();
  });

  it('persists completion_timing and surfaces it on the wire map', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence({ scheduled_date: new Date('2026-09-01') });
    const harness = createHarness(entry, [occ]);

    const result = await completeOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      completedOn: '2026-09-03',
      todayIso: '2026-09-03',
    });

    expect(result).not.toBeNull();
    expect(result.occurrence.completion_timing).toBe(COMPLETION_TIMING_LATE);
    expect(occurrenceToMap(result.occurrence).completion_timing).toBe(COMPLETION_TIMING_LATE);
  });

  it('scenario 2: partial multi-dose day does not advance series', async () => {
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

    await completeOccurrence(harness.pool, {
      entry,
      occurrenceId: morning.id,
      userId: 'user-1',
      completedOn: '2026-09-01',
      todayIso: '2026-09-01',
    });

    expect(harness.insertedDates).toEqual([]);
  });

  it('scenario 3: completing last slot advances to next day', async () => {
    const entry = makeEntry({ schedule_times: ['08:00', '18:00'] });
    const morning = makeOccurrence({
      scheduled_date: new Date('2026-09-01'),
      scheduled_time: '08:00:00',
      status: 'completed',
      completed_on: new Date('2026-09-01'),
      completion_timing: COMPLETION_TIMING_ON_TIME,
    });
    const evening = makeOccurrence({
      scheduled_date: new Date('2026-09-01'),
      scheduled_time: '18:00:00',
    });
    const harness = createHarness(entry, [morning, evening]);

    await completeOccurrence(harness.pool, {
      entry,
      occurrenceId: evening.id,
      userId: 'user-1',
      completedOn: '2026-09-01',
      todayIso: '2026-09-01',
    });

    expect(harness.insertedDates).toEqual(['2026-09-02', '2026-09-02']);
    expect(harness.nextDueDate).toBe('2026-09-02');
  });

  it('scenario 1: daily single-slot completion advances next day', async () => {
    const entry = makeEntry();
    const occ = makeOccurrence();
    const harness = createHarness(entry, [occ]);

    const result = await completeOccurrence(harness.pool, {
      entry,
      occurrenceId: occ.id,
      userId: 'user-1',
      completedOn: '2026-09-01',
      todayIso: '2026-09-01',
    });

    expect(harness.insertedDates).toEqual(['2026-09-02']);
    expect(result?.nextDueDate).toBe('2026-09-02');
    expect(result?.occurrence.completion_timing).toBe(COMPLETION_TIMING_ON_TIME);
  });
});
