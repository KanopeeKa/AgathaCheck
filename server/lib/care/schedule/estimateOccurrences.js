/**
 * Estimate in-window occurrence dates for from_completion rhythms (D-ACP-003).
 */

import { dateToIsoDate } from '../../calendarDate.js';
import { isOccurrenceDateWithinSeries } from '../../occurrenceLifecycle.js';
import { advanceByFrequency } from '../../recurrenceHelper.js';
import { isDateInCareWindow } from './projectSchedule.js';

/**
 * @param {object} params
 * @param {object} params.entry
 * @param {object|null} params.openOccurrence earliest pending occurrence, if any
 * @param {string|null} params.lastCompletedOn ISO date of last closed occurrence
 * @param {string} params.startsOn absence start (inclusive)
 * @param {string} params.endsOn absence end (inclusive)
 * @param {string} params.todayIso calendar today
 * @returns {{ dates: string[], basis: 'estimated' | 'planned' | null }}
 */
export function estimateOccurrences({
  entry,
  openOccurrence,
  lastCompletedOn,
  startsOn,
  endsOn,
  todayIso,
}) {
  const anchor = entry.recurrence_anchor || 'from_completion';
  if (anchor === 'from_due_date') {
    return { dates: [], basis: 'planned' };
  }

  let base = null;
  if (openOccurrence) {
    const openDate = dateToIsoDate(openOccurrence.scheduled_date);
    if (openDate) {
      base = openDate >= todayIso ? openDate : todayIso;
    }
  } else if (lastCompletedOn) {
    base = lastCompletedOn;
  } else {
    const nextDue = dateToIsoDate(entry.next_due_date);
    if (nextDue) {
      base = nextDue >= todayIso ? nextDue : todayIso;
    }
  }

  if (!base) {
    return { dates: [], basis: null };
  }

  let cursor = base;
  let guard = 0;
  while (cursor < startsOn && guard < 5000) {
    if (!isOccurrenceDateWithinSeries(entry, cursor)) {
      return { dates: [], basis: null };
    }
    const next = advanceByFrequency(cursor, entry);
    if (!next || next <= cursor) break;
    cursor = next;
    guard += 1;
  }

  const dates = [];
  guard = 0;
  while (
    cursor
    && cursor <= endsOn
    && isOccurrenceDateWithinSeries(entry, cursor)
    && guard < 5000
  ) {
    if (isDateInCareWindow(cursor, startsOn, endsOn)) {
      dates.push(cursor);
    }
    const next = advanceByFrequency(cursor, entry);
    if (!next || next <= cursor) break;
    cursor = next;
    guard += 1;
  }

  return { dates, basis: dates.length > 0 ? 'estimated' : null };
}

/**
 * @param {string} scheduledDate
 * @param {string} todayIso
 * @param {string} startsOn
 * @returns {'overdue'|'due_before_absence'|'in_window'|null}
 */
export function computeOpenStatus(scheduledDate, todayIso, startsOn, endsOn) {
  if (!scheduledDate) return null;
  if (scheduledDate < todayIso) return 'overdue';
  if (scheduledDate >= startsOn && scheduledDate <= endsOn) return 'in_window';
  if (scheduledDate >= todayIso && scheduledDate < startsOn) return 'due_before_absence';
  return null;
}
