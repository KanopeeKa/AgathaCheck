import { v4 as uuidv4 } from 'uuid';

import { ensurePersonalDirectory } from './directory.js';

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

  for (const row of rels.rows) {
    if (!row.contact_household_id) continue;
    if (householdId && row.contact_household_id !== householdId) continue;

    const source = await db.query(
      `SELECT pc.*, array_agg(pcr.role) AS roles
       FROM people_contacts pc
       LEFT JOIN people_contact_roles pcr ON pcr.contact_id = pc.id
       WHERE pc.id = $1
       GROUP BY pc.id`,
      [row.contact_id],
    );
    const contact = source.rows[0];
    if (!contact) continue;

    const existing = await db.query(
      `SELECT pc.id FROM people_contacts pc
       WHERE pc.directory_id = $1
         AND lower(pc.name) = lower($2)
         AND coalesce(pc.email, '') = coalesce($3::text, '')
       LIMIT 1`,
      [personalDirId, contact.name, contact.email],
    );
    let targetContactId = existing.rows[0]?.id;
    if (!targetContactId) {
      targetContactId = uuidv4();
      await db.query(
        `INSERT INTO people_contacts (
           id, directory_id, kind, name, phone, email, address, website,
           works_at_contact_id, linked_user_id, created_at, updated_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())`,
        [
          targetContactId,
          personalDirId,
          contact.kind,
          contact.name,
          contact.phone,
          contact.email,
          contact.address,
          contact.website,
          contact.works_at_contact_id,
          contact.linked_user_id,
        ],
      );
      const roles = (contact.roles || []).filter(Boolean);
      for (const role of roles) {
        await db.query(
          'INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [targetContactId, role],
        );
      }
    }

    if (targetContactId !== row.contact_id) {
      await db.query(
        'UPDATE pet_contact_relationships SET contact_id = $1, updated_at = NOW() WHERE id = $2',
        [targetContactId, row.relationship_id],
      );
    }
  }
}
