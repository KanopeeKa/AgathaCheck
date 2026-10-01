/**
 * Next series date after a closed date — pure (used by the Care Planner).
 * Writes live in `server/lib/care/occurrence/` (D-CSM-019).
 */

import { dateToIsoDate } from '../../calendarDate.js';
import { advanceByFrequency } from '../../recurrenceHelper.js';

/**
 * Anchor-aware next series date after a calendar day is fully closed.
 *
 * @param {object} entry health_entries row
 * @param {string} closedScheduledDate YYYY-MM-DD of the due day that closed
 * @param {string|null|undefined} completedOn YYYY-MM-DD actual completion (last slot)
 * @returns {string}
 */
export function resolveNextSeriesDate(entry, closedScheduledDate, completedOn) {
  const anchor = entry.recurrence_anchor || 'from_completion';
  const completedIso = dateToIsoDate(completedOn) || closedScheduledDate;
  const base = anchor === 'from_due_date'
    ? closedScheduledDate
    : completedIso;
  return advanceByFrequency(base, entry);
}
