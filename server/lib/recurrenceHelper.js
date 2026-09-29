/**
 * Recurrence helpers for health entries — shared by healthEntries routes.
 */

import { dateToIsoDate } from './calendarDate.js';
import { addSteps } from './care/schedule/seriesDates.js';

/**
 * @param {Date|string|null} d
 * @returns {{ y: number, m: number, d: number }}
 */
function calendarParts(d) {
  const iso = dateToIsoDate(d);
  if (!iso) {
    const now = new Date();
    return { y: now.getFullYear(), m: now.getMonth() + 1, d: now.getDate() };
  }
  const [y, m, day] = iso.split('-').map(Number);
  return { y, m, d: day };
}

/**
 * @param {{ y: number, m: number, d: number }} parts
 * @returns {string}
 */
function partsToIso({ y, m, d }) {
  return `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

/**
 * @param {Date|string|null} d
 * @returns {Date}
 */
export function toDateOnly(d) {
  const { y, m, d: day } = calendarParts(d);
  return new Date(y, m - 1, day);
}

/**
 * One series step from `base`. Month and year steps clamp to the month's last
 * day (D-CSM-024): 31 Jan + 1 month = 28/29 Feb, never 3 Mar.
 *
 * @param {Date|string} base calendar date
 * @param {object} row frequency fields
 * @returns {string} next due date as YYYY-MM-DD
 */
export function advanceByFrequency(base, row) {
  const { y, m, d } = calendarParts(base);
  return addSteps(partsToIso({ y, m, d }), row, 1);
}

/**
 * Computes the next due date after marking an occurrence complete.
 *
 * @param {object} row health_entries row
 * @param {Date|string} completedOn when the occurrence actually happened (b)
 * @returns {string|null} next due as YYYY-MM-DD, or null for one-time entries
 */
export function nextOccurrence(row, completedOn) {
  const freq = row.frequency || 'once';
  if (freq === 'once') return null;

  const anchor = row.recurrence_anchor || 'from_completion';
  const completedIso = dateToIsoDate(completedOn);
  const base =
    anchor === 'from_due_date'
      ? dateToIsoDate(row.next_due_date || completedIso)
      : completedIso;
  return advanceByFrequency(base, row);
}

/**
 * @param {Date|string|null} nextDue
 * @param {Date|string|null} completedOn
 */
export function assertAtLeastOneDate(nextDue, completedOn) {
  if (!dateToIsoDate(nextDue) && !dateToIsoDate(completedOn)) {
    throw new Error('Due date or completed on date is required');
  }
}
