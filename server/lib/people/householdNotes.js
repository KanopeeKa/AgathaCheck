import { getHouseholdMembership } from '../households/authz.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string|null} householdId
 * @param {string} viewerUserId
 * @param {string|null} linkedUserId
 * @returns {Promise<string|null>}
 */
export async function householdNoteForViewer(
  pool,
  contactId,
  householdId,
  viewerUserId,
  linkedUserId,
) {
  if (!householdId || !contactId || !viewerUserId) return null;
  if (linkedUserId && linkedUserId === viewerUserId) return null;
  const membership = await getHouseholdMembership(pool, householdId, viewerUserId);
  if (!membership) return null;
  const result = await pool.query(
    `SELECT note FROM people_contact_household_notes
     WHERE contact_id = $1 AND household_id = $2`,
    [contactId, householdId],
  );
  if (result.rows.length === 0) return '';
  return result.rows[0].note ?? '';
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} contactId
 * @param {string} householdId
 * @param {string} userId
 * @param {string} note
 */
export async function upsertHouseholdNote(client, contactId, householdId, userId, note) {
  await client.query(
    `INSERT INTO people_contact_household_notes (
       contact_id, household_id, note, updated_by_user_id, updated_at
     ) VALUES ($1, $2, $3, $4, NOW())
     ON CONFLICT (contact_id, household_id)
     DO UPDATE SET
       note = EXCLUDED.note,
       updated_by_user_id = EXCLUDED.updated_by_user_id,
       updated_at = NOW()`,
    [contactId, householdId, String(note), userId],
  );
}
