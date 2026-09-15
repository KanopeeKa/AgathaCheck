import { dateToIsoDate, todayCalendarIso } from '../../lib/calendarDate.js';
import { dateRangesOverlap, PLANNED_ABSENCE_STATUS_CANCELLED } from '../../lib/care/plannedAbsence.js';

/**
 * Non-blocking overlap warnings for same pet on other active absences.
 */
export async function findOverlapWarnings(
  pool,
  userId,
  petIds,
  startsOn,
  endsOn,
  excludeAbsenceId = null,
) {
  const todayIso = todayCalendarIso();
  const result = await pool.query(
    `SELECT pa.id, pa.starts_on, pa.ends_on, pap.pet_id
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap ON pap.planned_absence_id = pa.id
     WHERE pa.user_id = $1
       AND pa.status != $2
       AND pa.ends_on >= $3::date
       AND pap.pet_id = ANY($4::uuid[])`,
    [userId, PLANNED_ABSENCE_STATUS_CANCELLED, todayIso, petIds]
  );
  const warnings = [];
  for (const row of result.rows) {
    if (excludeAbsenceId && row.id === excludeAbsenceId) continue;
    const otherStart = dateToIsoDate(row.starts_on);
    const otherEnd = dateToIsoDate(row.ends_on);
    if (!otherStart || !otherEnd) continue;
    if (!dateRangesOverlap(startsOn, endsOn, otherStart, otherEnd)) continue;
    warnings.push({
      pet_id: row.pet_id,
      conflicting_absence_id: row.id,
      conflicting_starts_on: otherStart,
      conflicting_ends_on: otherEnd,
    });
  }
  return warnings;
}

export async function loadOverlapCandidatesForAbsences(pool, userId, absences, petsByAbsence) {
  if (!absences.length) return [];
  const petIds = [...new Set(
    absences.flatMap((row) => (petsByAbsence.get(row.id) || []).map((pet) => pet.pet_id))
  )];
  if (!petIds.length) return [];
  const todayIso = todayCalendarIso();
  const result = await pool.query(
    `SELECT pa.id, pa.starts_on, pa.ends_on, pap.pet_id
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap ON pap.planned_absence_id = pa.id
     WHERE pa.user_id = $1
       AND pa.status != $2
       AND pa.ends_on >= $3::date
       AND pap.pet_id = ANY($4::uuid[])`,
    [userId, PLANNED_ABSENCE_STATUS_CANCELLED, todayIso, petIds]
  );
  return result.rows;
}

export function overlapWarningsForAbsence(absence, petRows, candidates) {
  const startsOn = dateToIsoDate(absence.starts_on);
  const endsOn = dateToIsoDate(absence.ends_on);
  if (!startsOn || !endsOn) return [];
  const petIds = new Set(petRows.map((row) => row.pet_id));
  const warnings = [];
  for (const row of candidates) {
    if (row.id === absence.id) continue;
    if (!petIds.has(row.pet_id)) continue;
    const otherStart = dateToIsoDate(row.starts_on);
    const otherEnd = dateToIsoDate(row.ends_on);
    if (!otherStart || !otherEnd) continue;
    if (!dateRangesOverlap(startsOn, endsOn, otherStart, otherEnd)) continue;
    warnings.push({
      pet_id: row.pet_id,
      conflicting_absence_id: row.id,
      conflicting_starts_on: otherStart,
      conflicting_ends_on: otherEnd,
    });
  }
  return warnings;
}
