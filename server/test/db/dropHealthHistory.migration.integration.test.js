import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';
import {
  applyDropHealthHistoryDown,
  applyDropHealthHistoryMigration,
} from './helpers/dropHealthHistorySql.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('drop_health_history migration tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('088_drop_health_history migration (real PG)', () => {
  it('applies up, down, and up again idempotently', async () => {
    await applyDropHealthHistoryMigration(pool);

    const gone = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'health_history'`,
    );
    expect(gone.rows).toHaveLength(0);

    await applyDropHealthHistoryMigration(pool);

    await applyDropHealthHistoryDown(pool);
    const columns = await pool.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'health_history'
       ORDER BY column_name`,
    );
    expect(columns.rows.map((r) => r.column_name)).toEqual(
      expect.arrayContaining([
        'changed_at',
        'completed_on',
        'due_date',
        'health_entry_id',
        'id',
        'marked_by_user_id',
        'notes',
        'status',
      ]),
    );

    const rowCount = await pool.query('SELECT COUNT(*)::int AS n FROM health_history');
    expect(rowCount.rows[0].n).toBe(0);

    await applyDropHealthHistoryMigration(pool);
    const goneAgain = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'health_history'`,
    );
    expect(goneAgain.rows).toHaveLength(0);
  });
});
