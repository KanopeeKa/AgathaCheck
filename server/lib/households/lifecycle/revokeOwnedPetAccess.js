import { deleteAccessForTargetUser } from '../../../db/sharing/shareAccessQueries.js';
import {
  GUEST_GRANT_ACTIVE,
  GUEST_GRANT_REVOKED,
} from '../../people/absenceGuestGrants.js';

/**
 * H3: revoke direct shares and active absence guest grants the target holds on the actor's pets
 * in this household.
 *
 * @param {import('pg').PoolClient} client
 * @param {string} actorId
 * @param {string} targetUserId
 * @param {string} householdId
 */
export async function revokeRemoveAllAccessToMyPets(client, actorId, targetUserId, householdId) {
  const owned = await client.query(
    `SELECT hp.pet_id FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE hp.household_id = $1 AND p.user_id = $2`,
    [householdId, actorId],
  );
  for (const row of owned.rows) {
    await deleteAccessForTargetUser(client, row.pet_id, targetUserId);
    await client.query(
      `UPDATE planned_absence_guest_grants
       SET status = $4, revoked_at = NOW()
       WHERE pet_id = $1 AND grantee_user_id = $2 AND status = $3`,
      [row.pet_id, targetUserId, GUEST_GRANT_ACTIVE, GUEST_GRANT_REVOKED],
    );
  }
}
