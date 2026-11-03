import { dateToIsoDate, timestampToIso } from '../../calendarDate.js';
import { loadResolutionsByEntryIds } from '../absence/resolutionRepository.js';
import {
  applyReviewQueueToCoverage,
  evaluateCarePeriodCoverageWithResolutions,
} from '../absence/absenceCoverage.js';
import {
  PLANNED_ABSENCE_STATUS_CANCELLED,
  absenceToMap,
  resolvePlannedAbsenceTodayIso,
} from '../plannedAbsence.js';
import { loadPetHomeTimezone, wallClockInTimeZone } from '../../petHomeTimezone.js';
import { derivePerPetAwayPlanStatus } from './derivePerPetAwayPlanStatus.js';
import { loadAwayPlanProjection } from './loadAwayPlanProjection.js';
import { buildCareReviewQueue } from './reviewQueue.js';
import { petHasCarer } from './readiness.js';

/**
 * Current and upcoming away plans for one pet (declarer-owned absences only in phase 1).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} userId
 */
export async function listPetPlannedAbsences(pool, petId, userId) {
  const todayIso = await resolvePlannedAbsenceTodayIso(pool, userId);
  const result = await pool.query(
    `SELECT pa.*
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap
       ON pap.planned_absence_id = pa.id AND pap.pet_id = $2
     WHERE pa.user_id = $1
       AND pa.status != $3
       AND pa.ends_on >= $4::date
     ORDER BY pa.starts_on ASC`,
    [userId, petId, PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
  );

  const petTimeZone = await loadPetHomeTimezone(pool, petId);
  const careTodayIso = wallClockInTimeZone(petTimeZone).todayIso;

  const items = [];
  for (const absenceRow of result.rows) {
    const petRowResult = await pool.query(
      `SELECT pet_id, carer_kind, carer_user_id, carer_name, carer_note, pet_note, contact_id
       FROM planned_absence_pets
       WHERE planned_absence_id = $1 AND pet_id = $2`,
      [absenceRow.id, petId],
    );
    const petRow = petRowResult.rows[0];
    if (!petRow) continue;

    const startsOn = dateToIsoDate(absenceRow.starts_on);
    const endsOn = dateToIsoDate(absenceRow.ends_on);
    if (!startsOn || !endsOn) continue;

    const projection = await loadAwayPlanProjection(
      pool,
      petId,
      startsOn,
      endsOn,
      careTodayIso,
    );
    const entryIds = (projection.planned_care_items || []).map((row) => row.health_entry_id);
    const resolutionsByEntry = await loadResolutionsByEntryIds(
      pool,
      absenceRow.id,
      entryIds,
    );
    const reviewQueue = buildCareReviewQueue(
      projection.planned_care_items || [],
      projection.items || [],
      resolutionsByEntry,
      { startsOn, endsOn },
      { petHasCarer: petHasCarer(petRow) },
    );
    const coverage = applyReviewQueueToCoverage(
      evaluateCarePeriodCoverageWithResolutions(
        projection,
        projection.planned_care_items || [],
        resolutionsByEntry,
        { startsOn, endsOn },
      ),
      reviewQueue,
    );
    const reviewCareItemCount = reviewQueue.length;
    const status = derivePerPetAwayPlanStatus(petRow, {
      review_care_item_count: reviewCareItemCount,
      coverage_state: coverage.coverage_state,
    });

    items.push({
      absence_id: absenceRow.id,
      pet_id: petId,
      absence: {
        ...absenceToMap(absenceRow, [petRow]),
        handover_note: absenceRow.handover_note ?? null,
        last_handover_downloaded_at: timestampToIso(absenceRow.last_handover_downloaded_at),
      },
      status,
      review_care_item_count: reviewCareItemCount,
      coverage_state: coverage.coverage_state,
    });
  }

  return { pet_id: petId, today: todayIso, items };
}
