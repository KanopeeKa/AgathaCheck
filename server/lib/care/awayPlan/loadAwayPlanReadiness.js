import { dateToIsoDate } from '../../calendarDate.js';
import { loadResolutionsByEntryIds } from '../absence/resolutionRepository.js';
import { evaluateCarePeriodCoverageWithResolutions } from '../absence/absenceCoverage.js';
import {
  aggregateCareCoverage,
  deriveAwayPlanReadiness,
  deriveCarerCoverage,
} from './readiness.js';
import { loadAwayPlanProjection } from './loadAwayPlanProjection.js';

/**
 * Derive Away Planning readiness for one absence (D-AWAY-002).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object[]} petRows planned_absence_pets rows
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {string} [todayIso]
 */
export async function loadAwayPlanReadiness(
  pool,
  petRows,
  startsOn,
  endsOn,
  todayIso,
  absenceId = null
) {
  const carerCoverage = deriveCarerCoverage(petRows);
  const perPetCoverage = [];

  for (const petRow of petRows) {
    const projection = await loadAwayPlanProjection(
      pool,
      petRow.pet_id,
      startsOn,
      endsOn,
      todayIso
    );
    let coverage;
    if (absenceId) {
      const entryIds = (projection.planned_care_items || []).map((row) => row.health_entry_id);
      const resolutionsByEntry = await loadResolutionsByEntryIds(pool, absenceId, entryIds);
      coverage = evaluateCarePeriodCoverageWithResolutions(
        projection,
        projection.planned_care_items || [],
        resolutionsByEntry,
        { startsOn, endsOn }
      );
    } else {
      const { evaluateCarePeriodCoverage } = await import('../carePeriodCoverage.js');
      coverage = evaluateCarePeriodCoverage(projection);
    }
    perPetCoverage.push({
      pet_id: petRow.pet_id,
      projection,
      coverage,
    });
  }

  const careCoverage = aggregateCareCoverage(perPetCoverage);
  return deriveAwayPlanReadiness(carerCoverage, careCoverage);
}

/**
 * @param {object} absenceRow
 * @param {object[]} petRows
 * @param {string} [todayIso]
 */
export async function loadAwayPlanReadinessForAbsence(pool, absenceRow, petRows, todayIso) {
  const startsOn = dateToIsoDate(absenceRow.starts_on);
  const endsOn = dateToIsoDate(absenceRow.ends_on);
  if (!startsOn || !endsOn) {
    throw new Error('Absence dates are required for readiness derivation');
  }
  return loadAwayPlanReadiness(pool, petRows, startsOn, endsOn, todayIso, absenceRow.id);
}
