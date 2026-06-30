/**
 * Recurrence helpers for health entries — shared by healthEntries routes.
 */

import { dateToIsoDate } from './calendarDate.js';

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
 * @param {Date|string} base calendar date
 * @param {object} row frequency fields
 * @returns {string} next due date as YYYY-MM-DD
 */
export function advanceByFrequency(base, row) {
  const { y, m, d } = calendarParts(base);
  const next = new Date(y, m - 1, d);
  const freq = row.frequency || 'once';
  const interval = Math.max(1, row.frequency_interval ?? 1);
  const customDays = Math.max(1, row.frequency_days || interval);
  switch (freq) {
    case 'daily':
      next.setDate(next.getDate() + interval);
      break;
    case 'weekly':
      next.setDate(next.getDate() + 7 * interval);
      break;
    case 'monthly':
      next.setMonth(next.getMonth() + interval);
      break;
    case 'yearly':
      next.setFullYear(next.getFullYear() + interval);
      break;
    case 'custom':
      next.setDate(next.getDate() + customDays);
      break;
    default:
      next.setDate(next.getDate() + interval);
  }
  return partsToIso({
    y: next.getFullYear(),
    m: next.getMonth() + 1,
    d: next.getDate(),
  });
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
