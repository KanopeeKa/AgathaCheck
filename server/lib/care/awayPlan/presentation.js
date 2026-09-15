import { leastCertain } from './certainty.js';

/**
 * @param {object[]} uncertainties
 * @param {Map<string, object>} entriesById
 */
export function enrichUncertainties(uncertainties, entriesById) {
  return uncertainties.map((uncertainty) => {
    const entry = entriesById.get(uncertainty.health_entry_id);
    return {
      ...uncertainty,
      name: entry?.name || '',
      type: entry?.type ?? null,
      care_family: entry?.care_family ?? null,
    };
  });
}

/**
 * @param {object[]} items
 */
function countStatuses(items) {
  const counts = { pending: 0, completed: 0, skipped: 0 };
  for (const item of items) {
    const status = item.status || 'pending';
    if (status in counts) {
      counts[status] += 1;
    }
  }
  return counts;
}

/**
 * @param {{ pending: number, completed: number, skipped: number }} counts
 */
function aggregateStatus(counts) {
  if (counts.pending > 0) return 'pending';
  if (counts.completed > 0 && counts.skipped === 0) return 'completed';
  if (counts.completed === 0 && counts.skipped > 0) return 'skipped';
  if (counts.completed > 0 && counts.skipped > 0) return 'mixed';
  return 'pending';
}

/**
 * @param {object} item
 * @param {object[]} constituents
 */
function buildRoutineRow(item, constituents) {
  const counts = countStatuses(constituents);
  const dates = constituents.map((row) => row.scheduled_date).sort();

  return {
    health_entry_id: item.health_entry_id,
    name: item.name,
    type: item.type,
    care_family: item.care_family,
    scheduled_time: item.scheduled_time,
    certainty: leastCertain(constituents.map((row) => row.certainty)),
    occurrence_count: constituents.length,
    status: aggregateStatus(counts),
    first_scheduled_date: dates[0] ?? item.scheduled_date,
    last_scheduled_date: dates[dates.length - 1] ?? item.scheduled_date,
    status_counts: counts,
  };
}

/**
 * Split projection items into collapsed routine rows and dated rows.
 *
 * Daily-frequency entries collapse to one row per entry + time slot (D-AWAY-006).
 *
 * @param {object[]} items
 * @param {Map<string, object>} entriesById
 * @returns {{ routine_items: object[], dated_items: object[] }}
 */
export function splitRoutineAndDatedItems(items, entriesById) {
  const routineGroups = new Map();
  const datedItems = [];

  for (const item of items) {
    const entry = entriesById.get(item.health_entry_id);
    const frequency = entry?.frequency || 'once';

    if (frequency !== 'daily') {
      datedItems.push(item);
      continue;
    }

    const timeKey = item.scheduled_time ?? '__all_day__';
    const groupKey = `${item.health_entry_id}|${timeKey}`;
    const group = routineGroups.get(groupKey) || [];
    group.push(item);
    routineGroups.set(groupKey, group);
  }

  const routineItems = [...routineGroups.values()].map((constituents) => {
    const sorted = [...constituents].sort((a, b) => {
      if (a.scheduled_date !== b.scheduled_date) {
        return a.scheduled_date.localeCompare(b.scheduled_date);
      }
      const ta = a.scheduled_time || '';
      const tb = b.scheduled_time || '';
      return ta.localeCompare(tb);
    });
    return buildRoutineRow(sorted[0], sorted);
  });

  routineItems.sort((a, b) => {
    const nameCmp = a.name.localeCompare(b.name);
    if (nameCmp !== 0) return nameCmp;
    const ta = a.scheduled_time || '';
    const tb = b.scheduled_time || '';
    return ta.localeCompare(tb);
  });

  return { routine_items: routineItems, dated_items: datedItems };
}
