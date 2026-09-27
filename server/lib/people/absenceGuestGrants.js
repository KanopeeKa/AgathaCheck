import { v4 as uuidv4 } from 'uuid';

import { HOUSEHOLD_TIER_FULL } from '../households/constants.js';
import { getHouseholdGrantForUser } from '../households/petAccessGrants.js';
import { userIsOwnerOrCoParent } from '../petAccess.js';

const PLANNED_ABSENCE_STATUS_ACTIVE = 'active';

export const GUEST_GRANT_ACTIVE = 'active';
export const GUEST_GRANT_REVOKED = 'revoked';
export const GUEST_GRANT_EXPIRED = 'expired';

/**
 * SQL predicate: pet alias readable via an active absence guest grant in-window.
 *
 * @param {string} petAlias
 * @param {string} userIdParam e.g. `$1`
 */
export function absenceGuestAccessiblePetSql(petAlias, userIdParam) {
  return `EXISTS (
    SELECT 1
    FROM planned_absence_guest_grants g
    INNER JOIN planned_absences pa ON pa.id = g.planned_absence_id
    WHERE g.grantee_user_id = ${userIdParam}
      AND g.pet_id = ${petAlias}.id
      AND g.status = '${GUEST_GRANT_ACTIVE}'
      AND pa.status = '${PLANNED_ABSENCE_STATUS_ACTIVE}'
      AND (CURRENT_TIMESTAMP AT TIME ZONE COALESCE(pa.timezone, 'UTC'))::date
          BETWEEN pa.starts_on AND pa.ends_on
  )`;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} userId
 * @returns {Promise<boolean>}
 */
export async function userHasActiveAbsenceGuestAccess(pool, petId, userId) {
  if (!petId || !userId) return false;
  const result = await pool.query(
    `SELECT 1
     FROM planned_absence_guest_grants g
     INNER JOIN planned_absences pa ON pa.id = g.planned_absence_id
     WHERE g.grantee_user_id = $1
       AND g.pet_id = $2
       AND g.status = $3
       AND pa.status = $4
       AND (CURRENT_TIMESTAMP AT TIME ZONE COALESCE(pa.timezone, 'UTC'))::date
           BETWEEN pa.starts_on AND pa.ends_on
     LIMIT 1`,
    [userId, petId, GUEST_GRANT_ACTIVE, PLANNED_ABSENCE_STATUS_ACTIVE],
  );
  return result.rows.length > 0;
}

/**
 * Record owner or household Full access on the pet (D19).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} userId
 */
export async function userCanGrantAbsenceGuestForPet(pool, petId, userId) {
  if (!petId || !userId) return false;
  if (await userIsOwnerOrCoParent(pool, petId, userId)) return true;
  const tier = await getHouseholdGrantForUser(pool, petId, userId);
  return tier === HOUSEHOLD_TIER_FULL;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 */
export async function revokeActiveGuestGrantsForAbsence(pool, absenceId) {
  if (!absenceId) return;
  await pool.query(
    `UPDATE planned_absence_guest_grants
     SET status = $2, revoked_at = NOW()
     WHERE planned_absence_id = $1 AND status = $3`,
    [absenceId, GUEST_GRANT_REVOKED, GUEST_GRANT_ACTIVE],
  );
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 * @param {string[]} newPetIds
 * @param {string} actorUserId
 */
export async function extendGuestGrantsToPets(pool, absenceId, newPetIds, actorUserId) {
  if (!Array.isArray(newPetIds) || newPetIds.length === 0) return;
  const grantees = await pool.query(
    `SELECT DISTINCT grantee_user_id, contact_id, granted_by_user_id
     FROM planned_absence_guest_grants
     WHERE planned_absence_id = $1 AND status = $2`,
    [absenceId, GUEST_GRANT_ACTIVE],
  );
  if (grantees.rows.length === 0) return;
  for (const row of grantees.rows) {
    for (const petId of newPetIds) {
      await pool.query(
        `INSERT INTO planned_absence_guest_grants (
           id, planned_absence_id, pet_id, grantee_user_id, granted_by_user_id,
           contact_id, status
         )
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (planned_absence_id, pet_id, grantee_user_id) DO NOTHING`,
        [
          uuidv4(),
          absenceId,
          petId,
          row.grantee_user_id,
          actorUserId || row.granted_by_user_id,
          row.contact_id,
          GUEST_GRANT_ACTIVE,
        ],
      );
    }
  }
}

/**
 * @param {object} params
 * @param {object} params.existing
 * @param {string} params.newStartsOn
 * @param {string} params.newEndsOn
 * @param {string[]} params.oldPetIds
 * @param {string[]} params.newPetIds
 * @param {boolean} params.hasActiveGrants
 */
export function detectGuestAccessWiden({
  existing,
  newStartsOn,
  newEndsOn,
  oldPetIds,
  newPetIds,
  hasActiveGrants,
}) {
  if (!hasActiveGrants) {
    return { needsConfirm: false, extendsDates: false, addedPetIds: [] };
  }
  const oldEnd = existing.ends_on;
  const extendsDates = newEndsOn > oldEnd;
  const oldSet = new Set(oldPetIds);
  const addedPetIds = newPetIds.filter((id) => !oldSet.has(id));
  const needsConfirm = extendsDates || addedPetIds.length > 0;
  return { needsConfirm, extendsDates, addedPetIds };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 */
export async function absenceHasActiveGuestGrants(pool, absenceId) {
  const result = await pool.query(
    `SELECT 1 FROM planned_absence_guest_grants
     WHERE planned_absence_id = $1 AND status = $2 LIMIT 1`,
    [absenceId, GUEST_GRANT_ACTIVE],
  );
  return result.rows.length > 0;
}
