/**
 * Migration 084 — care date outcome backfill is idempotent when legacy column exists.
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { migrateCareDateOutcome } from '../../scripts/migrations/104_care_date_outcome.js';
import { createDbPool, createOwner, removeOwner } from './helpers/careHarness.js';

describe('migration 084 care date outcome', () => {
  /** @type {import('pg').Pool|null} */
  let pool;
  let entryId;
  let occId;
  let owner;
  let runnable = false;

  beforeAll(async () => {
    pool = createDbPool();
    const ready = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_name = 'health_occurrences' AND column_name = 'origin'`,
    );
    if (ready.rows.length === 0) {
      await pool.end();
      pool = null;
      return;
    }
    const legacy = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_name = 'health_occurrences' AND column_name = 'close_reason'`,
    );
    runnable = legacy.rows.length > 0;
    if (!runnable) return;

    entryId = randomUUID();
    occId = randomUUID();
    owner = await createOwner(pool);
    await pool.query(
      `INSERT INTO health_entries
         (id, pet_id, user_id, name, type, frequency, status, care_planning, care_importance,
          start_date, next_due_date)
       VALUES ($1, $2, $3, 'M084', 'medication', 'once', 'active', 'planned', 'essential',
         CURRENT_DATE, CURRENT_DATE)`,
      [entryId, owner.petId, owner.userId],
    );
    await pool.query(
      `INSERT INTO health_occurrences
         (id, health_entry_id, scheduled_date, status, close_reason, origin)
       VALUES ($1, $2, CURRENT_DATE - 1, 'skipped', 'not_recorded', 'schedule')`,
      [occId, entryId],
    );
  });

  afterAll(async () => {
    if (!pool) return;
    if (entryId) {
      await pool.query('DELETE FROM health_occurrences WHERE health_entry_id = $1', [entryId]);
      await pool.query('DELETE FROM health_entries WHERE id = $1', [entryId]);
    }
    if (owner) await removeOwner(pool, owner);
    await pool.end();
  });

  it('maps skipped/not_recorded to stored not_recorded and drops close_reason', async () => {
    if (!pool || !runnable) return;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await migrateCareDateOutcome(client);
      await client.query('COMMIT');
      await client.query('BEGIN');
      await migrateCareDateOutcome(client);
      await client.query('COMMIT');
    } finally {
      client.release();
    }
    const row = await pool.query('SELECT status FROM health_occurrences WHERE id = $1', [occId]);
    expect(row.rows[0]).toEqual({ status: 'not_recorded' });
    const legacy = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_name = 'health_occurrences' AND column_name = 'close_reason'`,
    );
    expect(legacy.rows).toHaveLength(0);
  });
});
