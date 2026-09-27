import {
  RESOLUTION_DECISION_MOVE_AFTER,
  RESOLUTION_DECISION_MOVE_BEFORE,
  UI_STATE_NEEDS_REVIEW,
  UI_STATE_NOTHING_DUE,
  UI_STATE_NOT_REVIEWED,
  UI_STATE_RESOLVED,
} from './constants.js';
import { isCareItemAffectedByAbsence } from './affectedCareItem.js';
import { CARER_KIND_SHARED_USER } from '../plannedAbsence.js';

/**
 * @param {string[]} dates
 * @param {string} startsOn
 * @param {string} endsOn
 */
export function pendingDatesInAbsenceWindow(dates, startsOn, endsOn) {
  return (dates || []).filter((date) => date >= startsOn && date <= endsOn);
}

/**
 * @param {object[]} projectionItems
 * @param {string} healthEntryId
 * @param {string} startsOn
 * @param {string} endsOn
 * @returns {string[]}
 */
export function collectCurrentDatesInWindow(projectionItems, healthEntryId, startsOn, endsOn) {
  const dates = new Set();
  for (const item of projectionItems || []) {
    if (item.health_entry_id !== healthEntryId) continue;
    if ((item.status || 'pending') !== 'pending') continue;
    const date = item.scheduled_date;
    if (date && date >= startsOn && date <= endsOn) {
      dates.add(date);
    }
  }
  const rowDates = [...dates].sort();
  if (rowDates.length > 0) {
    return rowDates;
  }
  return [];
}

/**
 * @param {string[]} a
 * @param {string[]} b
 */
function sortedArraysEqual(a, b) {
  if (a.length !== b.length) return false;
  const left = [...a].sort();
  const right = [...b].sort();
  return left.every((value, index) => value === right[index]);
}

/**
 * @param {object|null} resolutionRow DB row or null
 * @param {object} plannedCareRow enriched planned_care_items row
 * @param {{
 *   startsOn: string,
 *   endsOn: string,
 *   projectionItems?: object[],
 * }} context
 * @returns {string}
 */
export function deriveResolutionUiState(resolutionRow, plannedCareRow, context) {
  if (!isCareItemAffectedByAbsence(plannedCareRow)) {
    return UI_STATE_NOTHING_DUE;
  }
  if (!resolutionRow) {
    return UI_STATE_NOT_REVIEWED;
  }

  const currentDates = collectCurrentDatesInWindow(
    context.projectionItems,
    plannedCareRow.health_entry_id,
    context.startsOn,
    context.endsOn
  );
  const decidedRaw = resolutionRow.dates_decided_for;
  const decidedDates = Array.isArray(decidedRaw)
    ? decidedRaw.map(String).sort()
    : [];

  if (resolutionRow.carer_kind === CARER_KIND_SHARED_USER && !resolutionRow.carer_user_id) {
    return UI_STATE_NEEDS_REVIEW;
  }

  if (decidedDates.length > 0 && !sortedArraysEqual(decidedDates, currentDates)) {
    return UI_STATE_NEEDS_REVIEW;
  }

  const decision = resolutionRow.decision;
  if (
    decision === RESOLUTION_DECISION_MOVE_BEFORE
    || decision === RESOLUTION_DECISION_MOVE_AFTER
  ) {
    if (pendingDatesInAbsenceWindow(currentDates, context.startsOn, context.endsOn).length > 0) {
      return UI_STATE_NEEDS_REVIEW;
    }
  }

  return UI_STATE_RESOLVED;
}
