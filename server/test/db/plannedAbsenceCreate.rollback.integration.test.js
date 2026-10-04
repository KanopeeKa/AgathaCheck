import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { withTransaction } from '../../lib/db/withTransaction.js';
import { replaceAbsencePets } from '../../routes/careContext/plannedAbsenceStore.js';
import { createDbPool } from './helpers/careHarness.js';

let pool;
let dbAvailable = false;

beforeAll(async () => {
  pool = createDbPool();
  try {
    await pool.query('SELECT 1');
    dbAvailable = true;
  } catch {
    dbAvailable = false;
    await pool.end();
    pool = null;
  }
}, 30000);

afterAll(async () => {
  await pool?.end();
});

describe('planned absence create transaction (real PG)', () => {
  it('rolls back absence row when pet link insert fails', async () => {
    if (!dbAvailable || !pool) return;

    const userId = randomUUID();
    const petId = randomUUID();
    const absenceId = randomUUID();
    const bogusPetId = randomUUID();

    await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name)
       VALUES ($1, $2, 'hash', 'Away', 'User')`,
      [userId, `away-${userId}@example.com`],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'TripPet', 'cat')`,
      [petId, userId],
    );

    await expect(
      withTransaction(pool, async (client) => {
        await client.query(
          `INSERT INTO planned_absences
             (id, user_id, starts_on, ends_on, provenance, status)
           VALUES ($1, $2, CURRENT_DATE + 7, CURRENT_DATE + 14, 'user_declared', 'active')`,
          [absenceId, userId],
        );
        await replaceAbsencePets(client, absenceId, [bogusPetId]);
      }),
    ).rejects.toThrow();

    const remaining = await pool.query(
      'SELECT id FROM planned_absences WHERE id = $1',
      [absenceId],
    );
    expect(remaining.rows).toHaveLength(0);

    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  });
});
