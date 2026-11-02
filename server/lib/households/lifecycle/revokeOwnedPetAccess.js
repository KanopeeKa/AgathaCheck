import { deleteAccessForTargetUser } from '../../../db/sharing/shareAccessQueries.js';
import {
  GUEST_GRANT_ACTIVE,
  GUEST_GRANT_REVOKED,
} from '../../people/absenceGuestGrants.js';

/**
 * H3: revoke direct shares and active absence guest grants the target holds on every pet the
 * organiser owns (not limited to pets currently in the household).
 *
 * @param {import('pg').PoolClient} client
 * @param {string} actorId
 * @param {string} targetUserId
 */
export async function revokeRemoveAllAccessToMyPets(client, actorId, targetUserId) {
  const owned = await client.query(
    'SELECT id AS pet_id FROM pets WHERE user_id = $1',
    [actorId],
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
