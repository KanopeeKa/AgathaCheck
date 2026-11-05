import { dateToIsoDate } from '../../calendarDate.js';
import { loadPetHomeTimezone, normalizePetHomeTimezone, wallClockInTimeZone } from '../../petHomeTimezone.js';
import { userCanManageProfile } from '../../petAccess.js';
import { loadAwayPlanProjection } from '../awayPlan/loadAwayPlanProjection.js';
import {
  PLANNED_ABSENCE_STATUS_CANCELLED,
} from '../plannedAbsence.js';
import { buildAbsenceCareView } from './buildAbsenceCareView.js';
import { loadResolutionsByEntryIds } from './resolutionRepository.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 * @param {string} userId
 */
function absenceActiveTodayIso(absenceRow) {
  const tz = normalizePetHomeTimezone(absenceRow.timezone);
  return wallClockInTimeZone(tz).todayIso;
}

export async function loadHealthEntryAbsenceContext(pool, entry, userId) {
  if (!(await userCanManageProfile(pool, entry.pet_id, userId))) {
    return {
      health_entry_id: entry.id,
      pet_id: entry.pet_id,
      absences: [],
    };
  }

  const petTimeZone = await loadPetHomeTimezone(pool, entry.pet_id);
  const careTodayIso = wallClockInTimeZone(petTimeZone).todayIso;
  const result = await pool.query(
    `SELECT pa.*
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap ON pap.planned_absence_id = pa.id
     WHERE pap.pet_id = $1
       AND pa.status != $2
     ORDER BY pa.starts_on ASC`,
    [entry.pet_id, PLANNED_ABSENCE_STATUS_CANCELLED],
  );

  const absences = [];
  for (const absenceRow of result.rows) {
    const activeTodayIso = absenceActiveTodayIso(absenceRow);
    const endsOnDate = dateToIsoDate(absenceRow.ends_on);
    if (!endsOnDate || endsOnDate < activeTodayIso) continue;

    const startsOn = dateToIsoDate(absenceRow.starts_on);
    const endsOn = endsOnDate;
    if (!startsOn || !endsOn) continue;

    const projection = await loadAwayPlanProjection(
      pool,
      entry.pet_id,
      startsOn,
      endsOn,
      careTodayIso
    );
    const resolutionRows = await loadResolutionsByEntryIds(pool, absenceRow.id, [entry.id]);
    const resolutionDbRow = resolutionRows.get(entry.id) || null;

    const petCarerResult = await pool.query(
      `SELECT carer_kind, carer_user_id, carer_name, carer_note, pet_id
       FROM planned_absence_pets
       WHERE planned_absence_id = $1 AND pet_id = $2`,
      [absenceRow.id, entry.pet_id]
    );
    const petCarerRow = petCarerResult.rows[0] || null;

    const careView = buildAbsenceCareView({
      projection,
      healthEntryId: entry.id,
      startsOn,
      endsOn,
      resolutionDbRow,
      petCarerRow,
    });

    absences.push({
      planned_absence_id: absenceRow.id,
      starts_on: startsOn,
      ends_on: endsOn,
      ...careView,
    });
  }

  return {
    health_entry_id: entry.id,
    pet_id: entry.pet_id,
    absences,
  };
}
