/**
 * Care series lifecycle predicates — pure. Close/reopen are commands in
 * `server/lib/care/occurrence/commands/lifecycle.js`.
 */

import { dateToIsoDate, todayCalendarIso } from './calendarDate.js';

function isOnceEntry(row) {
  return (row.frequency || 'once') === 'once';
}

/**
 * @param {object} row health_entries row
 * @returns {string|null}
 */
export function repeatEndDateIso(row) {
  return dateToIsoDate(row.repeat_end_date);
}

/**
 * Whether the care event series is closed (manual close, once completed, or past end date).
 *
 * @param {object} row health_entries row
 * @param {string} [todayIso]
 * @returns {boolean}
 */
export function isEntrySeriesClosed(row, todayIso = todayCalendarIso()) {
  if ((row.status || 'active') === 'completed') return true;
  if (isOnceEntry(row)) {
    return Boolean(dateToIsoDate(row.completed_on));
  }
  const endIso = repeatEndDateIso(row);
  if (!endIso) return false;
  return endIso < todayIso;
}

/**
 * @param {object} row
 * @param {string} dateIso
 * @returns {boolean}
 */
export function isOccurrenceDateWithinSeries(row, dateIso) {
  const endIso = repeatEndDateIso(row);
  if (!endIso) return true;
  return dateIso <= endIso;
}
