/**
 * Recurrence helpers for health entries — shared by healthEntries routes.
 */

/**
 * @param {Date|string|null} d
 * @returns {Date}
 */
export function toDateOnly(d) {
  if (!d) return new Date();
  const dt = d instanceof Date ? d : new Date(d);
  return new Date(dt.getFullYear(), dt.getMonth(), dt.getDate());
}

/**
 * @param {Date} base date-only
 * @param {object} row frequency fields
 * @returns {Date}
 */
export function advanceByFrequency(base, row) {
  const freq = row.frequency || 'once';
  const interval = Math.max(1, row.frequency_interval ?? 1);
  const customDays = Math.max(1, row.frequency_days || interval);
  const next = new Date(base);
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
  return next;
}

/**
 * Computes the next due date after marking an occurrence complete.
 *
 * @param {object} row health_entries row
 * @param {Date|string} completedOn when the occurrence actually happened (b)
 * @returns {Date|null} next due, or null for one-time entries
 */
export function nextOccurrence(row, completedOn) {
  const freq = row.frequency || 'once';
  if (freq === 'once') return null;

  const anchor = row.recurrence_anchor || 'from_completion';
  const completed = toDateOnly(completedOn);
  const base =
    anchor === 'from_due_date'
      ? toDateOnly(row.next_due_date || completed)
      : completed;
  return advanceByFrequency(base, row);
}

/**
 * @param {Date|string|null} nextDue
 * @param {Date|string|null} completedOn
 */
export function assertAtLeastOneDate(nextDue, completedOn) {
  if (!nextDue && !completedOn) {
    throw new Error('Due date or completed on date is required');
  }
}
