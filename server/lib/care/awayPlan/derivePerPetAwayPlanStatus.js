import { carerRowToMap } from '../plannedAbsence.js';
import {
  CARER_STATE_SET,
  CARER_STATE_UNAVAILABLE,
} from '../../people/absenceCarer.js';
import { COVERAGE_STATE_HAS_ITEMS_TO_REVIEW } from '../carePeriodCoverage.js';

export const PET_STATUS_PRIORITY_CARER_GAP = 'carer_gap';
export const PET_STATUS_PRIORITY_CARE_REVIEW = 'care_review';
export const PET_STATUS_PRIORITY_NONE = 'none';

export const PET_STATUS_COPY_NO_CARER = 'awayPlanningPetStatusNoCarer';
export const PET_STATUS_COPY_CARER_UNAVAILABLE = 'awayPlanningPetStatusCarerUnavailable';
export const PET_STATUS_COPY_REVIEW_COUNT = 'awayPlanningPetStatusReviewCount';

/**
 * One-line away plan status for pills and pet-page rows (spec §4.1 / §4.3).
 *
 * @param {object} petRow planned_absence_pets row
 * @param {{ review_care_item_count: number, coverage_state?: string }} facts
 */
export function derivePerPetAwayPlanStatus(petRow, facts) {
  const mapped = carerRowToMap(petRow);
  const reviewCount = Math.max(0, Number(facts.review_care_item_count) || 0);

  if (mapped.carer_state === CARER_STATE_UNAVAILABLE) {
    return {
      priority: PET_STATUS_PRIORITY_CARER_GAP,
      carer_state: mapped.carer_state,
      review_care_item_count: reviewCount,
      copy_key: PET_STATUS_COPY_CARER_UNAVAILABLE,
      copy_params: {},
    };
  }

  if (mapped.carer_state !== CARER_STATE_SET) {
    return {
      priority: PET_STATUS_PRIORITY_CARER_GAP,
      carer_state: mapped.carer_state,
      review_care_item_count: reviewCount,
      copy_key: PET_STATUS_COPY_NO_CARER,
      copy_params: {},
    };
  }

  if (
    reviewCount > 0
    || facts.coverage_state === COVERAGE_STATE_HAS_ITEMS_TO_REVIEW
  ) {
    return {
      priority: PET_STATUS_PRIORITY_CARE_REVIEW,
      carer_state: mapped.carer_state,
      review_care_item_count: reviewCount,
      copy_key: PET_STATUS_COPY_REVIEW_COUNT,
      copy_params: { count: reviewCount },
    };
  }

  return {
    priority: PET_STATUS_PRIORITY_NONE,
    carer_state: mapped.carer_state,
    review_care_item_count: reviewCount,
    copy_key: null,
    copy_params: {},
  };
}
