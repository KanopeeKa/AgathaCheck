import { buildPlannedCareItems } from './presentation.js';
import { PROJECTION_STATUS_COMPLETE, PROJECTION_STATUS_PARTIALLY_INDETERMINATE } from '../schedule/projectSchedule.js';
import {
  computePreAbsenceOverdueAttention,
  filterPlannedCareItemsForAwayPlan,
  plannedCareShowsIndeterminateCaveat,
} from './plannedCareVisibility.js';

/**
 * @param {object[]} entries
 */
function entriesById(entries) {
  return new Map(entries.map((entry) => [entry.id, entry]));
}

/**
 * Apply Away Planning projection read contract on top of raw schedule projection.
 *
 * Scheduling semantics stay in projectSchedule; this layer only shapes the read model.
 * Replaces `routine_items`/`dated_items`/`uncertainties` with a single, server-sorted
 * `planned_care_items[]` array (D-AWD-002). The raw per-occurrence `items[]` array is
 * untouched and stays on the wire (D-AWD-002, review round 2).
 *
 * D-ACP-011: `planned_care_items[]` is filtered for away-plan/PDF parity; pre-departure
 * overdue is exposed via `pre_absence_overdue_attention` only.
 *
 * @param {object} projection
 * @param {object[]} entries
 */
export function formatProjectionReadContract(projection, entries) {
  const entryMap = entriesById(entries);
  const context = {
    startsOn: projection.starts_on,
    endsOn: projection.ends_on,
    todayIso: projection.today_iso,
  };
  const allPlannedCareItems = buildPlannedCareItems(
    projection.items || [],
    projection.uncertainties || [],
    entryMap,
    context
  );

  const preAbsenceOverdueAttention = computePreAbsenceOverdueAttention(
    allPlannedCareItems,
    context
  );
  const plannedCareItems = filterPlannedCareItemsForAwayPlan(
    allPlannedCareItems,
    context
  );

  const projectionStatus = plannedCareShowsIndeterminateCaveat(plannedCareItems)
    ? PROJECTION_STATUS_PARTIALLY_INDETERMINATE
    : PROJECTION_STATUS_COMPLETE;

  const rest = { ...projection };
  delete rest.uncertainties;

  return {
    ...rest,
    projection_status: projectionStatus,
    planned_care_items: plannedCareItems,
    pre_absence_overdue_attention: preAbsenceOverdueAttention,
  };
}
