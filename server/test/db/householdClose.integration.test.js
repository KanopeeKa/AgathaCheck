/**
 * H5 — closeHousehold re-points household contacts for in-household and stale outside pets.
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { withTransaction } from '../../lib/db/withTransaction.js';
import { closeHousehold } from '../../lib/households/departure/closeHousehold.js';
import { openStrictHarness } from './helpers/careHarness.js';

let harness;

beforeAll(async () => {
  harness = await openStrictHarness();
}, 30000);

afterAll(async () => {
  if (harness?.pool) await harness.pool.end();
});

async function ensurePersonalDirectory(pool, userId) {
  const existing = await pool.query(
    'SELECT id FROM people_directories WHERE owner_user_id = $1',
    [userId],
  );
  if (existing.rows[0]) return existing.rows[0].id;
  const directoryId = randomUUID();
  await pool.query(
    'INSERT INTO people_directories (id, owner_user_id) VALUES ($1, $2)',
    [directoryId, userId],
  );
  return directoryId;
}

async function createUserWithPet(pool, petName) {
  const userId = randomUUID();
  const petId = randomUUID();
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'House', 'Hold')`,
    [userId, `hh-close-${userId}@example.com`],
  );
  await pool.query(
    `INSERT INTO pets (id, user_id, name, species, home_timezone) VALUES ($1, $2, $3, 'dog', 'UTC')`,
    [petId, userId, petName],
  );
  return { userId, petId };
}

describe('closeHousehold (integration)', () => {
  it('closes with household vet on an in-household pet and a stale provider on a pet that already left', async () => {
    const pool = harness.pool;
    const ownerIn = await createUserWithPet(pool, 'InHouse');
    const ownerOut = await createUserWithPet(pool, 'LeftEarly');

    const householdId = randomUUID();
    const directoryId = randomUUID();
    const householdContactId = randomUUID();
    const entryInId = randomUUID();
    const entryStaleId = randomUUID();

    try {
      await pool.query('INSERT INTO households (id, name) VALUES ($1, $2)', [householdId, 'Close me']);
      await pool.query(
        `INSERT INTO household_members (household_id, user_id, access_tier, is_organiser)
         VALUES ($1, $2, 'full_access', true)`,
        [householdId, ownerIn.userId],
      );
      await pool.query(
        'INSERT INTO people_directories (id, household_id) VALUES ($1, $2)',
        [directoryId, householdId],
      );
      await pool.query(
        `INSERT INTO people_contacts (id, directory_id, kind, name)
         VALUES ($1, $2, 'organisation', 'Household Vet')`,
        [householdContactId, directoryId],
      );
      await pool.query(
        'INSERT INTO household_pets (household_id, pet_id) VALUES ($1, $2)',
        [householdId, ownerIn.petId],
      );

      await pool.query(
        `INSERT INTO health_entries (
           id, pet_id, user_id, name, type, frequency, status,
           care_family, care_setting, care_planning, care_importance,
           importance_overridden, care_source, schedule_policy_version,
           provider_contact_id
         ) VALUES (
           $1, $2, $3, 'Checkup in', 'vet_visit', 'yearly', 'active',
           'wellness_review', 'vet', 'planned', 'recommended',
           false, 'guardian_defined', 1, $4
         )`,
        [entryInId, ownerIn.petId, ownerIn.userId, householdContactId],
      );

      await pool.query(
        `INSERT INTO health_entries (
           id, pet_id, user_id, name, type, frequency, status,
           care_family, care_setting, care_planning, care_importance,
           importance_overridden, care_source, schedule_policy_version,
           provider_contact_id
         ) VALUES (
           $1, $2, $3, 'Stale provider', 'vet_visit', 'yearly', 'active',
           'wellness_review', 'vet', 'planned', 'recommended',
           false, 'guardian_defined', 1, $4
         )`,
        [entryStaleId, ownerOut.petId, ownerOut.userId, householdContactId],
      );

      await withTransaction(pool, async (client) => {
        await closeHousehold(client, householdId);
      });

      const householdRow = await pool.query('SELECT id FROM households WHERE id = $1', [householdId]);
      expect(householdRow.rows).toHaveLength(0);

      const inProvider = await pool.query(
        'SELECT provider_contact_id FROM health_entries WHERE id = $1',
        [entryInId],
      );
      const staleProvider = await pool.query(
        'SELECT provider_contact_id FROM health_entries WHERE id = $1',
        [entryStaleId],
      );

      expect(inProvider.rows[0].provider_contact_id).not.toBeNull();
      expect(staleProvider.rows[0].provider_contact_id).not.toBeNull();
      expect(inProvider.rows[0].provider_contact_id).not.toBe(householdContactId);
      expect(staleProvider.rows[0].provider_contact_id).not.toBe(householdContactId);

      const ownerInDir = await ensurePersonalDirectory(pool, ownerIn.userId);
      const ownerOutDir = await ensurePersonalDirectory(pool, ownerOut.userId);

      const inContactDir = await pool.query(
        `SELECT pd.owner_user_id FROM people_contacts pc
         INNER JOIN people_directories pd ON pd.id = pc.directory_id
         WHERE pc.id = $1`,
        [inProvider.rows[0].provider_contact_id],
      );
      const staleContactDir = await pool.query(
        `SELECT pd.owner_user_id FROM people_contacts pc
         INNER JOIN people_directories pd ON pd.id = pc.directory_id
         WHERE pc.id = $1`,
        [staleProvider.rows[0].provider_contact_id],
      );

      expect(inContactDir.rows[0].owner_user_id).toBe(ownerIn.userId);
      expect(staleContactDir.rows[0].owner_user_id).toBe(ownerOut.userId);
      expect(inContactDir.rows[0].owner_user_id).not.toBe(ownerOutDir);
    } finally {
      await pool.query('DELETE FROM health_entries WHERE id = ANY($1::uuid[])', [
        [entryInId, entryStaleId],
      ]);
      await pool.query('DELETE FROM pets WHERE id = ANY($1::uuid[])', [
        [ownerIn.petId, ownerOut.petId],
      ]);
      await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [
        [ownerIn.userId, ownerOut.userId],
      ]);
      await pool.query('DELETE FROM people_directories WHERE id = $1 OR owner_user_id = ANY($2::uuid[])', [
        directoryId,
        [ownerIn.userId, ownerOut.userId],
      ]).catch(() => {});
    }
  });
});
