import { HOUSEHOLD_TIER_FULL, HOUSEHOLD_TIER_LOG } from './constants.js';

/**
 * Household grant for a user on a pet, or null when the pet is not in a household
 * or the user is not a member.
 * @returns {Promise<'full_access'|'can_log_care'|null>}
 */
export async function getHouseholdGrantForUser(pool, petId, userId) {
  if (!petId || !userId) return null;
  const result = await pool.query(
    `SELECT hm.access_tier
     FROM household_pets hp
     INNER JOIN household_members hm ON hm.household_id = hp.household_id
     WHERE hp.pet_id = $1 AND hm.user_id = $2
     LIMIT 1`,
    [petId, userId],
  );
  const tier = result.rows[0]?.access_tier;
  if (tier === HOUSEHOLD_TIER_FULL || tier === HOUSEHOLD_TIER_LOG) return tier;
  return null;
}

/** SQL fragment: pet row alias is readable via household membership. */
export function householdAccessiblePetSql(petAlias, userIdParam) {
  return `EXISTS (
    SELECT 1 FROM household_pets hp
    INNER JOIN household_members hm ON hm.household_id = hp.household_id
    WHERE hp.pet_id = ${petAlias}.id AND hm.user_id = ${userIdParam}
  )`;
}

export async function listHouseholdAccessForPet(pool, petId) {
  const result = await pool.query(
    `SELECT hm.user_id, hm.access_tier, hm.is_organiser, hm.joined_at,
            h.id AS household_id, h.name AS household_name,
            u.first_name, u.last_name, u.email, u.category, u.bio, u.photo_url
     FROM household_pets hp
     INNER JOIN households h ON h.id = hp.household_id
     INNER JOIN household_members hm ON hm.household_id = h.id
     INNER JOIN users u ON u.id = hm.user_id
     WHERE hp.pet_id = $1
     ORDER BY hm.joined_at`,
    [petId],
  );
  return result.rows;
}

export async function getPetHouseholdId(pool, petId) {
  const result = await pool.query(
    'SELECT household_id FROM household_pets WHERE pet_id = $1 LIMIT 1',
    [petId],
  );
  return result.rows[0]?.household_id ?? null;
}
