import { carerRowToMap } from '../plannedAbsence.js';
import { isCareItemAffectedByAbsence } from './affectedCareItem.js';
import { deriveResolutionUiState } from './deriveResolutionState.js';
import {
  buildReviewOccurrence,
  enrichPlannedCareForTrip,
} from './plannedDatesInTrip.js';
import {
  defaultSuggestedDecision,
  resolutionRowToMap,
  suggestedLookedAfterFromPetCarer,
} from './resolutionRepository.js';

/**
 * Per-entry absence care read model (child E4 / D-ACP-011).
 *
 * Scheduling stays in `loadAwayPlanProjection`; this shapes one health entry's
 * slice for absence-context and resolution validation.
 *
 * @param {object} params
 * @param {object} params.projection `loadAwayPlanProjection` result
 * @param {string} params.healthEntryId
 * @param {string} params.startsOn YYYY-MM-DD
 * @param {string} params.endsOn YYYY-MM-DD
 * @param {object|null} [params.resolutionDbRow]
 * @param {object|null} [params.petCarerRow] planned_absence_pets row
 */
export function buildAbsenceCareView({
  projection,
  healthEntryId,
  startsOn,
  endsOn,
  resolutionDbRow = null,
  petCarerRow = null,
}) {
  const projectionItems = projection?.items || [];
  const plannedRow = (projection?.planned_care_items || []).find(
    (row) => row.health_entry_id === healthEntryId
  );
  const affected = plannedRow ? isCareItemAffectedByAbsence(plannedRow) : false;

  const uiState = plannedRow
    ? deriveResolutionUiState(resolutionDbRow, plannedRow, {
        startsOn,
        endsOn,
        projectionItems,
      })
    : 'nothing_due';

  const plannedCare = enrichPlannedCareForTrip(
    plannedRow,
    projectionItems,
    healthEntryId,
    startsOn,
    endsOn,
    resolutionDbRow,
  );
  const reviewOccurrence = buildReviewOccurrence(plannedCare);

  return {
    affected,
    ui_state: uiState,
    planned_care: plannedCare,
    review_occurrence: reviewOccurrence,
    resolution: resolutionDbRow ? resolutionRowToMap(resolutionDbRow) : null,
    suggested_looked_after_by: suggestedLookedAfterFromPetCarer(petCarerRow),
    suggested_decision: affected && uiState === 'not_reviewed'
      ? defaultSuggestedDecision()
      : null,
    pet_carer: petCarerRow ? carerRowToMap(petCarerRow) : null,
  };
}
