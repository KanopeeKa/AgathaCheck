/**
 * Add/remove pets on planned absences (CARE-CONTEXT-R-034, R-035, R-036).
 */

import {
  PLANNED_ABSENCE_STATUS_ACTIVE,
  PLANNED_ABSENCE_STATUS_CANCELLED,
} from '../plannedAbsence.js';
import { GUEST_GRANT_ACTIVE, GUEST_GRANT_REVOKED } from '../../people/absenceGuestGrants.js';

const INVITE_PENDING = 'pending';

/**
 * Revoke active guest grants for one pet on an absence.
 *
 * @param {import('pg').PoolClient} client
 */
export async function revokeGuestGrantsForAbsencePet(client, absenceId, petId) {
  await client.query(
    `UPDATE planned_absence_guest_grants
     SET status = $4, revoked_at = NOW()
     WHERE planned_absence_id = $1 AND pet_id = $2 AND status = $3`,
    [absenceId, petId, GUEST_GRANT_ACTIVE, GUEST_GRANT_REVOKED],
  );
}

/**
 * Drop pending carer invite rows for a pet; remove invites left with no pets.
 *
 * @param {import('pg').PoolClient} client
 */
export async function trimCarerInvitesForAbsencePet(client, absenceId, petId) {
  await client.query(
    `DELETE FROM planned_absence_carer_invite_pets ip
     USING planned_absence_carer_invites i
     WHERE ip.invite_id = i.id
       AND i.planned_absence_id = $1
       AND ip.pet_id = $2`,
    [absenceId, petId],
  );
  await client.query(
    `DELETE FROM planned_absence_carer_invites i
     WHERE i.planned_absence_id = $1
       AND i.status = $2
       AND NOT EXISTS (
         SELECT 1 FROM planned_absence_carer_invite_pets ip
         WHERE ip.invite_id = i.id
       )`,
    [absenceId, INVITE_PENDING],
  );
}

/**
 * Clear trip decisions for this pet on this absence; care item dates unchanged.
 *
 * @param {import('pg').PoolClient} client
 */
export async function deleteAbsenceResolutionsForPet(client, absenceId, petId) {
  await client.query(
    `DELETE FROM health_entry_absence_resolutions r
     USING health_entries he
     WHERE r.health_entry_id = he.id
       AND he.pet_id = $2
       AND r.planned_absence_id = $1`,
    [absenceId, petId],
  );
}

/**
 * Remove one pet row from an absence (carer columns live on the row).
 *
 * @param {import('pg').PoolClient} client
 */
export async function deleteAbsencePetRow(client, absenceId, petId) {
  await client.query(
    `DELETE FROM planned_absence_pets
     WHERE planned_absence_id = $1 AND pet_id = $2`,
    [absenceId, petId],
  );
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} absenceId
 */
export async function countAbsencePets(client, absenceId) {
  const result = await client.query(
    `SELECT COUNT(*)::int AS count FROM planned_absence_pets WHERE planned_absence_id = $1`,
    [absenceId],
  );
  return result.rows[0]?.count ?? 0;
}

/**
 * Cancel absence and revoke all guest grants (last-pet removal / empty cleanup).
 *
 * @param {import('pg').PoolClient} client
 */
export async function cancelPlannedAbsenceInTransaction(client, absenceId, declarerUserId) {
  const result = await client.query(
    `UPDATE planned_absences
     SET status = $1, cancelled_at = NOW(), updated_at = NOW()
     WHERE id = $2 AND user_id = $3 AND status != $1
     RETURNING *`,
    [PLANNED_ABSENCE_STATUS_CANCELLED, absenceId, declarerUserId],
  );
  if (result.rows.length === 0) return null;
  await client.query(
    `UPDATE planned_absence_guest_grants
     SET status = $2, revoked_at = NOW()
     WHERE planned_absence_id = $1 AND status = $3`,
    [absenceId, GUEST_GRANT_REVOKED, GUEST_GRANT_ACTIVE],
  );
  return result.rows[0];
}

/**
 * After a pet leaves absences (delete or remove), cancel any active absence with no pets.
 *
 * @param {import('pg').PoolClient} client
 * @param {string[]} absenceIds
 */
export async function cancelEmptyActiveAbsences(client, absenceIds) {
  if (!absenceIds?.length) return;
  const empty = await client.query(
    `SELECT pa.id, pa.user_id
     FROM planned_absences pa
     WHERE pa.id = ANY($1::uuid[])
       AND pa.status = $2
       AND NOT EXISTS (
         SELECT 1 FROM planned_absence_pets pap
         WHERE pap.planned_absence_id = pa.id
       )`,
    [absenceIds, PLANNED_ABSENCE_STATUS_ACTIVE],
  );
  for (const row of empty.rows) {
    await cancelPlannedAbsenceInTransaction(client, row.id, row.user_id);
  }
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @returns {Promise<string[]>}
 */
export async function listActiveAbsenceIdsForPet(pool, petId) {
  const result = await pool.query(
    `SELECT DISTINCT pap.planned_absence_id AS id
     FROM planned_absence_pets pap
     INNER JOIN planned_absences pa ON pa.id = pap.planned_absence_id
     WHERE pap.pet_id = $1 AND pa.status = $2`,
    [petId, PLANNED_ABSENCE_STATUS_ACTIVE],
  );
  return result.rows.map((row) => row.id);
}
