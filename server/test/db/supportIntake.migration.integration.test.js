import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';
import {
  applySupportIntakeDown,
  applySupportIntakeMigration,
} from './helpers/supportIntakeSql.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('support intake migration tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('106_support_intake_tables migration (real PG)', () => {
  it('applies up, down, and up again', async () => {
    await applySupportIntakeDown(pool).catch(() => {});
    await applySupportIntakeMigration(pool);

    const tables = await pool.query(
      `SELECT table_name FROM information_schema.tables
       WHERE table_schema = 'public'
         AND table_name IN ('support_tickets', 'support_attachments', 'support_outbox')
       ORDER BY table_name`,
    );
    expect(tables.rows.map((r) => r.table_name)).toEqual([
      'support_attachments',
      'support_outbox',
      'support_tickets',
    ]);

    const staffCol = await pool.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'is_support_staff'`,
    );
    expect(staffCol.rows).toHaveLength(1);

    await applySupportIntakeDown(pool);
    const gone = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'support_tickets'`,
    );
    expect(gone.rows).toHaveLength(0);

    await applySupportIntakeMigration(pool);
    const back = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'support_tickets'`,
    );
    expect(back.rows).toHaveLength(1);
  });
});
