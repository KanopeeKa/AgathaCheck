import { dateToIsoDate, timestampToIso } from '../../calendarDate.js';
import { loadResolutionsByEntryIds } from '../absence/resolutionRepository.js';
import {
  applyReviewQueueToCoverage,
  evaluateCarePeriodCoverageWithResolutions,
} from '../absence/absenceCoverage.js';
import { absenceToMap, resolvePlannedAbsenceTodayIso } from '../plannedAbsence.js';
import { loadPetHomeTimezone, wallClockInTimeZone } from '../../petHomeTimezone.js';
import { derivePerPetAwayPlanStatus } from './derivePerPetAwayPlanStatus.js';
import { loadAwayPlanProjection } from './loadAwayPlanProjection.js';
import { buildCareReviewQueue } from './reviewQueue.js';
import { petHasCarer } from './readiness.js';

/**
 * Per-pet away plan read model (phase 1 — declarer-scoped absence access unchanged).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} absenceRow planned_absences row
 * @param {object} petRow planned_absence_pets row for petId
 * @param {string} userId declarer (caller must already own absence)
 */
export async function loadPerPetAwayPlan(pool, absenceRow, petRow, userId) {
  const startsOn = dateToIsoDate(absenceRow.starts_on);
  const endsOn = dateToIsoDate(absenceRow.ends_on);
  if (!startsOn || !endsOn) {
    throw new Error('Absence dates are required for away plan');
  }

  const petTimeZone = await loadPetHomeTimezone(pool, petRow.pet_id);
  const careTodayIso = wallClockInTimeZone(petTimeZone).todayIso;
  const projection = await loadAwayPlanProjection(
    pool,
    petRow.pet_id,
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

  const declarerTodayIso = await resolvePlannedAbsenceTodayIso(pool, userId);
  const absence = {
    ...absenceToMap(absenceRow, [petRow]),
    handover_note: absenceRow.handover_note ?? null,
    last_handover_downloaded_at: timestampToIso(absenceRow.last_handover_downloaded_at),
  };

  return {
    absence_id: absenceRow.id,
    pet_id: petRow.pet_id,
    today: declarerTodayIso,
    absence,
    pet_carer: absence.pet_carers[0],
    status,
    coverage,
    review_queue: reviewQueue,
    review_care_item_count: reviewCareItemCount,
    projection,
  };
}
