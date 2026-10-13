import { describe, expect, it, jest } from '@jest/globals';

import { maybeRunDailySuggestionGeneration } from '../../lib/suggestions/suggestionGenerationScheduler.js';

const JOB_KEY = 'suggestion_wave1';

function utcDayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

describe('maybeRunDailySuggestionGeneration', () => {
  it('claims and completes when no prior row exists', async () => {
    const day = utcDayKey();
    const queries = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        queries.push({ sql, params });
        if (sql.includes('INSERT INTO scheduler_daily_runs')) {
          return { rows: [{ job_key: JOB_KEY }] };
        }
        if (sql.includes('FROM pets p')) {
          return { rows: [] };
        }
        if (sql.includes('completed_at = NOW()')) {
          return { rows: [{ job_key: JOB_KEY }] };
        }
        return { rows: [] };
      }),
    };

    const result = await maybeRunDailySuggestionGeneration(pool);
    expect(result.skipped).toBe(false);
    expect(queries.some((q) => q.sql.includes('INSERT INTO scheduler_daily_runs'))).toBe(true);
    expect(queries.some((q) => q.sql.includes('completed_at = NOW()'))).toBe(true);
    expect(queries.find((q) => q.sql.includes('INSERT INTO scheduler_daily_runs'))?.params).toEqual([
      JOB_KEY,
      day,
    ]);
  });

  it('skips when today run already completed', async () => {
    const day = utcDayKey();
    const pool = {
      query: jest.fn(async (sql) => {
        if (sql.includes('INSERT INTO scheduler_daily_runs')) {
          return { rows: [] };
        }
        if (sql.includes('UPDATE scheduler_daily_runs') && sql.includes('claimed_at')) {
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };

    const result = await maybeRunDailySuggestionGeneration(pool);
    expect(result).toEqual({ skipped: true, reason: 'already_ran_today' });
  });

  it('resets run_day on generation failure so another instance can retry', async () => {
    const day = utcDayKey();
    const pool = {
      query: jest.fn(async (sql) => {
        if (sql.includes('INSERT INTO scheduler_daily_runs')) {
          return { rows: [{ job_key: JOB_KEY }] };
        }
        if (sql.includes('FROM pets p')) {
          throw new Error('generation failed');
        }
        if (sql.includes("run_day = ($2::date - INTERVAL '1 day')")) {
          return { rows: [{ job_key: JOB_KEY }] };
        }
        return { rows: [] };
      }),
    };

    await expect(maybeRunDailySuggestionGeneration(pool)).rejects.toThrow('generation failed');
    expect(
      pool.query.mock.calls.some(([sql]) => sql.includes("run_day = ($2::date - INTERVAL '1 day')")),
    ).toBe(true);
    const resetCall = pool.query.mock.calls.find(([sql]) =>
      sql.includes("run_day = ($2::date - INTERVAL '1 day')"),
    );
    expect(resetCall[1]).toEqual([JOB_KEY, day]);
  });

  it('skips concurrent claim while today run is in-flight', async () => {
    const pool = {
      query: jest.fn(async (sql) => {
        if (sql.includes('INSERT INTO scheduler_daily_runs')) {
          return { rows: [] };
        }
        if (sql.includes('UPDATE scheduler_daily_runs') && sql.includes('claimed_at')) {
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };

    const result = await maybeRunDailySuggestionGeneration(pool);
    expect(result).toEqual({ skipped: true, reason: 'already_ran_today' });
    expect(pool.query.mock.calls.some(([sql]) => sql.includes('FROM pets p'))).toBe(false);
  });

  it('reclaims stale in-flight claim older than one hour', async () => {
    const day = utcDayKey();
    let claimUpdates = 0;
    const pool = {
      query: jest.fn(async (sql) => {
        if (sql.includes('INSERT INTO scheduler_daily_runs')) {
          return { rows: [] };
        }
        if (sql.includes('UPDATE scheduler_daily_runs') && sql.includes('claimed_at')) {
          claimUpdates += 1;
          return claimUpdates === 1 ? { rows: [{ job_key: JOB_KEY }] } : { rows: [] };
        }
        if (sql.includes('FROM pets p')) {
          return { rows: [] };
        }
        if (sql.includes('completed_at = NOW()')) {
          return { rows: [{ job_key: JOB_KEY }] };
        }
        return { rows: [] };
      }),
    };

    const result = await maybeRunDailySuggestionGeneration(pool);
    expect(result.skipped).toBe(false);
    const claimSql = pool.query.mock.calls.find(([sql]) =>
      sql.includes('UPDATE scheduler_daily_runs') && sql.includes('claimed_at'),
    )?.[0];
    expect(claimSql).toMatch(/INTERVAL '1 hour'/i);
  });
});
