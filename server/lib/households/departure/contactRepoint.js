import { repointProviderContactForPet } from '../../care/occurrence/repointProviderContact.js';
import {
  copyContactToPersonalDirectory,
  ensurePersonalDirectory,
} from '../../people/contactsRepo.js';

/**
 * @param {import('pg').PoolClient} client
 * @param {string} contactId
 */
async function loadContactWithRoles(client, contactId) {
  const source = await client.query(
    `SELECT pc.*, array_agg(pcr.role) AS roles
     FROM people_contacts pc
     LEFT JOIN people_contact_roles pcr ON pcr.contact_id = pc.id
     WHERE pc.id = $1
     GROUP BY pc.id`,
    [contactId],
  );
  return source.rows[0] || null;
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} contactId
 * @param {string|null} householdId
 */
async function contactBelongsToHousehold(client, contactId, householdId) {
  const row = await client.query(
    `SELECT pd.household_id
     FROM people_contacts pc
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE pc.id = $1`,
    [contactId],
  );
  const contactHouseholdId = row.rows[0]?.household_id ?? null;
  if (!contactHouseholdId) return false;
  if (householdId && contactHouseholdId !== householdId) return false;
  return true;
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} petId
 * @param {string|null} householdId
 */
async function collectHouseholdContactIdsForPet(client, petId, householdId) {
  const ids = new Set();

  const rels = await client.query(
    `SELECT pcr.contact_id, pd.household_id
     FROM pet_contact_relationships pcr
     INNER JOIN people_contacts pc ON pc.id = pcr.contact_id
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE pcr.pet_id = $1 AND pd.household_id IS NOT NULL`,
    [petId],
  );
  for (const row of rels.rows) {
    if (householdId && row.household_id !== householdId) continue;
    ids.add(row.contact_id);
  }

  const entries = await client.query(
    `SELECT he.provider_contact_id AS contact_id, pd.household_id
     FROM health_entries he
     INNER JOIN people_contacts pc ON pc.id = he.provider_contact_id
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE he.pet_id = $1 AND he.provider_contact_id IS NOT NULL AND pd.household_id IS NOT NULL`,
    [petId],
  );
  for (const row of entries.rows) {
    if (householdId && row.household_id !== householdId) continue;
    ids.add(row.contact_id);
  }

  const occurrences = await client.query(
    `SELECT ho.provider_contact_id AS contact_id, pd.household_id
     FROM health_occurrences ho
     INNER JOIN health_entries he ON he.id = ho.health_entry_id
     INNER JOIN people_contacts pc ON pc.id = ho.provider_contact_id
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE he.pet_id = $1 AND ho.provider_contact_id IS NOT NULL AND pd.household_id IS NOT NULL`,
    [petId],
  );
  for (const row of occurrences.rows) {
    if (householdId && row.household_id !== householdId) continue;
    ids.add(row.contact_id);
  }

  const absencePets = await client.query(
    `SELECT pap.contact_id, pd.household_id
     FROM planned_absence_pets pap
     INNER JOIN people_contacts pc ON pc.id = pap.contact_id
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE pap.pet_id = $1 AND pap.contact_id IS NOT NULL AND pd.household_id IS NOT NULL`,
    [petId],
  );
  for (const row of absencePets.rows) {
    if (householdId && row.household_id !== householdId) continue;
    ids.add(row.contact_id);
  }

  const invites = await client.query(
    `SELECT i.contact_id, pd.household_id
     FROM planned_absence_carer_invites i
     INNER JOIN planned_absence_carer_invite_pets ip ON ip.invite_id = i.id
     INNER JOIN people_contacts pc ON pc.id = i.contact_id
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE ip.pet_id = $1 AND i.status = 'pending' AND pd.household_id IS NOT NULL`,
    [petId],
  );
  for (const row of invites.rows) {
    if (householdId && row.household_id !== householdId) continue;
    ids.add(row.contact_id);
  }

  return [...ids];
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} petId
 * @param {string} sourceContactId
 * @param {string} targetContactId
 */
export async function repointPetReferences(client, petId, sourceContactId, targetContactId) {
  if (sourceContactId === targetContactId) return;

  await client.query(
    `UPDATE pet_contact_relationships
     SET contact_id = $1, updated_at = NOW()
     WHERE pet_id = $2 AND contact_id = $3`,
    [targetContactId, petId, sourceContactId],
  );

  await client.query(
    `UPDATE health_entries
     SET provider_contact_id = $1, updated_at = NOW()
     WHERE pet_id = $2 AND provider_contact_id = $3`,
    [targetContactId, petId, sourceContactId],
  );

  await repointProviderContactForPet(client, petId, sourceContactId, targetContactId);

  await client.query(
    `UPDATE planned_absence_pets
     SET contact_id = $1
     WHERE pet_id = $2 AND contact_id = $3`,
    [targetContactId, petId, sourceContactId],
  );

  await client.query(
    `UPDATE planned_absence_carer_invites i
     SET contact_id = $1
     FROM planned_absence_carer_invite_pets ip
     WHERE ip.invite_id = i.id
       AND ip.pet_id = $2
       AND i.contact_id = $3
       AND i.status = 'pending'`,
    [targetContactId, petId, sourceContactId],
  );
}

