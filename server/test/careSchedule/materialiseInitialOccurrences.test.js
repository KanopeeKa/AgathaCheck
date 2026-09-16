import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import { materialiseInitialOccurrences } from '../../lib/occurrenceScheduling.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'daily',
    frequency_interval: 1,
    start_date: new Date('2026-09-01'),
    next_due_date: new Date('2026-09-01'),
    status: 'active',
    schedule_times: ['08:00', '18:00'],
    ...overrides,
  };
}

function createHarness(entry, todayIso = '2026-09-01') {
  const insertedDates = [];

  const pool = {
    query: async (sql, params) => {
      if (sql.includes('SELECT id FROM health_occurrences') && sql.includes("status = 'pending'")) {
        return { rows: [] };
      }

      if (sql.includes('INSERT INTO health_occurrences')) {
        insertedDates.push(params[2]);
        return { rows: [] };
      }

      if (
        sql.includes('SELECT scheduled_date, scheduled_time FROM health_occurrences')
        && sql.includes("status = 'pending'")
      ) {
        const dates = insertedDates.map((d) => ({
          scheduled_date: new Date(d),
          scheduled_time: null,
        }));
        return { rows: dates.length > 0 ? [dates[0]] : [] };
      }

      if (sql.includes('UPDATE health_entries SET next_due_date')) {
        return { rows: [] };
      }

      return { rows: [] };
    },
  };

  return { pool, insertedDates };
}

describe('materialiseInitialOccurrences', () => {
  it('materialises all slots on anchor day only for multi-per-day entries', async () => {
    const entry = makeEntry();
    const harness = createHarness(entry, '2026-09-01');

    await materialiseInitialOccurrences(harness.pool, entry, '2026-09-01');

    expect(harness.insertedDates).toEqual(['2026-09-01', '2026-09-01']);
    expect(harness.insertedDates).not.toContain('2026-09-02');
  });

  it('does not pre-materialise anchor+1 even when next day is within T-1 window', async () => {
    const entry = makeEntry({ next_due_date: new Date('2026-09-02') });
    const harness = createHarness(entry, '2026-09-01');

    await materialiseInitialOccurrences(harness.pool, entry, '2026-09-01');

    expect(harness.insertedDates.every((d) => d === '2026-09-02')).toBe(true);
    expect(harness.insertedDates).not.toContain('2026-09-03');
  });

  it('materialises once entries on start or next due date', async () => {
    const entry = makeEntry({
      id: uuidv4(),
      frequency: 'once',
      schedule_times: null,
    });
    const harness = createHarness(entry, '2026-09-01');

    await materialiseInitialOccurrences(harness.pool, entry, '2026-09-01');

    expect(harness.insertedDates).toEqual(['2026-09-01']);
  });
});
