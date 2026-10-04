import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';
import {
  applyAccountErasureDown,
  applyAccountErasureMigration,
} from './helpers/accountErasureSql.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('account_erasure migration tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('087_account_erasure_operations migration (real PG)', () => {
  it('applies up, down, and up again', async () => {
    await applyAccountErasureDown(pool).catch(() => {});
    await applyAccountErasureMigration(pool);

    const columns = await pool.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'account_erasure_operations'
       ORDER BY column_name`,
    );
    expect(columns.rows.map((r) => r.column_name)).toEqual(
      expect.arrayContaining([
        'completed_at',
        'db_erased_at',
        'failed_at',
        'id',
        'last_error_redacted',
        'requested_at',
        'status',
        'status_token_hash',
        'user_id',
      ]),
    );

    await applyAccountErasureDown(pool);
    const gone = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'account_erasure_operations'`,
    );
    expect(gone.rows).toHaveLength(0);

    await applyAccountErasureMigration(pool);
    const back = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'account_erasure_operations'`,
    );
    expect(back.rows).toHaveLength(1);
  });
});
