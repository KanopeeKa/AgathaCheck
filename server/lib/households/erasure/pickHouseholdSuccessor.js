import { HOUSEHOLD_TIER_FULL, HOUSEHOLD_TIER_LOG } from '../constants.js';

/**
 * H2 — prefer longest-standing Full access member, else Can log care (promoted to Full access).
 *
 * @param {import('pg').PoolClient} client
 * @param {string} householdId
 * @returns {Promise<string|null>}
 */
export async function pickHouseholdSuccessor(client, householdId) {
  const full = await client.query(
    `SELECT user_id FROM household_members
     WHERE household_id = $1 AND access_tier = $2
     ORDER BY joined_at ASC, user_id ASC
     LIMIT 1`,
    [householdId, HOUSEHOLD_TIER_FULL],
  );
  if (full.rows[0]?.user_id) {
    return full.rows[0].user_id;
  }

  const logTier = await client.query(
    `SELECT user_id FROM household_members
     WHERE household_id = $1 AND access_tier = $2
     ORDER BY joined_at ASC, user_id ASC
     LIMIT 1`,
    [householdId, HOUSEHOLD_TIER_LOG],
  );
  return logTier.rows[0]?.user_id ?? null;
}
