import { v4 as uuidv4 } from 'uuid';

import { upsertContactFromVet } from './vetSync.js';

/**
 * Ensure pet_contact_relationships primary_vet row for pets.vet_id.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string|null} vetId
 * @param {string} ownerUserId
 */
export async function syncPetPrimaryVetFromLegacyVetId(
  pool,
  petId,
  vetId,
  ownerUserId,
) {
  if (!petId || !ownerUserId) return;

  await pool.query(
    `UPDATE pet_contact_relationships
     SET active = false, updated_at = NOW()
     WHERE pet_id = $1 AND relationship_kind = 'primary_vet' AND active = true`,
    [petId],
  );

  if (!vetId) return;

  const vetResult = await pool.query(
    'SELECT * FROM vets WHERE id = $1 AND user_id = $2',
    [vetId, ownerUserId],
  );
  if (vetResult.rows.length === 0) return;

  const vetRow = vetResult.rows[0];
  const contactId = await upsertContactFromVet(pool, vetRow, ownerUserId);
  if (!contactId) return;

  const existing = await pool.query(
    `SELECT id FROM pet_contact_relationships
     WHERE pet_id = $1 AND contact_id = $2 AND relationship_kind = 'primary_vet'`,
    [petId, contactId],
  );

  if (existing.rows.length > 0) {
    await pool.query(
      `UPDATE pet_contact_relationships
       SET active = true, is_primary = true, updated_at = NOW()
       WHERE id = $1`,
      [existing.rows[0].id],
    );
    return;
  }

  await pool.query(
    `INSERT INTO pet_contact_relationships (
       id, pet_id, contact_id, relationship_kind, is_primary, active,
       created_at, updated_at
     ) VALUES ($1, $2, $3, 'primary_vet', true, true, NOW(), NOW())`,
    [uuidv4(), petId, contactId],
  );
}

/**
 * Idempotent repair: sync all vets to contacts and pets.vet_id to primary_vet links.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 */
export async function reconcilePeopleVets(pool) {
  const vets = await pool.query(
    `SELECT v.* FROM vets v
     WHERE v.user_id IS NOT NULL
     ORDER BY v.created_at, v.id`,
  );

  for (const vet of vets.rows) {
    await upsertContactFromVet(pool, vet, vet.user_id);
  }

  const pets = await pool.query(
    `SELECT p.id AS pet_id, p.vet_id, p.user_id AS owner_user_id
     FROM pets p
     WHERE p.vet_id IS NOT NULL`,
  );

  for (const pet of pets.rows) {
    await syncPetPrimaryVetFromLegacyVetId(
      pool,
      pet.pet_id,
      pet.vet_id,
      pet.owner_user_id,
    );
  }
}
