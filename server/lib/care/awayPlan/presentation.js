import {
  CERTAINTY_COMPLETE,
  CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
} from '../schedule/projectSchedule.js';
import {
  RECURRENCE_ANCHOR_FROM_COMPLETION,
  RECURRENCE_ANCHOR_FROM_DUE_DATE,
} from '../schedule/recurrenceAnchorDefaults.js';
import {
  computeOpenStatus,
  estimateOccurrences,
} from '../schedule/estimateOccurrences.js';
import { isDateInCareWindow } from '../schedule/projectSchedule.js';
import { leastCertain } from './certainty.js';

export const PLANNED_CARE_KIND_RECURRING_CALENDAR = 'recurring_calendar';
export const PLANNED_CARE_KIND_RECURRING_CHAIN = 'recurring_chain';
export const PLANNED_CARE_KIND_SINGLE_ONCE = 'single_once';
export const PLANNED_CARE_KIND_INDETERMINATE_PENDING = 'indeterminate_pending';

/** Server-side sort bucket order (D-AWD-002). */
const PLANNED_CARE_KIND_ORDER = {
  [PLANNED_CARE_KIND_RECURRING_CALENDAR]: 0,
  [PLANNED_CARE_KIND_RECURRING_CHAIN]: 1,
  [PLANNED_CARE_KIND_SINGLE_ONCE]: 2,
  [PLANNED_CARE_KIND_INDETERMINATE_PENDING]: 3,
};

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
 * Distinct, sorted times of day across a group's constituents (D-AWD-002).
 *
 * @param {object[]} constituents
 * @returns {string[]}
 */
function distinctSortedTimesOfDay(constituents) {
  const times = new Set();
  for (const item of constituents) {
    if (item.scheduled_time) {
      times.add(item.scheduled_time);
    }
  }
  return [...times].sort();
}

/**
 * Earliest still-pending occurrence date among a group's constituents.
 *
 * @param {object[]} constituents
 * @returns {string|null}
 */
function earliestPendingDate(constituents) {
  const pendingDates = constituents
    .filter((item) => (item.status || 'pending') === 'pending')
    .map((item) => item.scheduled_date)
    .filter(Boolean)
    .sort();
  return pendingDates[0] ?? null;
}

function earliestMaterialisedPending(constituents) {
  const pending = constituents
    .filter(
      (item) => item.source === 'materialised' && (item.status || 'pending') === 'pending'
    )
    .sort((a, b) => a.scheduled_date.localeCompare(b.scheduled_date));
  return pending[0] ?? null;
}

/**
 * @param {object} row
 * @param {object|undefined} entry
 * @param {object[]} constituents
 * @param {{ startsOn: string, endsOn: string, todayIso: string }} context
 */
function enrichRowContract(row, entry, constituents, context) {
  const { startsOn, endsOn, todayIso } = context;
  row.is_paused = entry?.status === 'paused';

  if (row.is_paused) {
    row.open_occurrence = null;
    row.in_window = null;
    return row;
  }

  const openItem = earliestMaterialisedPending(constituents);
  if (openItem) {
    row.open_occurrence = {
      occurrence_id: openItem.occurrence_id ?? null,
      scheduled_date: openItem.scheduled_date,
      scheduled_time: openItem.scheduled_time,
      open_status: computeOpenStatus(
        openItem.scheduled_date,
        todayIso,
        startsOn,
        endsOn
      ),
    };
  } else {
    row.open_occurrence = null;
  }

  const inWindowItems = constituents.filter((item) =>
    isDateInCareWindow(item.scheduled_date, startsOn, endsOn)
  );

  const anchor = entry?.recurrence_anchor || RECURRENCE_ANCHOR_FROM_COMPLETION;
  let inWindowDates = inWindowItems.map((item) => item.scheduled_date).sort();

  if (inWindowDates.length === 0 && anchor === RECURRENCE_ANCHOR_FROM_COMPLETION) {
    const estimate = estimateOccurrences({
      entry: entry || {},
      openOccurrence: openItem
        ? { scheduled_date: openItem.scheduled_date }
        : null,
      lastCompletedOn: null,
      startsOn,
      endsOn,
      todayIso,
    });
    inWindowDates = estimate.dates;
  }

  if (inWindowDates.length === 0) {
    row.in_window = null;
    return row;
  }

  let dateBasis = 'scheduled';
  if (inWindowItems.some((item) => item.source === 'projected')) {
    dateBasis = anchor === RECURRENCE_ANCHOR_FROM_DUE_DATE ? 'planned' : 'estimated';
  } else if (
    inWindowDates.length > 0
    && inWindowItems.length === 0
    && anchor === RECURRENCE_ANCHOR_FROM_COMPLETION
  ) {
    dateBasis = 'estimated';
  }

  row.in_window = {
    first_date: inWindowDates[0],
    last_date: inWindowDates[inWindowDates.length - 1],
    count: inWindowDates.length,
    date_basis: dateBasis,
  };

  return row;
}

/**
 * Build the single-array `planned_care_items[]` row for a repeating (grouped) entry.
 *
 * @param {string} healthEntryId
 * @param {object|undefined} entry health_entries row
 * @param {object[]} constituents projected/materialised items for this entry
 * @param {object|null} uncertainty enriched uncertainty row for this entry, if any
 * @param {{ startsOn?: string, endsOn?: string, todayIso?: string }} [context]
 */
