import { dateToIsoDate } from '../../calendarDate.js';
import { userCanManageCare } from '../../petAccess.js';

/**
 * Absence window when the entry's pet is on the absence and the caller may manage care.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {string} params.absenceId
 * @param {string} params.petId
 * @param {string} params.userId
 * @returns {Promise<{ ok: true, startsOn: string, endsOn: string }|{ ok: false, status: number, error: string }>}
 */
export async function loadAbsenceWindowForEntry(pool, { absenceId, petId, userId }) {
  if (!absenceId || !petId || !userId) {
    return { ok: false, status: 400, error: 'Absence context is incomplete' };
  }
  if (!(await userCanManageCare(pool, petId, userId))) {
    return { ok: false, status: 403, error: 'Forbidden' };
  }
  const result = await pool.query(
    `SELECT pa.starts_on, pa.ends_on
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap
       ON pap.planned_absence_id = pa.id AND pap.pet_id = $2
     WHERE pa.id = $1`,
    [absenceId, petId],
  );
  const row = result.rows[0];
  if (!row) {
    return { ok: false, status: 404, error: 'Absence not found' };
  }
  const startsOn = dateToIsoDate(row.starts_on);
  const endsOn = dateToIsoDate(row.ends_on);
  if (!startsOn || !endsOn) {
    return { ok: false, status: 404, error: 'Absence not found' };
  }
  return { ok: true, startsOn, endsOn };
}
