import { getHouseholdMembership, userIsHouseholdOrganiser } from '../authz.js';
import { isHouseholdTier, normalizeMemberTier } from '../constants.js';
import { mapMemberRow } from './mapMemberRow.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} actorId
 * @param {string} householdId
 * @param {string} targetUserId
 * @param {object} [body]
 */
export async function patchHouseholdMember(db, actorId, householdId, targetUserId, body = {}) {
  if (!(await userIsHouseholdOrganiser(db, householdId, actorId))) {
    return { error: 'Forbidden', status: 403 };
  }

  const target = await getHouseholdMembership(db, householdId, targetUserId);
  if (!target) {
    return { error: 'Member not found', status: 404 };
  }

  const hasTier = body.access_tier !== undefined || body.accessTier !== undefined;
  const hasOrganiser = body.is_organiser !== undefined || body.isOrganiser !== undefined;

  if (!hasTier && !hasOrganiser) {
    return { error: 'No changes specified', status: 400 };
  }

  let accessTier = target.access_tier;
  let isOrganiser = target.is_organiser;

  if (hasTier) {
    const raw = body.access_tier ?? body.accessTier;
    if (!isHouseholdTier(raw)) {
      return { error: 'Invalid access_tier', status: 400 };
    }
    accessTier = raw;
  }

  if (hasOrganiser) {
    isOrganiser = Boolean(body.is_organiser ?? body.isOrganiser);
  }

  accessTier = normalizeMemberTier({ accessTier, isOrganiser });

  const demotingOrganiser = target.is_organiser === true && !isOrganiser;
  if (demotingOrganiser) {
    const others = await db.query(
      `SELECT user_id FROM household_members
       WHERE household_id = $1 AND is_organiser = true AND user_id <> $2`,
      [householdId, targetUserId],
    );
    if (others.rows.length === 0) {
      return {
        error: 'At least one organiser is required',
        status: 409,
        code: 'last_organiser',
      };
    }
  }

  await db.query(
    `UPDATE household_members
     SET access_tier = $3, is_organiser = $4
     WHERE household_id = $1 AND user_id = $2`,
    [householdId, targetUserId, accessTier, isOrganiser],
  );

  const updated = await db.query(
    `SELECT hm.*, u.first_name, u.last_name, u.email, u.photo_url
     FROM household_members hm
     INNER JOIN users u ON u.id = hm.user_id
     WHERE hm.household_id = $1 AND hm.user_id = $2`,
    [householdId, targetUserId],
  );

  return { member: mapMemberRow(updated.rows[0]) };
}
