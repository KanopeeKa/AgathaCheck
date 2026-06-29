/**
 * Calendar-date helpers for API serialization.
 *
 * Fields backed by PostgreSQL `DATE` (or treated as calendar dates in the UI)
 * must be sent as `YYYY-MM-DD`, not UTC ISO timestamps. Using `toISOString()`
 * on a DATE read through node-pg shifts the day for clients west of UTC.
 */

/**
 * @param {Date|string|null|undefined} value
 * @returns {string|null}
 */
export function dateToIsoDate(value) {
  if (value == null || value === '') return null;
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().split('T')[0];
}
