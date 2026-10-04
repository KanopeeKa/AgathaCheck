import { resolutionRowToMap } from './resolutionRepository.js';

/**
 * Pending occurrence dates for one care item inside the absence window (trip context).
 *
 * @param {object[]} projectionItems
 * @param {string} healthEntryId
 * @param {string} startsOn
 * @param {string} endsOn
 */
export function listPlannedDatesInTrip(projectionItems, healthEntryId, startsOn, endsOn) {
  const rows = [];
  for (const item of projectionItems || []) {
    if (item.health_entry_id !== healthEntryId) continue;
    if ((item.status || 'pending') !== 'pending') continue;
    const date = item.scheduled_date;
    if (!date || date < startsOn || date > endsOn) continue;
    rows.push({
      scheduled_date: date,
      occurrence_id: item.occurrence_id ?? null,
      scheduled_time: item.scheduled_time ?? null,
      source: item.source ?? null,
    });
  }
  rows.sort((a, b) => a.scheduled_date.localeCompare(b.scheduled_date));
  return rows;
}

/**
 * @param {object} plannedRow enriched planned_care_items row
 * @param {object[]} projectionItems
 * @param {string} healthEntryId
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {object|null} resolutionDbRow
 */
export function enrichPlannedCareForTrip(
  plannedRow,
  projectionItems,
  healthEntryId,
  startsOn,
  endsOn,
  resolutionDbRow,
) {
  if (!plannedRow) return null;
  const enriched = { ...plannedRow };
  enriched.planned_dates = listPlannedDatesInTrip(
    projectionItems,
    healthEntryId,
    startsOn,
    endsOn,
  );
  if (resolutionDbRow) {
    const mapped = resolutionRowToMap(resolutionDbRow);
    if (mapped.looked_after_by) {
      enriched.looked_after_by = mapped.looked_after_by;
    }
  }
  return enriched;
}

/**
 * Real occurrence for Review date — no ensure-open step (D-ACP-011).
 *
 * @param {object|null} plannedRow
 */
export function buildReviewOccurrence(plannedRow) {
  if (!plannedRow) return null;
  const occurrenceId = plannedRow.open_occurrence?.occurrence_id
    ?? plannedRow.occurrence_id
    ?? null;
  const scheduledDate = plannedRow.open_occurrence?.scheduled_date
    ?? plannedRow.scheduled_date
    ?? plannedRow.next_due_date
    ?? plannedRow.in_window?.first_date
    ?? null;
  if (!occurrenceId || !scheduledDate) return null;
  return {
    occurrence_id: occurrenceId,
    scheduled_date: scheduledDate,
    scheduled_time: plannedRow.open_occurrence?.scheduled_time
      ?? (plannedRow.times_of_day?.[0] ?? null),
  };
}
