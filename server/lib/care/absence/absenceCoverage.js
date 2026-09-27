import {
  COVERAGE_POLICY_VERSION,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
  REASON_NO_PENDING_ITEMS,
  evaluateCarePeriodCoverage,
} from '../carePeriodCoverage.js';
import { deriveResolutionUiState } from './deriveResolutionState.js';
import { UI_STATE_RESOLVED } from './constants.js';
import { isCareItemAffectedByAbsence } from './affectedCareItem.js';

/**
 * Exclude pending occurrences for health entries that have a resolved absence decision (D-CIE-013).
 *
 * @param {object} projection
 * @param {object[]} plannedCareItems
 * @param {Map<string, object>} resolutionRowsByEntryId raw DB rows
 * @param {{ startsOn: string, endsOn: string }} window
 */
export function evaluateCarePeriodCoverageWithResolutions(
  projection,
  plannedCareItems,
  resolutionRowsByEntryId,
  window
) {
  const resolvedEntryIds = new Set();
  for (const row of plannedCareItems) {
    if (!isCareItemAffectedByAbsence(row)) continue;
    const resolutionRow = resolutionRowsByEntryId.get(row.health_entry_id) || null;
    const uiState = deriveResolutionUiState(resolutionRow, row, {
      startsOn: window.startsOn,
      endsOn: window.endsOn,
      projectionItems: projection.items,
    });
    if (uiState === UI_STATE_RESOLVED) {
      resolvedEntryIds.add(row.health_entry_id);
    }
  }

  if (resolvedEntryIds.size === 0) {
    return evaluateCarePeriodCoverage(projection);
  }

  const originalPending = (projection.items || []).filter(
    (item) => (item.status || 'pending') === 'pending'
  );
  const filteredItems = (projection.items || []).filter((item) => {
    if ((item.status || 'pending') !== 'pending') {
      return true;
    }
    if (resolvedEntryIds.has(item.health_entry_id)) {
      return false;
    }
    return true;
  });

  const filteredPending = filteredItems.filter(
    (item) => (item.status || 'pending') === 'pending'
  );
  if (
    originalPending.length > 0
    && filteredPending.length === 0
    && resolvedEntryIds.size > 0
  ) {
    return {
      policy_version: COVERAGE_POLICY_VERSION,
      coverage_state: COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
      reason_codes: [REASON_NO_PENDING_ITEMS],
      reassurance_available: true,
    };
  }

  return evaluateCarePeriodCoverage({
    ...projection,
    items: filteredItems,
  });
}
