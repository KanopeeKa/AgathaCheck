import { describe, expect, it } from '@jest/globals';

import { ensureOpenOccurrence } from '../../lib/care/schedule/ensureOpenOccurrence.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'monthly',
    frequency_interval: 1,
    start_date: new Date('2026-08-01'),
    next_due_date: new Date('2026-10-27'),
    recurrence_anchor: 'from_completion',
    status: 'active',
    schedule_times: null,
    repeat_end_date: null,
    ...overrides,
  };
}

describe('ensureOpenOccurrence', () => {
  it('materialises the canonical head when no pending row exists (bypasses T-1)', async () => {
    const entry = makeEntry();
    const inserted = [];
    const occurrences = [
      {
        id: 'occ-closed',
        health_entry_id: 'he-1',
        scheduled_date: new Date('2026-09-27'),
        scheduled_time: null,
        status: 'completed',
        completed_on: new Date('2026-09-27'),
      },
    ];

    const pool = {
      query: async (sql, params) => {
        if (
          sql.includes('SELECT scheduled_date FROM health_occurrences')
          && sql.includes("status = 'pending'")
          && sql.includes('ORDER BY scheduled_date ASC')
        ) {
          return { rows: [] };
        }
        if (
          sql.includes('SELECT scheduled_date, completed_on FROM health_occurrences')
          && sql.includes("status IN ('completed', 'skipped')")
        ) {
          return {
            rows: [{
              scheduled_date: occurrences[0].scheduled_date,
              completed_on: occurrences[0].completed_on,
            }],
          };
        }
        if (sql.includes('SELECT id FROM health_occurrences') && sql.includes('scheduled_date')) {
          const dateIso = params[1];
          const match = occurrences.find(
            (o) => o.status === 'pending' && String(o.scheduled_date).slice(0, 10) === dateIso,
          );
          return { rows: match ? [{ id: match.id }] : [] };
        }
        if (sql.includes('INSERT INTO health_occurrences')) {
          inserted.push(params[2]);
          occurrences.push({
            id: params[0],
            health_entry_id: params[1],
            scheduled_date: new Date(params[2]),
            scheduled_time: params[3],
            status: 'pending',
          });
          return { rows: [] };
        }
        if (sql.includes('SELECT * FROM health_occurrences') && sql.includes('scheduled_date')) {
          const dateIso = params[1];
          const rows = occurrences.filter(
            (o) => o.health_entry_id === params[0]
              && o.status === 'pending'
              && String(o.scheduled_date).slice(0, 10) === dateIso,
          );
          return { rows };
        }
        if (sql.includes('SELECT next_due_date FROM health_entries')) {
          return { rows: [{ next_due_date: new Date('2026-10-27') }] };
        }
        if (sql.includes('UPDATE health_entries SET next_due_date')) {
          return { rows: [] };
        }
        if (sql.includes('SELECT scheduled_date, scheduled_time FROM health_occurrences')) {
          const pending = occurrences.filter((o) => o.status === 'pending');
          return {
            rows: pending.map((o) => ({
              scheduled_date: o.scheduled_date,
              scheduled_time: o.scheduled_time,
            })),
          };
        }
        return { rows: [] };
      },
    };

    const result = await ensureOpenOccurrence(pool, {
      entry,
      todayIso: '2026-09-28',
    });

    expect(result.ok).toBe(true);
    expect(result.created).toBe(true);
    expect(result.head_date).toBe('2026-10-27');
    expect(inserted).toContain('2026-10-27');
  });

  it('uses the deferred next_due_date as head when nothing was ever materialised', async () => {
    const entry = makeEntry({
      frequency: 'daily',
      start_date: new Date('2026-07-01'),
      next_due_date: new Date('2026-10-05'),
    });
    const inserted = [];
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('INSERT INTO health_occurrences')) {
          inserted.push(params[2]);
        }
        return { rows: [] };
      },
    };

    const result = await ensureOpenOccurrence(pool, {
      entry,
      todayIso: '2026-09-28',
    });

    expect(result.ok).toBe(true);
    expect(result.head_date).toBe('2026-10-05');
    expect(inserted).toEqual(['2026-10-05']);
  });

  it('rejects requested_date that is not the open head', async () => {
    const entry = makeEntry();
    const pool = {
      query: async (sql) => {
        if (sql.includes('SELECT scheduled_date FROM health_occurrences') && sql.includes('pending')) {
          return { rows: [{ scheduled_date: new Date('2026-10-27') }] };
        }
        return { rows: [] };
      },
    };

    const result = await ensureOpenOccurrence(pool, {
      entry,
      requestedDateIso: '2026-11-27',
      todayIso: '2026-09-28',
    });

    expect(result.ok).toBe(false);
    expect(result.error).toBe('not_open_head');
    expect(result.head_date).toBe('2026-10-27');
  });
});
