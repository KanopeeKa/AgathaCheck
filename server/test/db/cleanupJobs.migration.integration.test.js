import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';
import {
  applyCleanupJobsDown,
  applyCleanupJobsMigration,
} from './helpers/cleanupJobsSql.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('cleanup_jobs migration tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('085_cleanup_jobs migration (real PG)', () => {
  it('applies up, down, and up again', async () => {
    await applyCleanupJobsDown(pool).catch(() => {});
    await applyCleanupJobsMigration(pool);

    const columns = await pool.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'cleanup_jobs'
       ORDER BY column_name`,
    );
    expect(columns.rows.map((r) => r.column_name)).toEqual(
      expect.arrayContaining([
        'attempts',
        'completed_at',
        'correlation_id',
        'created_at',
        'dedupe_key',
        'id',
        'job_type',
        'last_error_redacted',
        'lease_expires_at',
        'lease_token',
        'max_attempts',
        'next_attempt_at',
        'payload',
        'status',
        'updated_at',
      ]),
    );

    await applyCleanupJobsDown(pool);
    const gone = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'cleanup_jobs'`,
    );
    expect(gone.rows).toHaveLength(0);

    await applyCleanupJobsMigration(pool);
    const back = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'cleanup_jobs'`,
    );
    expect(back.rows).toHaveLength(1);
  });
});
