import { findUserDisplayFields } from '../../db/sharing/shareAccessQueries.js';
import { createNotification, userDisplayName } from '../notificationHelper.js';
import { emailShareAccessChanged } from './relationshipNotificationEmail.js';
import { CO_PARENT_ROLE } from '../petAccess.js';
import { HOUSEHOLD_TIER_LOG } from '../households/constants.js';

export const NOTIFICATION_TYPE_SHARE_ACCESS_CHANGED = 'shareAccessChanged';
export const NOTIFICATION_TYPE_HOUSEHOLD_MEMBER_JOINED = 'householdMemberJoined';
export const NOTIFICATION_TYPE_HOUSEHOLD_MEMBER_LEFT = 'householdMemberLeft';
export const NOTIFICATION_TYPE_HOUSEHOLD_PET_ADDED = 'householdPetAdded';
export const NOTIFICATION_TYPE_HOUSEHOLD_PET_REMOVED = 'householdPetRemoved';
export const NOTIFICATION_TYPE_CARE_ASSIGNMENT_ASSIGNED = 'careAssignmentAssigned';

function shareRoleLabel(role) {
  return role === CO_PARENT_ROLE ? 'Co-parent' : 'Can log care';
}

function householdTierLabel(tier) {
  return tier === HOUSEHOLD_TIER_LOG ? 'Can log care' : 'Full access';
}

async function loadHouseholdName(pool, householdId) {
  const result = await pool.query(
    'SELECT name FROM households WHERE id = $1',
    [householdId],
  );
  return result.rows[0]?.name || 'Household';
}

async function listHouseholdMemberIds(pool, householdId, { excludeUserId = null } = {}) {
  const result = await pool.query(
    'SELECT user_id FROM household_members WHERE household_id = $1',
    [householdId],
  );
  return result.rows
    .map((r) => r.user_id)
    .filter((id) => id && id !== excludeUserId);
}

async function actorDisplayName(pool, userId) {
  const row = await findUserDisplayFields(pool, userId);
  return userDisplayName(row);
}

/**
 * R5 — share role changed for a pet (relationship).
 */
export async function emitShareAccessChanged(pool, {
  targetUserId,
  petId,
  petName,
  actorUserId,
  nextRole,
}) {
  if (!targetUserId || targetUserId === actorUserId) return;
  const actorName = await actorDisplayName(pool, actorUserId);
  const label = shareRoleLabel(nextRole);
  await createNotification(pool, {
    userId: targetUserId,
    petId,
    petName,
    title: 'Access updated',
    message: `${actorName} changed your access to ${petName || 'a pet'} to ${label}.`,
    type: NOTIFICATION_TYPE_SHARE_ACCESS_CHANGED,
  });
  const target = await findUserDisplayFields(pool, targetUserId);
  if (target?.email) {
    await emailShareAccessChanged(target.email, {
      actorName,
      petName: petName || 'your pet',
      roleLabel: label,
    });
  }
}

/**
 * R9 — household member joined (informational).
 */
export async function emitHouseholdMemberJoined(pool, {
  householdId,
  memberUserId,
}) {
  const [householdName, memberName, recipientIds] = await Promise.all([
    loadHouseholdName(pool, householdId),
    actorDisplayName(pool, memberUserId),
    listHouseholdMemberIds(pool, householdId, { excludeUserId: memberUserId }),
  ]);
  const message = `${memberName} joined the ${householdName} household.`;
  for (const userId of recipientIds) {
    await createNotification(pool, {
      userId,
      title: 'Household update',
      message,
      type: NOTIFICATION_TYPE_HOUSEHOLD_MEMBER_JOINED,
    });
  }
}

/**
 * R10 — member left or was removed.
 */
export async function emitHouseholdMemberLeft(pool, {
  householdId,
  memberUserId,
  removedByActorId = null,
}) {
  const householdName = await loadHouseholdName(pool, householdId);
  const memberName = await actorDisplayName(pool, memberUserId);
  const message = `${memberName} left the ${householdName} household.`;

  const remainingIds = (await listHouseholdMemberIds(pool, householdId))
    .filter((id) => id !== memberUserId);
  for (const userId of remainingIds) {
    await createNotification(pool, {
      userId,
      title: 'Household update',
      message,
      type: NOTIFICATION_TYPE_HOUSEHOLD_MEMBER_LEFT,
    });
  }

  if (memberUserId && memberUserId !== removedByActorId) {
    await createNotification(pool, {
      userId: memberUserId,
      title: 'Household update',
      message: `You left the ${householdName} household.`,
      type: NOTIFICATION_TYPE_HOUSEHOLD_MEMBER_LEFT,
    });
  }
}

/**
 * R11 — pet added to household.
 */
export async function emitHouseholdPetAdded(pool, {
  householdId,
  petId,
  petName,
  actorUserId = null,
}) {
  const householdName = await loadHouseholdName(pool, householdId);
  const message = `${petName || 'A pet'} was added to the ${householdName} household.`;
  const recipients = await listHouseholdMemberIds(pool, householdId, {
    excludeUserId: actorUserId,
  });
  for (const userId of recipients) {
    await createNotification(pool, {
      userId,
      petId,
      petName,
      title: 'Household update',
      message,
      type: NOTIFICATION_TYPE_HOUSEHOLD_PET_ADDED,
    });
  }
}

/**
 * R12 — pet removed from household (neutral, D22).
 */
export async function emitHouseholdPetRemoved(pool, {
  householdId,
  petId,
  petName,
  actorUserId = null,
}) {
  const householdName = await loadHouseholdName(pool, householdId);
  const message = `${petName || 'A pet'} is no longer in the ${householdName} household.`;
  const recipients = await listHouseholdMemberIds(pool, householdId, {
    excludeUserId: actorUserId,
  });
  for (const userId of recipients) {
    await createNotification(pool, {
      userId,
      petId,
      petName,
      title: 'Household update',
      message,
      type: NOTIFICATION_TYPE_HOUSEHOLD_PET_REMOVED,
    });
  }
}

/**
 * R16 — named carer on a planned absence period (D21).
 */
export async function emitCareAssignmentAssigned(pool, {
  assigneeUserId,
  actorUserId,
  petId,
  petName,
  startsOn,
  endsOn,
}) {
  if (!assigneeUserId || assigneeUserId === actorUserId) return;
  const actorName = await actorDisplayName(pool, actorUserId);
  const range = `${startsOn}–${endsOn}`;
  await createNotification(pool, {
    userId: assigneeUserId,
    petId,
    petName,
    title: 'Care assignment',
    message: `${actorName} asked you to look after ${petName || 'a pet'} from ${range}.`,
    type: NOTIFICATION_TYPE_CARE_ASSIGNMENT_ASSIGNED,
  });
}

export { householdTierLabel, shareRoleLabel };
