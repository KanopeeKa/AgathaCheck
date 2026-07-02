/**
 * Pet access control for owners and collaborators (shared/guardian followers).
 *
 * Organisation-wide pet visibility is limited to super_admin and admin roles;
 * fosters see only pets they are actively fostering via foster_placements.
 */
import { orgPetViewerRolesSql } from './orgRoles.js';

export const COLLABORATOR_ROLES = ['shared', 'guardian'];
export const FOSTER_PET_ACCESS_ROLE = 'foster';

const COLLABORATOR_ROLES_SQL = COLLABORATOR_ROLES.map((r) => `'${r}'`).join(', ');

/** SQL predicate: `alias` is a pet row the caller may read or manage. */
export function accessiblePetSql(alias, userIdParam) {
  return `(
    ${alias}.user_id = ${userIdParam}
    OR EXISTS (
      SELECT 1 FROM pet_access pa
      WHERE pa.pet_id = ${alias}.id
        AND pa.user_id = ${userIdParam}
        AND pa.role IN (${COLLABORATOR_ROLES_SQL})
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

export async function userCanAccessPet(pool, petId, userId) {
  if (!petId || !userId) return false;
  if (await userOwnsPet(pool, petId, userId)) return true;
  const shared = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${COLLABORATOR_ROLES_SQL})
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

/** Owner or active collaborator — full edit access except sharing management. */
export async function userCanManagePet(pool, petId, userId) {
  return userCanAccessPet(pool, petId, userId);
}

export async function userCanManageWeightEntry(pool, entryId, userId) {
  const result = await pool.query(
    `SELECT 1 FROM weight_entries we
     JOIN pets p ON p.id = we.pet_id
     WHERE we.id = $1 AND ${accessiblePetSql('p', '$2')}
     LIMIT 1`,
    [entryId, userId]
  );
  return result.rows.length > 0;
}

export async function userCanManageHealthEntry(pool, entryId, userId) {
  const result = await pool.query(
    `SELECT 1 FROM health_entries he
     JOIN pets p ON p.id = he.pet_id
     WHERE he.id = $1 AND ${accessiblePetSql('p', '$2')}
     LIMIT 1`,
    [entryId, userId]
  );
  return result.rows.length > 0;
}

export async function userCanManageHealthIssue(pool, issueId, userId) {
  const result = await pool.query(
    `SELECT 1 FROM health_issues hi
     JOIN pets p ON p.id = hi.pet_id
     WHERE hi.id = $1 AND ${accessiblePetSql('p', '$2')}
     LIMIT 1`,
    [issueId, userId]
  );
  return result.rows.length > 0;
}

/** All user IDs that should receive pet-scoped notifications (owner + collaborators). */
export async function petNotificationRecipientIds(pool, petId) {
  const result = await pool.query(
    `SELECT p.user_id FROM pets p WHERE p.id = $1
     UNION
     SELECT pa.user_id FROM pet_access pa
     WHERE pa.pet_id = $1
       AND pa.role IN (${COLLABORATOR_ROLES_SQL}, '${FOSTER_PET_ACCESS_ROLE}')
       AND COALESCE(pa.hidden, false) = false`,
    [petId]
  );
  return result.rows.map((r) => r.user_id);
}
