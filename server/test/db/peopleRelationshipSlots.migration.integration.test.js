import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';
import {
  applyPeopleRelationshipSlotsDown,
  applyPeopleRelationshipSlotsMigration,
} from './helpers/peopleRelationshipSlotsSql.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'pet_contact_relationships'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('087 migration tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('088_people_relationship_slots migration (real PG)', () => {
  it('dedupes duplicate active primary_vet rows and enforces one active slot', async () => {
    await applyPeopleRelationshipSlotsDown(pool);

    const userId = randomUUID();
    const petId = randomUUID();
    const directoryId = randomUUID();
    const contactA = randomUUID();
    const contactB = randomUUID();
    const relA = randomUUID();
    const relB = randomUUID();

    await pool.query(
      'INSERT INTO users (id, email, password_hash, first_name, last_name) VALUES ($1, $2, $3, $4, $5)',
      [userId, `slots-${userId}@test.local`, 'hash', 'Slot', 'Tester'],
    );
    await pool.query(
      'INSERT INTO people_directories (id, owner_user_id) VALUES ($1, $2)',
      [directoryId, userId],
    );
    await pool.query(
      `INSERT INTO people_contacts (id, directory_id, kind, name)
       VALUES ($1, $2, 'person', 'Vet A'), ($3, $2, 'person', 'Vet B')`,
      [contactA, directoryId, contactB],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species)
       VALUES ($1, $2, 'SlotPet', 'dog')`,
      [petId, userId],
    );

    await pool.query(
      `INSERT INTO pet_contact_relationships (
         id, pet_id, contact_id, relationship_kind, is_primary, active, created_at, updated_at
       ) VALUES
         ($1, $3, $4, 'primary_vet', true, true, NOW() - interval '2 days', NOW() - interval '1 day'),
         ($2, $3, $5, 'primary_vet', true, true, NOW(), NOW())`,
      [relA, relB, petId, contactA, contactB],
    );

    await applyPeopleRelationshipSlotsMigration(pool);

    const active = await pool.query(
      `SELECT id FROM pet_contact_relationships
       WHERE pet_id = $1 AND relationship_kind = 'primary_vet' AND active = true`,
      [petId],
    );
    expect(active.rows).toHaveLength(1);
    expect(active.rows[0].id).toBe(relB);

    await pool.query('DELETE FROM pet_contact_relationships WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM people_contacts WHERE directory_id = $1', [directoryId]);
    await pool.query('DELETE FROM people_directories WHERE id = $1', [directoryId]);
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);

    await applyPeopleRelationshipSlotsMigration(pool);
  });
});
