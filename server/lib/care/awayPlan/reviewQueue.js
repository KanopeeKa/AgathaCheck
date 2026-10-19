import {
  collectCurrentDatesInWindow,
  deriveResolutionUiState,
} from '../absence/deriveResolutionState.js';
import { isCareItemAffectedByAbsence } from '../absence/affectedCareItem.js';
import {
  UI_STATE_NOTHING_DUE,
  UI_STATE_RESOLVED,
} from '../absence/constants.js';

/**
 * Pending in-trip dates for one planned row (D-006).
 *
 * @param {object} plannedRow
 * @param {object[]} projectionItems
 * @param {string} startsOn
 * @param {string} endsOn
 */
export function impactedDateCountForReviewCard(plannedRow, projectionItems, startsOn, endsOn) {
  const fromWindow = plannedRow.in_window?.count;
  if (fromWindow != null && fromWindow > 0) {
    return fromWindow;
  }
  return collectCurrentDatesInWindow(
    projectionItems,
    plannedRow.health_entry_id,
    startsOn,
    endsOn
  ).length;
}

/**
 * @param {object[]} plannedCareItems
 * @param {object[]} projectionItems
 * @param {Map<string, object>} resolutionRowsByEntryId
 * @param {{ startsOn: string, endsOn: string }} window
 * @param {{ petHasCarer: boolean }} options
 * @returns {object[]}
 */
export function buildCareReviewQueue(
  plannedCareItems,
  projectionItems,
  resolutionRowsByEntryId,
  window,
  options
) {
  const { startsOn, endsOn } = window;
  const petHasCarer = options.petHasCarer === true;
  const queue = [];

  for (const row of plannedCareItems || []) {
    if (!isCareItemAffectedByAbsence(row)) {
      continue;
    }
    const resolutionRow = resolutionRowsByEntryId.get(row.health_entry_id) || null;
    const uiState = deriveResolutionUiState(resolutionRow, row, {
      startsOn,
      endsOn,
      projectionItems,
    });
    if (uiState === UI_STATE_RESOLVED || uiState === UI_STATE_NOTHING_DUE) {
      continue;
    }

    const impactedDateCount = impactedDateCountForReviewCard(
      row,
      projectionItems,
      startsOn,
      endsOn
    );
    const bulkKeepCarerEligible = petHasCarer && uiState !== UI_STATE_RESOLVED;

    queue.push({
      health_entry_id: row.health_entry_id,
      name: row.name,
      type: row.type ?? null,
      care_family: row.care_family ?? null,
      impacted_date_count: impactedDateCount,
      bulk_keep_carer_eligible: bulkKeepCarerEligible,
      needs_review: true,
    });
  }

  queue.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
  return queue;
}

/**
 * @param {object[]} reviewQueue
 * @returns {number}
 */
export function reviewCareItemCount(reviewQueue) {
  return (reviewQueue || []).length;
}
