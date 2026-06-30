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
  const s = String(value).trim();
  const datePart = s.split('T')[0];
  if (/^\d{4}-\d{2}-\d{2}$/.test(datePart)) return datePart;
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  // node-pg reads PostgreSQL DATE as midnight UTC.
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

/**
 * Normalizes a request-body calendar date to `YYYY-MM-DD` for DB writes.
 *
 * @param {Date|string|null|undefined} value
 * @returns {string|null}
 */
export function normalizeCalendarDateInput(value) {
  return dateToIsoDate(value);
}

/**
 * Today's calendar date in the server local timezone as `YYYY-MM-DD`.
 *
 * @returns {string}
 */
export function todayCalendarIso() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}
