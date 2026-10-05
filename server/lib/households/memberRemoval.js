import { getHouseholdMembership } from './authz.js';
import { HOUSEHOLD_TIER_FULL } from './constants.js';

/**
 * Access grants the target keeps after household membership ends (D16).
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} actorId
 * @param {string} householdId
 * @param {string} targetUserId
 */
export async function getHouseholdMemberRemovalPreview(db, actorId, householdId, targetUserId) {
  const actorMembership = await getHouseholdMembership(db, householdId, actorId);
  if (!actorMembership) return { error: 'Forbidden', status: 403 };

  const selfPreview = actorId === targetUserId;
  if (!selfPreview && !actorMembership.is_organiser) {
    return { error: 'Forbidden', status: 403 };
  }

  const targetMembership = await getHouseholdMembership(db, householdId, targetUserId);
  if (!targetMembership) return { error: 'Member not found', status: 404 };

  const householdPets = await db.query(
    `SELECT hp.pet_id, p.name AS pet_name
     FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE hp.household_id = $1`,
    [householdId],
  );

  const remainingAccess = [];

  for (const pet of householdPets.rows) {
    const direct = await db.query(
      `SELECT role FROM pet_access
       WHERE pet_id = $1 AND user_id = $2
         AND COALESCE(hidden, false) = false
         AND role IN ('carer', 'co_parent')
       LIMIT 1`,
      [pet.pet_id, targetUserId],
    );
    if (direct.rows.length > 0) {
      remainingAccess.push({
        pet_id: pet.pet_id,
        pet_name: pet.pet_name,
        source: 'direct_share',
        role: direct.rows[0].role,
      });
    }

    const absence = await db.query(
      `SELECT pa.id AS absence_id, pa.ends_on
       FROM planned_absence_guest_grants g
       INNER JOIN planned_absences pa ON pa.id = g.planned_absence_id
       WHERE g.grantee_user_id = $1
         AND g.pet_id = $2
         AND g.status = 'active'
         AND pa.status = 'active'
         AND pa.cancelled_at IS NULL
         AND pa.ends_on >= CURRENT_DATE
       ORDER BY pa.ends_on DESC
       LIMIT 1`,
      [targetUserId, pet.pet_id],
    );
    if (absence.rows.length > 0) {
      const endsOn = absence.rows[0].ends_on;
      remainingAccess.push({
        pet_id: pet.pet_id,
        pet_name: pet.pet_name,
        source: 'absence',
        absence_id: absence.rows[0].absence_id,
        until: endsOn ? String(endsOn).split(/[T ]/)[0] : null,
      });
    }
  }

  const organisers = await db.query(
    `SELECT user_id FROM household_members
     WHERE household_id = $1 AND is_organiser = true`,
    [householdId],
  );
  const memberCount = await db.query(
    'SELECT count(*)::int AS c FROM household_members WHERE household_id = $1',
    [householdId],
  );
  const requiresSuccessor = targetMembership.is_organiser
    && organisers.rows.length === 1
    && memberCount.rows[0].c > 1;

  return {
    target_user_id: targetUserId,
    household_id: householdId,
    loses_household_access: true,
    remaining_access: remainingAccess,
    requires_successor: requiresSuccessor,
    target_access_tier: targetMembership.access_tier,
    target_is_organiser: targetMembership.is_organiser === true,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} householdId
 * @param {string} userId
 */
export async function canManageHouseholdDirectory(db, householdId, userId) {
  const membership = await getHouseholdMembership(db, householdId, userId);
  if (!membership) return false;
  return membership.is_organiser === true || membership.access_tier === HOUSEHOLD_TIER_FULL;
}