function buildGroupRow(healthEntryId, entry, constituents, uncertainty, context = {}) {
  const anchor = entry?.recurrence_anchor || RECURRENCE_ANCHOR_FROM_COMPLETION;
  const hasOccurrence = constituents.length > 0;
  const kind = !hasOccurrence
    ? PLANNED_CARE_KIND_INDETERMINATE_PENDING
    : anchor === RECURRENCE_ANCHOR_FROM_DUE_DATE
      ? PLANNED_CARE_KIND_RECURRING_CALENDAR
      : PLANNED_CARE_KIND_RECURRING_CHAIN;

  const sample = constituents[0];
  const name = entry?.name ?? sample?.name ?? '';
  const type = entry?.type ?? sample?.type ?? null;
  const careFamily = entry?.care_family ?? sample?.care_family ?? null;
  const timesOfDay = distinctSortedTimesOfDay(constituents);

  const certainties = constituents.map((item) => item.certainty);
  if (uncertainty) {
    certainties.push(CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION);
  }
  const certainty = leastCertain(certainties);

  const nextDueDate = kind === PLANNED_CARE_KIND_RECURRING_CALENDAR && timesOfDay.length <= 1
    ? earliestPendingDate(constituents)
    : null;

  const row = {
    kind,
    health_entry_id: healthEntryId,
    name,
    type,
    care_family: careFamily,
    frequency: entry?.frequency ?? null,
    frequency_interval: entry?.frequency_interval ?? null,
    times_of_day: timesOfDay,
    next_due_date: nextDueDate,
    certainty,
  };

  if (kind === PLANNED_CARE_KIND_INDETERMINATE_PENDING) {
    row.reason = uncertainty?.reason ?? null;
    row.occurrence_count = 0;
    row.status_counts = countStatuses([]);
    row.first_scheduled_date = null;
    row.last_scheduled_date = null;
    return row;
  }

  const dates = constituents.map((item) => item.scheduled_date).sort();
  row.occurrence_count = constituents.length;
  row.status_counts = countStatuses(constituents);
  row.first_scheduled_date = dates[0] ?? null;
  row.last_scheduled_date = dates[dates.length - 1] ?? null;

  if (context.startsOn && context.endsOn && context.todayIso) {
    enrichRowContract(row, entry, constituents, context);
  }

  return row;
}

/**
 * Build the single-array `planned_care_items[]` row for an ungrouped `once`-frequency
 * occurrence (D-AWD-002: never grouped, one row per occurrence).
 *
 * @param {object} item raw projection item
 * @param {object|undefined} entry health_entries row
 */
function buildSingleOnceRow(item, entry) {
  return {
    kind: PLANNED_CARE_KIND_SINGLE_ONCE,
    health_entry_id: item.health_entry_id,
    occurrence_id: item.occurrence_id ?? null,
    name: item.name,
    type: item.type,
    care_family: item.care_family,
    frequency: entry?.frequency ?? 'once',
    frequency_interval: entry?.frequency_interval ?? null,
    times_of_day: item.scheduled_time ? [item.scheduled_time] : [],
    next_due_date: null,
    certainty: item.certainty || CERTAINTY_COMPLETE,
    scheduled_date: item.scheduled_date,
    status: item.status,
  };
}

/**
 * @param {object[]} rows
 */
function sortPlannedCareItems(rows) {
  rows.sort((a, b) => {
    const orderCmp = PLANNED_CARE_KIND_ORDER[a.kind] - PLANNED_CARE_KIND_ORDER[b.kind];
    if (orderCmp !== 0) return orderCmp;
    return (a.name || '').localeCompare(b.name || '');
  });
  return rows;
}

/**
 * Build the unified `planned_care_items[]` array from raw projection output (D-AWD-002).
 *
 * Grouped by `health_entry_id` only, across every repeating `frequency` — `once`-frequency
 * occurrences are never grouped (one row per occurrence). Exactly one row per
 * `health_entry_id` for repeating entries: a `from_completion` entry with both a
 * materialised and a pending occurrence in the window still surfaces as a single
 * `recurring_chain` row, never split into a separate indeterminate row.
 *
 * The raw per-occurrence `items[]` array is untouched by this function; callers keep it
 * on the wire unchanged alongside `planned_care_items[]`.
 *
 * @param {object[]} items raw projection items (`projection.items`)
 * @param {object[]} uncertainties raw uncertainty rows (`projection.uncertainties`: health_entry_id + reason)
 * @param {Map<string, object>} entriesById
 * @param {{ startsOn?: string, endsOn?: string, todayIso?: string }} [context]
 * @returns {object[]} sorted `planned_care_items[]`
 */
export function buildPlannedCareItems(items, uncertainties, entriesById, context = {}) {
  const groupedConstituents = new Map();
  const singleOnceRows = [];

  for (const item of items) {
    const entry = entriesById.get(item.health_entry_id);
    const frequency = entry?.frequency || 'once';

    if (frequency === 'once') {
      singleOnceRows.push(buildSingleOnceRow(item, entry));
      continue;
    }

    const constituents = groupedConstituents.get(item.health_entry_id) || [];
    constituents.push(item);
    groupedConstituents.set(item.health_entry_id, constituents);
  }

  const uncertaintyByEntryId = new Map();
  for (const uncertainty of uncertainties) {
    uncertaintyByEntryId.set(uncertainty.health_entry_id, uncertainty);
  }

  const groupedEntryIds = new Set([
    ...groupedConstituents.keys(),
    ...uncertaintyByEntryId.keys(),
  ]);

  const groupRows = [...groupedEntryIds].map((healthEntryId) => buildGroupRow(
    healthEntryId,
    entriesById.get(healthEntryId),
    groupedConstituents.get(healthEntryId) || [],
    uncertaintyByEntryId.get(healthEntryId) || null,
    context
  ));

  return sortPlannedCareItems([...groupRows, ...singleOnceRows]);
}
