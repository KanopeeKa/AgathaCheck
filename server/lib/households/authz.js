import { v4 as uuidv4 } from 'uuid';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 */
export async function getHouseholdMembership(db, householdId, userId) {
  const result = await db.query(
    `SELECT household_id, user_id, access_tier, is_organiser, joined_at
     FROM household_members
     WHERE household_id = $1 AND user_id = $2`,
    [householdId, userId],
  );
  return result.rows[0] || null;
}

export async function userIsHouseholdOrganiser(db, householdId, userId) {
  const row = await getHouseholdMembership(db, householdId, userId);
  return Boolean(row?.is_organiser);
}

export async function userIsHouseholdMember(db, householdId, userId) {
  const row = await getHouseholdMembership(db, householdId, userId);
  return Boolean(row);
}

export async function ensureHouseholdDirectory(db, householdId) {
  const existing = await db.query(
    'SELECT id FROM people_directories WHERE household_id = $1',
    [householdId],
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const id = uuidv4();
  await db.query(
    `INSERT INTO people_directories (id, household_id, created_at, updated_at)
     VALUES ($1, $2, NOW(), NOW())
     ON CONFLICT DO NOTHING`,
    [id, householdId],
  );
  const again = await db.query(
    'SELECT id FROM people_directories WHERE household_id = $1',
    [householdId],
  );
  return again.rows[0]?.id ?? id;
}
