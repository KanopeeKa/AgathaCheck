import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import {
  advanceSeries,
  resolveNextSeriesDate,
} from '../../lib/care/schedule/advanceSeries.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'daily',
    frequency_interval: 1,
    frequency_days: null,
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
    ...overrides,
  };
}

/**
 * In-memory occurrence store with enough SQL coverage for advanceSeries +
 * insertOccurrencesForDay + syncNextDueDateFromOccurrences.
 */
function createOccurrenceHarness(entry, initialOccurrences = [], todayIso = '2026-09-01') {
  const occurrences = [...initialOccurrences];
  const insertedDates = [];
  let nextDueDate = entry.next_due_date
    ? String(entry.next_due_date).slice(0, 10)
    : null;

  const pool = {
    query: async (sql, params) => {
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
          .sort((a, b) => {
            const dateCmp = b.scheduled_date - a.scheduled_date;
            if (dateCmp !== 0) return dateCmp;
            const timeA = a.scheduled_time || '00:00:00';
            const timeB = b.scheduled_time || '00:00:00';
            return String(timeB).localeCompare(String(timeA));
          });
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
          && String(o.scheduled_date).slice(0, 10) === params[1]
          && o.status === 'pending'
          && (
            (params[2] == null && o.scheduled_time == null)
            || String(o.scheduled_time).slice(0, 5) === String(params[2]).slice(0, 5)
          ));
        return { rows: dup ? [{ id: dup.id }] : [] };
      }

      if (sql.includes('INSERT INTO health_occurrences')) {
        const row = makeOccurrence({
          id: params[0],
          health_entry_id: params[1],
          scheduled_date: new Date(params[2]),
          scheduled_time: params[3],
          status: 'pending',
        });
        occurrences.push(row);
        insertedDates.push(params[2]);
        return { rows: [] };
      }

      if (
        sql.includes('SELECT scheduled_date, scheduled_time FROM health_occurrences')
        && sql.includes("status = 'pending'")
        && sql.includes('LIMIT 1')
      ) {
        const pending = occurrences
          .filter((o) => o.health_entry_id === params[0] && o.status === 'pending')
          .sort((a, b) => {
            const dateCmp = a.scheduled_date - b.scheduled_date;
            if (dateCmp !== 0) return dateCmp;
            const timeA = a.scheduled_time || '00:00:00';
            const timeB = b.scheduled_time || '00:00:00';
            return String(timeA).localeCompare(String(timeB));
          });
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
    insertedDates,
    get nextDueDate() {
      return nextDueDate;
    },
  };
}

describe('resolveNextSeriesDate', () => {
  it('scenario 4: weekly advances by 7 days from closed due date', () => {
    const entry = makeEntry({ frequency: 'weekly', recurrence_anchor: 'from_due_date' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-01')).toBe('2026-09-08');
  });

  it('scenario 5: from_due_date ignores late completion date', () => {
    const entry = makeEntry({ frequency: 'weekly', recurrence_anchor: 'from_due_date' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-05')).toBe('2026-09-08');
  });

  it('scenario 6: from_completion drifts from actual completion', () => {
    const entry = makeEntry({ frequency: 'weekly', recurrence_anchor: 'from_completion' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-05')).toBe('2026-09-12');
  });

  it('scenario 1: daily advances by one day', () => {
    const entry = makeEntry({ frequency: 'daily' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-01')).toBe('2026-09-02');
  });
});

describe('advanceSeries', () => {
  it('scenario 1: daily single-slot rollover materialises next day', async () => {
    const entry = makeEntry({ frequency: 'daily', schedule_times: null });
    const harness = createOccurrenceHarness(entry, [
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
    ], '2026-09-01');

    await advanceSeries(harness.pool, entry, '2026-09-01');

    expect(harness.insertedDates).toEqual(['2026-09-02']);
    expect(harness.nextDueDate).toBe('2026-09-02');
  });

  it('scenario 2: partial multi-dose day does not advance', async () => {
    const entry = makeEntry({
      frequency: 'daily',
      schedule_times: ['08:00', '18:00'],
    });
    const harness = createOccurrenceHarness(entry, [
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        scheduled_time: '08:00:00',
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        scheduled_time: '18:00:00',
        status: 'pending',
      }),
    ], '2026-09-01');

    await advanceSeries(harness.pool, entry, '2026-09-01');

    expect(harness.insertedDates).toEqual([]);
  });

  it('scenario 3: daily multi-dose day closed materialises next day for all slots', async () => {
    const entry = makeEntry({
      frequency: 'daily',
      schedule_times: ['08:00', '18:00'],
    });
    const harness = createOccurrenceHarness(entry, [
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        scheduled_time: '08:00:00',
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        scheduled_time: '18:00:00',
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
    ], '2026-09-01');

    await advanceSeries(harness.pool, entry, '2026-09-01');

    expect(harness.insertedDates).toEqual(['2026-09-02', '2026-09-02']);
  });

  it('scenario 19: weekly multi-dose day closed advances +7 days not +1', async () => {
    const entry = makeEntry({
      frequency: 'weekly',
      schedule_times: ['08:00', '18:00'],
      recurrence_anchor: 'from_due_date',
    });
    const harness = createOccurrenceHarness(entry, [
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        scheduled_time: '08:00:00',
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        scheduled_time: '18:00:00',
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
    ], '2026-09-07');

    await advanceSeries(harness.pool, entry, '2026-09-07');

    expect(harness.insertedDates).toEqual(['2026-09-08', '2026-09-08']);
    expect(harness.insertedDates).not.toContain('2026-09-02');
  });

  it('scenario 4: weekly single-slot advances by frequency not calendar day', async () => {
    const entry = makeEntry({
      frequency: 'weekly',
      recurrence_anchor: 'from_due_date',
    });
    const harness = createOccurrenceHarness(entry, [
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
    ], '2026-09-07');

    await advanceSeries(harness.pool, entry, '2026-09-07');

    expect(harness.insertedDates).toEqual(['2026-09-08']);
  });

  it('does not materialise when next date is outside T-1 window and not overdue', async () => {
    const entry = makeEntry({ frequency: 'daily' });
    const harness = createOccurrenceHarness(entry, [
      makeOccurrence({
        scheduled_date: new Date('2026-09-01'),
        status: 'completed',
        completed_on: new Date('2026-09-01'),
      }),
    ], '2026-08-30');

    await advanceSeries(harness.pool, entry, '2026-08-30');

    expect(harness.insertedDates).toEqual([]);
  });
});
