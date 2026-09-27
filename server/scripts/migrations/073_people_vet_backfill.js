import { v4 as uuidv4 } from 'uuid';

import { upsertContactFromVet } from '../../lib/people/vetSync.js';

/**
 * Backfill personal directories, vet contacts, and primary_vet relationships.
 * @param {import('pg').PoolClient} client
 */
export async function backfillPeopleFromVets(client) {
  const vets = await client.query(
    `SELECT v.* FROM vets v
     WHERE v.user_id IS NOT NULL
     ORDER BY v.created_at, v.id`,
  );

  const directoryByUser = new Map();

  for (const vet of vets.rows) {
    let directoryId = directoryByUser.get(vet.user_id);
    if (!directoryId) {
      const existing = await client.query(
        'SELECT id FROM people_directories WHERE owner_user_id = $1',
        [vet.user_id],
      );
      if (existing.rows.length > 0) {
        directoryId = existing.rows[0].id;
      } else {
        directoryId = uuidv4();
        await client.query(
          `INSERT INTO people_directories (id, owner_user_id, created_at, updated_at)
           VALUES ($1, $2, NOW(), NOW())`,
          [directoryId, vet.user_id],
        );
      }
      directoryByUser.set(vet.user_id, directoryId);
    }

    await upsertContactFromVet(client, vet, vet.user_id);
  }

  const pets = await client.query(
    `SELECT p.id AS pet_id, p.vet_id, p.user_id AS owner_user_id
     FROM pets p
     INNER JOIN vets v ON v.id = p.vet_id AND v.user_id = p.user_id
     WHERE p.vet_id IS NOT NULL`,
  );

  for (const pet of pets.rows) {
    const contact = await client.query(
      `SELECT pc.id
       FROM people_contacts pc
       WHERE pc.legacy_vet_id = $1`,
      [pet.vet_id],
    );
    if (contact.rows.length === 0) continue;
    const contactId = contact.rows[0].id;

    const existing = await client.query(
      `SELECT id FROM pet_contact_relationships
       WHERE pet_id = $1 AND contact_id = $2 AND relationship_kind = 'primary_vet'`,
      [pet.pet_id, contactId],
    );
    if (existing.rows.length > 0) continue;

    await client.query(
      `INSERT INTO pet_contact_relationships (
         id, pet_id, contact_id, relationship_kind, is_primary, active,
         created_at, updated_at
       ) VALUES ($1, $2, $3, 'primary_vet', true, true, NOW(), NOW())`,
      [uuidv4(), pet.pet_id, contactId],
    );
  }
}
