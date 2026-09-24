import { buildPlannedCareItems } from './presentation.js';

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
  const plannedCareItems = buildPlannedCareItems(
    projection.items || [],
    projection.uncertainties || [],
    entryMap,
    context
  );

  const rest = { ...projection };
  delete rest.uncertainties;

  return {
    ...rest,
    planned_care_items: plannedCareItems,
  };
}
