/**
 * Pets owned by the user that other household members still rely on for access.
 * @param {import('pg').Pool|import('pg').PoolClient} db
 */
export async function listHouseholdDependentOwnedPets(db, userId) {
  const result = await db.query(
    `SELECT DISTINCT p.id, p.name, h.id AS household_id, h.name AS household_name
     FROM pets p
     INNER JOIN household_pets hp ON hp.pet_id = p.id
     INNER JOIN households h ON h.id = hp.household_id
     INNER JOIN household_members hm ON hm.household_id = h.id
     WHERE p.user_id = $1 AND hm.user_id <> $1`,
    [userId],
  );
  return result.rows;
}
