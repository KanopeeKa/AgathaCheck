import { v4 as uuidv4 } from 'uuid';

import { syncPetPrimaryVetFromLegacyVetId } from '../../lib/people/petVetLink.js';
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
    await syncPetPrimaryVetFromLegacyVetId(
      client,
      pet.pet_id,
      pet.vet_id,
      pet.owner_user_id,
    );
  }
}
