import { withTransaction } from '../db/withTransaction.js';
import { copyContactToPersonalDirectory, ensurePersonalDirectory } from './contactsRepo.js';

/**
 * D23: when a pet leaves a household, copy household-directory contacts used by
 * the pet's relationships into the record owner's personal directory and repoint.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} petId
 * @param {string} ownerUserId
 * @param {string|null} householdId — household the pet is leaving (optional)
 */
export async function copyHouseholdContactsForPetLeave(db, petId, ownerUserId, householdId) {
  if (!petId || !ownerUserId) return;

  const rels = await db.query(
    `SELECT pcr.id AS relationship_id, pcr.contact_id, pc.directory_id,
            pd.household_id AS contact_household_id
     FROM pet_contact_relationships pcr
     INNER JOIN people_contacts pc ON pc.id = pcr.contact_id
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE pcr.pet_id = $1`,
    [petId],
  );

  const personalDirId = await ensurePersonalDirectory(db, ownerUserId);

  await withTransaction(db, async (client) => {
    for (const row of rels.rows) {
      if (!row.contact_household_id) continue;
      if (householdId && row.contact_household_id !== householdId) continue;

      const source = await client.query(
        `SELECT pc.*, array_agg(pcr.role) AS roles
         FROM people_contacts pc
         LEFT JOIN people_contact_roles pcr ON pcr.contact_id = pc.id
         WHERE pc.id = $1
         GROUP BY pc.id`,
        [row.contact_id],
      );
      const contact = source.rows[0];
      if (!contact) continue;

      const targetContactId = await copyContactToPersonalDirectory(
        client,
        contact,
        personalDirId,
      );

      if (targetContactId !== row.contact_id) {
        await client.query(
          'UPDATE pet_contact_relationships SET contact_id = $1, updated_at = NOW() WHERE id = $2',
          [targetContactId, row.relationship_id],
        );
      }
    }
  });
}
