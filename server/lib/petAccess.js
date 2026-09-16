/**
 * Pet access control: Pet Parent (owner), co-parent, carer, and foster roles.
 */
import { orgPetViewerRolesSql } from './orgRoles.js';

export const CARER_ROLE = 'carer';
export const CO_PARENT_ROLE = 'co_parent';
/** Roles granted via shared pet access (Away Planning shared_user candidates). */
export const PET_ACCESS_ROLES = [CARER_ROLE, CO_PARENT_ROLE];
export const FOSTER_PET_ACCESS_ROLE = 'foster';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((r) => `'${r}'`).join(', ');

/** @deprecated Use PET_ACCESS_ROLES */
export const COLLABORATOR_ROLES = PET_ACCESS_ROLES;

export function petAccessRolesSql() {
  return PET_ACCESS_ROLES_SQL;
}

/** SQL predicate: `alias` is a pet row the caller may read or manage. */
export function accessiblePetSql(alias, userIdParam) {
  return `(
    ${alias}.user_id = ${userIdParam}
    OR EXISTS (
      SELECT 1 FROM pet_access pa
      WHERE pa.pet_id = ${alias}.id
        AND pa.user_id = ${userIdParam}
        AND pa.role IN (${PET_ACCESS_ROLES_SQL})
        AND COALESCE(pa.hidden, false) = false
    )
    OR EXISTS (
      SELECT 1 FROM pet_access pa
      WHERE pa.pet_id = ${alias}.id
        AND pa.user_id = ${userIdParam}
        AND pa.role = '${FOSTER_PET_ACCESS_ROLE}'
        AND COALESCE(pa.hidden, false) = false
    )
    OR (
      ${alias}.organization_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM organization_users ou
        WHERE ou.organization_id = ${alias}.organization_id
          AND ou.user_id = ${userIdParam}
          AND ou.role IN (${orgPetViewerRolesSql()})
      )
    )
  )`;
}

export async function userOwnsPet(pool, petId, userId) {
  if (!petId || !userId) return false;
  const result = await pool.query(
    'SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1',
    [petId, userId]
  );
  return result.rows.length > 0;
}

export async function getPetAccessRole(pool, petId, userId) {
  if (!petId || !userId) return null;
  const result = await pool.query(
    `SELECT role FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, userId]
  );
  const role = result.rows[0]?.role;
  if (!role) return null;
  if (PET_ACCESS_ROLES.includes(role) || role === FOSTER_PET_ACCESS_ROLE) {
    return role;
  }
  return null;
}

export async function userIsOwnerOrCoParent(pool, petId, userId) {
  if (!petId || !userId) return false;
  if (await userOwnsPet(pool, petId, userId)) return true;
  const result = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role = $3
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, userId, CO_PARENT_ROLE]
  );
  return result.rows.length > 0;
}

export async function userCanAccessPet(pool, petId, userId) {
  if (!petId || !userId) return false;
  if (await userOwnsPet(pool, petId, userId)) return true;
  const shared = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${PET_ACCESS_ROLES_SQL})
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, userId]
  );
  if (shared.rows.length > 0) return true;
  const foster = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role = $3
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, userId, FOSTER_PET_ACCESS_ROLE]
  );
  if (foster.rows.length > 0) return true;
  const orgMember = await pool.query(
    `SELECT 1 FROM pets p
     JOIN organization_users ou ON ou.organization_id = p.organization_id
     WHERE p.id = $1 AND ou.user_id = $2
       AND ou.role IN (${orgPetViewerRolesSql()})
     LIMIT 1`,
    [petId, userId]
  );
  return orgMember.rows.length > 0;
}

/** Active carer/co-parent or foster pet_access — not org-viewer-only. */
export async function userHasSharedAccess(pool, petId, userId) {
  if (!petId || !userId) return false;
  const shared = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${PET_ACCESS_ROLES_SQL})
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, userId]
  );
  if (shared.rows.length > 0) return true;
  const foster = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role = $3
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, userId, FOSTER_PET_ACCESS_ROLE]
  );
  return foster.rows.length > 0;
}

/** @deprecated Use userHasSharedAccess */
export const userHasCollaboratorAccess = userHasSharedAccess;

/** Owner, co-parent, carer, or foster — care events, health, weight, away planning. */
export async function userCanManageCare(pool, petId, userId) {
  if (!petId || !userId) return false;
  if (await userOwnsPet(pool, petId, userId)) return true;
  return userHasSharedAccess(pool, petId, userId);
}

/** Owner or co-parent — profile, vet, sharing admin. */
export async function userCanManageProfile(pool, petId, userId) {
  return userIsOwnerOrCoParent(pool, petId, userId);
}

/** @deprecated Use userCanManageCare */
export const userCanManagePet = userCanManageCare;

/** Owner, co-parent, or active foster during placement — may create share links. */
export async function userCanSharePet(pool, petId, userId) {
  if (!petId || !userId) return false;
  if (await userIsOwnerOrCoParent(pool, petId, userId)) return true;
  const foster = await pool.query(
    `SELECT 1 FROM pet_access pa
     INNER JOIN foster_placements fp
       ON fp.pet_id = pa.pet_id AND fp.foster_user_id = pa.user_id
     WHERE pa.pet_id = $1 AND pa.user_id = $2
       AND pa.role = $3
       AND fp.status = 'in_progress'
       AND COALESCE(pa.hidden, false) = false
     LIMIT 1`,
    [petId, userId, FOSTER_PET_ACCESS_ROLE]
  );
  return foster.rows.length > 0;
}

export async function userCanManageWeightEntry(pool, entryId, userId) {
  const result = await pool.query(
    'SELECT pet_id FROM weight_entries WHERE id = $1 LIMIT 1',
    [entryId]
  );
  const petId = result.rows[0]?.pet_id;
  if (!petId) return false;
  return userCanManageCare(pool, petId, userId);
}

export async function userCanManageHealthEntry(pool, entryId, userId) {
  const result = await pool.query(
    'SELECT pet_id FROM health_entries WHERE id = $1 LIMIT 1',
    [entryId]
  );
  const petId = result.rows[0]?.pet_id;
  if (!petId) return false;
  return userCanManageCare(pool, petId, userId);
}

export async function userCanManageHealthIssue(pool, issueId, userId) {
  const result = await pool.query(
    'SELECT pet_id FROM health_issues WHERE id = $1 LIMIT 1',
    [issueId]
  );
  const petId = result.rows[0]?.pet_id;
  if (!petId) return false;
  return userCanManageCare(pool, petId, userId);
}

/** All user IDs that should receive pet-scoped notifications (owner + shared access). */
export async function petNotificationRecipientIds(pool, petId) {
  const result = await pool.query(
    `SELECT p.user_id FROM pets p WHERE p.id = $1
     UNION
     SELECT pa.user_id FROM pet_access pa
     WHERE pa.pet_id = $1
       AND pa.role IN (${PET_ACCESS_ROLES_SQL}, '${FOSTER_PET_ACCESS_ROLE}')
       AND COALESCE(pa.hidden, false) = false`,
    [petId]
  );
  return result.rows.map((r) => r.user_id);
}