/**
 * H4 — copy household-directory contacts used by a pet and repoint that pet's references.
 *
 * @param {import('pg').PoolClient} client
 * @param {string} petId
 * @param {string} copyToUserId
 * @param {string|null} householdId
 */
export async function repointPetHouseholdContacts(client, petId, copyToUserId, householdId) {
  if (!petId || !copyToUserId) return;

  const personalDirId = await ensurePersonalDirectory(client, copyToUserId);
  const contactIds = await collectHouseholdContactIdsForPet(client, petId, householdId);

  for (const sourceContactId of contactIds) {
    if (!(await contactBelongsToHousehold(client, sourceContactId, householdId))) continue;
    const contact = await loadContactWithRoles(client, sourceContactId);
    if (!contact) continue;

    const targetContactId = await copyContactToPersonalDirectory(client, contact, personalDirId);
    await repointPetReferences(client, petId, sourceContactId, targetContactId);
  }
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} sourceContactId
 */
async function listPetOwnersReferencingContact(client, sourceContactId) {
  const pairs = new Map();

  const add = (petId, ownerUserId) => {
    if (!petId || !ownerUserId) return;
    pairs.set(petId, ownerUserId);
  };

  const rels = await client.query(
    `SELECT pcr.pet_id, p.user_id AS owner_user_id
     FROM pet_contact_relationships pcr
     INNER JOIN pets p ON p.id = pcr.pet_id
     WHERE pcr.contact_id = $1`,
    [sourceContactId],
  );
  for (const row of rels.rows) add(row.pet_id, row.owner_user_id);

  const entries = await client.query(
    `SELECT he.pet_id, p.user_id AS owner_user_id
     FROM health_entries he
     INNER JOIN pets p ON p.id = he.pet_id
     WHERE he.provider_contact_id = $1`,
    [sourceContactId],
  );
  for (const row of entries.rows) add(row.pet_id, row.owner_user_id);

  const occurrences = await client.query(
    `SELECT he.pet_id, p.user_id AS owner_user_id
     FROM health_occurrences ho
     INNER JOIN health_entries he ON he.id = ho.health_entry_id
     INNER JOIN pets p ON p.id = he.pet_id
     WHERE ho.provider_contact_id = $1`,
    [sourceContactId],
  );
  for (const row of occurrences.rows) add(row.pet_id, row.owner_user_id);

  const absencePets = await client.query(
    `SELECT pap.pet_id, p.user_id AS owner_user_id
     FROM planned_absence_pets pap
     INNER JOIN pets p ON p.id = pap.pet_id
     WHERE pap.contact_id = $1`,
    [sourceContactId],
  );
  for (const row of absencePets.rows) add(row.pet_id, row.owner_user_id);

  const invites = await client.query(
    `SELECT ip.pet_id, p.user_id AS owner_user_id
     FROM planned_absence_carer_invites i
     INNER JOIN planned_absence_carer_invite_pets ip ON ip.invite_id = i.id
     INNER JOIN pets p ON p.id = ip.pet_id
     WHERE i.contact_id = $1 AND i.status = 'pending'`,
    [sourceContactId],
  );
  for (const row of invites.rows) add(row.pet_id, row.owner_user_id);

  return pairs;
}

/**
 * H5 — after pets leave, re-point every remaining reference to a household-directory contact.
 *
 * @param {import('pg').PoolClient} client
 * @param {string} householdId
 */
export async function repointRemainingHouseholdDirectoryContacts(client, householdId) {
  const dirRow = await client.query(
    'SELECT id FROM people_directories WHERE household_id = $1',
    [householdId],
  );
  const directoryId = dirRow.rows[0]?.id;
  if (!directoryId) return;

  const contacts = await client.query(
    'SELECT id FROM people_contacts WHERE directory_id = $1',
    [directoryId],
  );

  for (const { id: sourceContactId } of contacts.rows) {
    const contact = await loadContactWithRoles(client, sourceContactId);
    if (!contact) continue;

    const petOwners = await listPetOwnersReferencingContact(client, sourceContactId);
    const owners = [...new Set(petOwners.values())];

    for (const ownerUserId of owners) {
      const personalDirId = await ensurePersonalDirectory(client, ownerUserId);
      const targetContactId = await copyContactToPersonalDirectory(client, contact, personalDirId);
      for (const [petId, petOwnerId] of petOwners) {
        if (petOwnerId !== ownerUserId) continue;
        await repointPetReferences(client, petId, sourceContactId, targetContactId);
      }
    }
  }
}
