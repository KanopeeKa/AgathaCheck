/**
 * CarePeriodCoveragePolicy — server-authoritative reassurance states for a projected window.
 *
 * Coverage is evaluated separately from projection completeness. Zero items may only
 * mean "nothing scheduled" when projection_status is complete.
 */

import { PROJECTION_STATUS_PARTIALLY_INDETERMINATE } from './carePeriodProjection.js';

export const COVERAGE_POLICY_VERSION = '1';

export const COVERAGE_STATE_NOTHING_SCHEDULED = 'nothing_scheduled';
export const COVERAGE_STATE_ALL_COMPLETED = 'all_completed';
export const COVERAGE_STATE_NO_UNRESOLVED_ITEMS = 'no_unresolved_items';
export const COVERAGE_STATE_HAS_ITEMS_TO_REVIEW = 'has_items_to_review';
export const COVERAGE_STATE_INDETERMINATE = 'indeterminate';

export const REASON_PROJECTION_PARTIALLY_INDETERMINATE = 'projection_partially_indeterminate';
export const REASON_COMPLETE_ZERO_ITEMS = 'complete_projection_zero_items';
export const REASON_PENDING_ITEMS_IN_WINDOW = 'pending_items_in_window';
export const REASON_ALL_ITEMS_COMPLETED = 'all_items_completed';
export const REASON_NO_PENDING_ITEMS = 'no_pending_items';

/**
 * @param {object} projection output from projectCareForPeriod / loadAndProjectCareForPeriod
 * @returns {{
 *   policy_version: string,
 *   coverage_state: string,
 *   reason_codes: string[],
 *   reassurance_available: boolean,
 * }}
 */
export function evaluateCarePeriodCoverage(projection) {
  if (projection.projection_status === PROJECTION_STATUS_PARTIALLY_INDETERMINATE) {
    return {
      policy_version: COVERAGE_POLICY_VERSION,
      coverage_state: COVERAGE_STATE_INDETERMINATE,
      reason_codes: [REASON_PROJECTION_PARTIALLY_INDETERMINATE],
      reassurance_available: false,
    };
  }

  const items = projection.items || [];

  if (items.length === 0) {
    return {
      policy_version: COVERAGE_POLICY_VERSION,
      coverage_state: COVERAGE_STATE_NOTHING_SCHEDULED,
      reason_codes: [REASON_COMPLETE_ZERO_ITEMS],
      reassurance_available: true,
    };
  }

  const pending = items.filter((item) => item.status === 'pending');
  if (pending.length > 0) {
    return {
      policy_version: COVERAGE_POLICY_VERSION,
      coverage_state: COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
      reason_codes: [REASON_PENDING_ITEMS_IN_WINDOW],
      reassurance_available: true,
    };
  }

  const allCompleted = items.every((item) => item.status === 'completed');
  if (allCompleted) {
    return {
      policy_version: COVERAGE_POLICY_VERSION,
      coverage_state: COVERAGE_STATE_ALL_COMPLETED,
      reason_codes: [REASON_ALL_ITEMS_COMPLETED],
      reassurance_available: true,
    };
  }

  return {
    policy_version: COVERAGE_POLICY_VERSION,
    coverage_state: COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
    reason_codes: [REASON_NO_PENDING_ITEMS],
    reassurance_available: true,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {string} [todayIso]
 */
export async function loadCarePeriodCoverage(pool, petId, startsOn, endsOn, todayIso) {
  const { loadAndProjectCareForPeriod } = await import('./carePeriodProjection.js');
  const projection = await loadAndProjectCareForPeriod(pool, petId, startsOn, endsOn, todayIso);
  const coverage = evaluateCarePeriodCoverage(projection);
  return {
    ...projection,
    coverage,
  };
}
