import { dateToIsoDate } from './calendarDate.js';
import { hasPermissionForUser } from './orgPermissions.js';
import { userCanAccessPet, userOwnsPet } from './petAccess.js';

/** Allowlisted fields for associate / view-only org pet profile (Option B). */
export function redactedOrgPetToMap(row) {
  return {
    id: row.id,
    name: row.name,
    species: row.species,
    breed: row.breed || '',
    photo_path: row.photo_path || null,
    date_of_birth: row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null,
    age: row.age ?? null,
    organization_id: row.organization_id,
  };
}

export async function userCanViewRedactedOrgPet(pool, orgId, petId, userId) {
  if (!(await hasPermissionForUser(pool, userId, orgId, 'view_org_pets'))) return false;
  const result = await pool.query(
    `SELECT 1 FROM pets
     WHERE id = $1 AND organization_id = $2
       AND COALESCE(passed_away, false) = false`,
    [petId, orgId],
  );
  return result.rows.length > 0;
}

async function userHasDirectPetRelationship(pool, petId, userId) {
  if (await userOwnsPet(pool, petId, userId)) return true;
  const result = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, userId],
  );
  return result.rows.length > 0;
}

/**
 * Operational depth for organisation pets: direct pet relationship or manage_pets.
 * Non-org pets fall back to [userCanAccessPet].
 */
export async function userCanAccessOrgPetOperational(pool, petId, userId) {
  const petResult = await pool.query(
    'SELECT organization_id FROM pets WHERE id = $1',
    [petId],
  );
  const orgId = petResult.rows[0]?.organization_id;
  if (!orgId) {
    return userCanAccessPet(pool, petId, userId);
  }
  if (await userHasDirectPetRelationship(pool, petId, userId)) return true;
  return hasPermissionForUser(pool, userId, orgId, 'manage_pets');
}
