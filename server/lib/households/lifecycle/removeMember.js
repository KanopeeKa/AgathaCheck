import { withTransaction } from '../../db/withTransaction.js';
import { closeHousehold, removePetFromHousehold } from '../departure/index.js';
import { getHouseholdMembership } from '../authz.js';
import { HOUSEHOLD_TIER_FULL } from '../constants.js';
import { getHouseholdMemberRemovalPreview } from '../memberRemoval.js';
import {
  emitHouseholdMemberLeft,
  emitHouseholdPetRemovedNotices,
} from '../../notifications/relationshipEmitters.js';
import { revokeRemoveAllAccessToMyPets } from './revokeOwnedPetAccess.js';

async function listHouseholdMemberIds(db, householdId, { excludeUserId = null } = {}) {
  const result = await db.query(
    'SELECT user_id FROM household_members WHERE household_id = $1',
    [householdId],
  );
  return result.rows
    .map((r) => r.user_id)
    .filter((id) => id && id !== excludeUserId);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} actorId
 * @param {string} householdId
 * @param {string} targetUserId
 * @param {object} [options]
 */
export async function removeHouseholdMember(db, actorId, householdId, targetUserId, options = {}) {
  const preview = await getHouseholdMemberRemovalPreview(db, actorId, householdId, targetUserId);
  if (preview.error) return preview;

  const selfLeave = actorId === targetUserId;
  const removeAllAccess = !selfLeave && (
    options.remove_all_access_to_my_pets === true
    || options.removeAllAccessToMyPets === true
  );

  const successorUserId = options.successor_user_id || options.successorUserId || null;

  if (preview.requires_successor && !successorUserId) {
    return {
      error: 'A successor organiser is required',
      status: 409,
      code: 'successor_required',
    };
  }

  if (successorUserId) {
    const successorMembership = await getHouseholdMembership(db, householdId, successorUserId);
    if (!successorMembership || successorUserId === targetUserId) {
      return {
        error: 'Invalid successor_user_id',
        status: 400,
        code: 'validation_failed',
      };
    }
  }

  const householdRow = await db.query('SELECT name FROM households WHERE id = $1', [householdId]);
  const householdName = householdRow.rows[0]?.name || 'Household';
  const petNoticeRecipients = await listHouseholdMemberIds(db, householdId, {
    excludeUserId: targetUserId,
  });

  /** @type {import('../departure/notices.js').HouseholdPetRemovedNotice[]} */
  let petNotices = [];

  await withTransaction(db, async (client) => {
    if (preview.requires_successor && successorUserId) {
      await client.query(
        `UPDATE household_members
         SET is_organiser = true, access_tier = $3, joined_at = joined_at
         WHERE household_id = $1 AND user_id = $2`,
        [householdId, successorUserId, HOUSEHOLD_TIER_FULL],
      );
    }

    const ownedByTarget = await client.query(
      `SELECT hp.pet_id, p.user_id AS owner_user_id
       FROM household_pets hp
       INNER JOIN pets p ON p.id = hp.pet_id
       WHERE hp.household_id = $1 AND p.user_id = $2`,
      [householdId, targetUserId],
    );
    for (const row of ownedByTarget.rows) {
      const result = await removePetFromHousehold(client, {
        householdId,
        petId: row.pet_id,
        ownerUserId: row.owner_user_id,
      });
      petNotices.push(...result.notices);
    }

    await client.query(
      'DELETE FROM household_members WHERE household_id = $1 AND user_id = $2',
      [householdId, targetUserId],
    );

    if (removeAllAccess) {
      await revokeRemoveAllAccessToMyPets(client, actorId, targetUserId, householdId);
    }

    const memberCount = await client.query(
      'SELECT count(*)::int AS c FROM household_members WHERE household_id = $1',
      [householdId],
    );
    if (memberCount.rows[0].c === 0) {
      const closeResult = await closeHousehold(client, householdId);
      petNotices.push(...closeResult.notices);
    }
  });

  await emitHouseholdMemberLeft(db, {
    householdId,
    memberUserId: targetUserId,
    removedByActorId: actorId,
  });

  await emitHouseholdPetRemovedNotices(db, {
    householdName,
    notices: petNotices,
    recipientUserIds: petNoticeRecipients,
    actorUserId: actorId,
  });

  return { message: 'Member removed' };
}
