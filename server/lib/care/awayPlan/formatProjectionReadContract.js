import { enrichUncertainties, splitRoutineAndDatedItems } from './presentation.js';

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
 *
 * @param {object} projection
 * @param {object[]} entries
 */
export function formatProjectionReadContract(projection, entries) {
  const entryMap = entriesById(entries);
  const { routine_items, dated_items } = splitRoutineAndDatedItems(
    projection.items || [],
    entryMap
  );

  return {
    ...projection,
    uncertainties: enrichUncertainties(projection.uncertainties || [], entryMap),
    routine_items,
    dated_items,
  };
}
