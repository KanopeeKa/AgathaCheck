/**
 * Away-plan list visibility (D-ACP-011): in-window care plus stale open work
 * once the absence has started. Pre-departure overdue is attention-only.
 */

import { PLANNED_CARE_KIND_INDETERMINATE_PENDING } from './presentation.js';

/**
 * @param {object} row planned_care_items row (enriched)
 * @param {{ startsOn: string, endsOn: string, todayIso: string }} context
 * @returns {boolean}
 */
export function isPlannedCareRowVisibleOnAwayPlan(row, context) {
  const { startsOn, todayIso } = context;

  if (row.is_paused) {
    return row.in_window != null;
  }

  if (row.in_window != null) {
    return true;
  }

  const open = row.open_occurrence;
  if (!open?.scheduled_date) {
    return false;
  }

  if (todayIso >= startsOn && open.scheduled_date < startsOn) {
    return true;
  }

  return false;
}

/**
 * @param {object[]} rows
 * @param {{ startsOn: string, todayIso: string }} context
 * @returns {{ show: boolean, overdue_count: number }}
 */
export function computePreAbsenceOverdueAttention(rows, context) {
  const { startsOn, todayIso } = context;
  if (todayIso >= startsOn) {
    return { show: false, overdue_count: 0 };
  }

  let overdueCount = 0;
  for (const row of rows) {
    if (row.is_paused) continue;
    const open = row.open_occurrence;
    if (open?.open_status === 'overdue') {
      overdueCount += 1;
    }
  }

  return {
    show: overdueCount > 0,
    overdue_count: overdueCount,
  };
}

/**
 * @param {object[]} rows
 * @param {{ startsOn: string, endsOn: string, todayIso: string }} context
 * @returns {object[]}
 */
export function filterPlannedCareItemsForAwayPlan(rows, context) {
  return rows.filter((row) => isPlannedCareRowVisibleOnAwayPlan(row, context));
}

/**
 * @param {object[]} visibleRows
 * @returns {boolean}
 */
export function plannedCareShowsIndeterminateCaveat(visibleRows) {
  return visibleRows.some((row) => row.kind === PLANNED_CARE_KIND_INDETERMINATE_PENDING);
}
