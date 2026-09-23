import { randomUUID } from 'crypto';

import { describe, expect, it, beforeAll, afterAll } from '@jest/globals';
import pg from 'pg';

import { deleteAllPetData } from '../../lib/petDataLifecycle.js';
import { withTransaction } from '../../lib/db/withTransaction.js';

function createPool() {
  if (process.env.DATABASE_URL) {
    return new pg.Pool({ connectionString: process.env.DATABASE_URL });
  }
  return new pg.Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: process.env.PGPORT || 5432,
    database: process.env.PGDATABASE || 'agatha_db',
  });
}

describe('petDataLifecycle integration', () => {
  let pool;

  beforeAll(async () => {
    pool = createPool();
    await pool.query('SELECT 1');
  });

  afterAll(async () => {
    await pool?.end();
  });

  it('deleteAllPetData removes child rows in one transaction', async () => {
    const userId = randomUUID();
    const petId = randomUUID();
    const weightId = randomUUID();

    await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name)
       VALUES ($1, $2, 'hash', 'Test', 'User')`,
      [userId, `pet-del-${userId}@example.com`],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'DelPet', 'cat')`,
      [petId, userId],
    );
    await pool.query(
      `INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date)
       VALUES ($1, $2, $3, 4.5, 'kg', CURRENT_DATE)`,
      [weightId, petId, userId],
    );

    const result = await deleteAllPetData(pool, petId, { actorUserId: userId });
    expect(result.deleted).toBe(true);
    expect(result.rows_removed.weight_entries).toBeGreaterThanOrEqual(1);

    const remaining = await pool.query(
      'SELECT COUNT(*)::int AS n FROM weight_entries WHERE pet_id = $1',
      [petId],
    );
    expect(remaining.rows[0].n).toBe(0);

    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  });

  it('withTransaction rolls back when a statement fails', async () => {
    const marker = `rollback-test-${randomUUID()}`;
    let sawRollback = false;

    await expect(
      withTransaction(pool, async (client) => {
        await client.query('CREATE TEMP TABLE txn_probe (label text) ON COMMIT DROP');
        await client.query('INSERT INTO txn_probe (label) VALUES ($1)', [marker]);
        throw new Error('forced failure');
      }),
    ).rejects.toThrow('forced failure');

    const probe = await pool.query(
      `SELECT to_regclass('pg_temp.txn_probe') IS NOT NULL AS exists`,
    );
    sawRollback = !probe.rows[0]?.exists;
    expect(sawRollback).toBe(true);
  });
});
