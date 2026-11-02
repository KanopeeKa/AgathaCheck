import { closeHousehold } from '../departure/index.js';
import { pickHouseholdSuccessor } from './pickHouseholdSuccessor.js';
import { HOUSEHOLD_TIER_FULL } from '../constants.js';

/**
 * H6 — after the user row is deleted, release each household they belonged to.
 *
 * @param {import('pg').PoolClient} client
 * @param {{ memberships: Array<{ household_id: string, is_organiser?: boolean }> }} params
 * @returns {Promise<{ petNotices: import('../departure/notices.js').HouseholdPetRemovedNotice[], promotions: Array<{ householdId: string, householdName: string, promotedUserId: string }> }>}
 */
export async function releaseHouseholdsForDepartingUser(client, { memberships }) {
  /** @type {import('../departure/notices.js').HouseholdPetRemovedNotice[]} */
  const petNotices = [];
  /** @type {Array<{ householdId: string, householdName: string, promotedUserId: string }> } */
  const promotions = [];

  const householdIds = [...new Set((memberships || []).map((m) => m.household_id).filter(Boolean))];

  for (const householdId of householdIds) {
    const householdExists = await client.query(
      'SELECT name FROM households WHERE id = $1',
      [householdId],
    );
    if (householdExists.rows.length === 0) {
      continue;
    }
    const householdName = householdExists.rows[0].name || 'Household';

    const memberCount = await client.query(
      'SELECT count(*)::int AS c FROM household_members WHERE household_id = $1',
      [householdId],
    );
    if (memberCount.rows[0].c === 0) {
      const closeResult = await closeHousehold(client, householdId);
      petNotices.push(...closeResult.notices);
      continue;
    }

    const organiserCount = await client.query(
      `SELECT count(*)::int AS c FROM household_members
       WHERE household_id = $1 AND is_organiser = true`,
      [householdId],
    );
    if (organiserCount.rows[0].c === 0) {
      const successorId = await pickHouseholdSuccessor(client, householdId);
      if (successorId) {
        await client.query(
          `UPDATE household_members
           SET is_organiser = true, access_tier = $3, joined_at = joined_at
           WHERE household_id = $1 AND user_id = $2`,
          [householdId, successorId, HOUSEHOLD_TIER_FULL],
        );
        promotions.push({
          householdId,
          householdName,
          promotedUserId: successorId,
        });
      }
    }
  }

  return { petNotices, promotions };
}
