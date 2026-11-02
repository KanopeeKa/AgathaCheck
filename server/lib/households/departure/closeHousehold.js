import { repointRemainingHouseholdDirectoryContacts } from './contactRepoint.js';
import { removePetFromHousehold } from './removePetFromHousehold.js';

/**
 * Close a household: remove remaining pets, re-point stale household contacts (H5), delete row.
 *
 * @param {import('pg').PoolClient} client
 * @param {string} householdId
 * @returns {Promise<import('./notices.js').DepartureResult>}
 */
export async function closeHousehold(client, householdId) {
  const pets = await client.query(
    `SELECT hp.pet_id, p.user_id AS owner_user_id
     FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE hp.household_id = $1`,
    [householdId],
  );

  /** @type {import('./notices.js').HouseholdPetRemovedNotice[]} */
  const notices = [];

  for (const row of pets.rows) {
    const result = await removePetFromHousehold(client, {
      householdId,
      petId: row.pet_id,
      ownerUserId: row.owner_user_id,
    });
    notices.push(...result.notices);
  }

  await repointRemainingHouseholdDirectoryContacts(client, householdId);

  await client.query('DELETE FROM households WHERE id = $1', [householdId]);

  return { notices };
}
