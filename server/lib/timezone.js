/**
 * IANA timezone validation and helpers (D24).
 */

export const DEFAULT_TIMEZONE = 'UTC';

/**
 * @param {unknown} value
 * @returns {value is string}
 */
export function isValidIanaTimezone(value) {
  if (typeof value !== 'string') return false;
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > 64) return false;
  try {
    Intl.DateTimeFormat(undefined, { timeZone: trimmed });
    return true;
  } catch {
    return false;
  }
}

/**
 * @param {unknown} value
 * @returns {string|null}
 */
export function normalizeTimezoneInput(value) {
  if (value == null || value === '') return null;
  const trimmed = String(value).trim();
  if (!isValidIanaTimezone(trimmed)) return null;
  return trimmed;
}

/**
 * @param {unknown} value
 * @returns {string}
 */
export function resolveTimezoneOrDefault(value) {
  return normalizeTimezoneInput(value) || DEFAULT_TIMEZONE;
}
