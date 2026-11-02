import { withTransaction } from '../../db/withTransaction.js';
import { userOwnsPet } from '../../petAccess.js';
import { removePetFromHousehold } from '../departure/index.js';
import { getPetHouseholdId } from '../petAccessGrants.js';
import { emitHouseholdPetRemovedNotices } from '../../notifications/relationshipEmitters.js';

/**
 * Record owner removes their pet from a household (membership not required).
 *
 * @param {import('pg').Pool} pool
 */
export async function removeOwnerPetFromHousehold(pool, ownerUserId, householdId, petId) {
  if (!(await userOwnsPet(pool, petId, ownerUserId))) {
    return { error: 'Forbidden', status: 403 };
  }

  const currentHousehold = await getPetHouseholdId(pool, petId);
  if (!currentHousehold) {
    return { error: 'Pet is not in a household', status: 404 };
  }
  if (currentHousehold !== householdId) {
    return { error: 'Pet is not in this household', status: 404 };
  }

  const householdRow = await pool.query('SELECT name FROM households WHERE id = $1', [householdId]);
  if (householdRow.rows.length === 0) {
    return { error: 'Household not found', status: 404 };
  }
  const householdName = householdRow.rows[0].name || 'Household';

  const memberRows = await pool.query(
    'SELECT user_id FROM household_members WHERE household_id = $1',
    [householdId],
  );
  const recipientUserIds = memberRows.rows
    .map((r) => r.user_id)
    .filter((id) => id && id !== ownerUserId);

  /** @type {import('../departure/notices.js').HouseholdPetRemovedNotice[]} */
  let petNotices = [];

  await withTransaction(pool, async (client) => {
    const result = await removePetFromHousehold(client, {
      householdId,
      petId,
      ownerUserId,
    });
    petNotices = result.notices;
  });

  await emitHouseholdPetRemovedNotices(pool, {
    householdName,
    notices: petNotices,
    recipientUserIds,
    actorUserId: ownerUserId,
  });

  return { message: 'Pet removed from household', pet_id: petId };
}
