/**
 * Migration 085 — care item closed status backfill (CARE-STATUS-R-013 items).
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { migrateCareItemClosed } from '../../scripts/migrations/085_care_item_closed.js';
import { createDbPool, createOwner, removeOwner } from './helpers/careHarness.js';

describe('migration 085 care item closed', () => {
  /** @type {import('pg').Pool|null} */
  let pool;
  let owner;
  let endedId;
  let stoppedId;
  let runnable = false;

  beforeAll(async () => {
    pool = createDbPool();
    const ready = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_name = 'health_entries' AND column_name = 'status'`,
    );
    if (ready.rows.length === 0) {
      await pool.end();
      pool = null;
      return;
    }
    const legacy = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_name = 'health_entries' AND column_name = 'care_closed_reason'`,
    );
    runnable = legacy.rows.length === 0;
    if (!runnable) return;

    owner = await createOwner(pool);
    endedId = randomUUID();
    stoppedId = randomUUID();
    await pool.query(
      `INSERT INTO health_entries
         (id, pet_id, user_id, name, type, frequency, status, care_planning, care_importance,
          start_date, next_due_date)
       VALUES ($1, $2, $3, 'Ended', 'medication', 'once', 'completed', 'planned', 'essential',
         CURRENT_DATE, NULL),
              ($4, $2, $3, 'Stopped', 'medication', 'once', 'completed', 'planned', 'essential',
         CURRENT_DATE, NULL)`,
      [endedId, owner.petId, owner.userId, stoppedId],
    );
    await pool.query(
      `INSERT INTO audit_events
         (id, actor_user_id, actor_type, action, resource_type, resource_id, outcome, metadata)
       VALUES ($1, $2, 'user', 'health_entry.closed', 'health_entry', $3, 'success', '{}'::jsonb)`,
      [randomUUID(), owner.userId, stoppedId],
    );
  });

  afterAll(async () => {
    if (!pool) return;
    for (const id of [endedId, stoppedId]) {
      if (id) {
        await pool.query('DELETE FROM audit_events WHERE resource_id = $1', [id]);
        await pool.query('DELETE FROM health_entries WHERE id = $1', [id]);
      }
    }
    if (owner) await removeOwner(pool, owner);
    await pool.end();
  });

  it('maps completed to closed with ended or stopped_by_user and is idempotent', async () => {
    if (!pool || !runnable) return;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await migrateCareItemClosed(client);
      await client.query('COMMIT');
      await client.query('BEGIN');
      await migrateCareItemClosed(client);
      await client.query('COMMIT');
    } finally {
      client.release();
    }
    const rows = await pool.query(
      'SELECT id, status, care_closed_reason FROM health_entries WHERE id = ANY($1::uuid[])',
      [[endedId, stoppedId]],
    );
    const byId = Object.fromEntries(rows.rows.map((r) => [r.id, r]));
    expect(byId[endedId]).toMatchObject({ status: 'closed', care_closed_reason: 'ended' });
    expect(byId[stoppedId]).toMatchObject({
      status: 'closed',
      care_closed_reason: 'stopped_by_user',
    });
  });
});
