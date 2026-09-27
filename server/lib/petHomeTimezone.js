/**
 * Pet home timezone — IANA zone for care calendar "today" and timed overdue.
 * Separate from absence guest access timezone (People D24).
 */

import { normalizeCalendarDateInput } from './calendarDate.js';

export const DEFAULT_PET_HOME_TIMEZONE = 'UTC';

/**
 * @param {string|null|undefined} tz
 * @returns {boolean}
 */
export function isValidIanaTimeZone(tz) {
  if (!tz || typeof tz !== 'string') return false;
  const trimmed = tz.trim();
  if (!trimmed) return false;
  try {
    Intl.DateTimeFormat('en-US', { timeZone: trimmed }).format(new Date());
    return true;
  } catch {
    return false;
  }
}

/**
 * @param {string|null|undefined} raw
 * @param {string} [fallback]
 * @returns {string}
 */
export function normalizePetHomeTimezone(raw, fallback = DEFAULT_PET_HOME_TIMEZONE) {
  const candidate = raw == null ? '' : String(raw).trim();
  if (candidate && isValidIanaTimeZone(candidate)) return candidate;
  if (isValidIanaTimeZone(fallback)) return fallback;
  return DEFAULT_PET_HOME_TIMEZONE;
}

/**
 * @param {import('express').Request|null|undefined} req
 * @returns {string|null}
 */
export function clientTimezoneFromRequest(req) {
  const raw = req?.headers?.['x-client-timezone']
    ?? req?.headers?.['X-Client-Timezone'];
  if (!raw) return null;
  const value = String(Array.isArray(raw) ? raw[0] : raw).trim();
  return isValidIanaTimeZone(value) ? value : null;
}

/**
 * Default at pet create: explicit body, else client header, else UTC.
 * When People P4 lands, prefer owner account timezone before client header.
 *
 * @param {import('express').Request} req
 * @returns {string}
 */
export function resolveDefaultHomeTimezoneForCreate(req) {
  const body = req.body || {};
  const fromBody = body.homeTimezone ?? body.home_timezone;
  if (fromBody != null && String(fromBody).trim() !== '') {
    return normalizePetHomeTimezone(fromBody, DEFAULT_PET_HOME_TIMEZONE);
  }
  return normalizePetHomeTimezone(
    clientTimezoneFromRequest(req),
    DEFAULT_PET_HOME_TIMEZONE,
  );
}

/**
 * @param {object} body
 * @returns {string|undefined} undefined when field omitted
 */
export function parseHomeTimezoneBody(body) {
  if (!body) return undefined;
  if (!Object.prototype.hasOwnProperty.call(body, 'homeTimezone')
      && !Object.prototype.hasOwnProperty.call(body, 'home_timezone')) {
    return undefined;
  }
  const raw = body.homeTimezone ?? body.home_timezone;
  if (raw == null || String(raw).trim() === '') {
    return DEFAULT_PET_HOME_TIMEZONE;
  }
  return normalizePetHomeTimezone(raw, DEFAULT_PET_HOME_TIMEZONE);
}

/**
 * @param {string} timeZone IANA
 * @param {Date} [instant]
 * @returns {{ todayIso: string, nowTimeIso: string }}
 */
export function wallClockInTimeZone(timeZone, instant = new Date()) {
  const zone = normalizePetHomeTimezone(timeZone);
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: zone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  const parts = fmt.formatToParts(instant);
  const pick = (type) => parts.find((p) => p.type === type)?.value ?? '';
  const todayIso = `${pick('year')}-${pick('month')}-${pick('day')}`;
  const hour = pick('hour').padStart(2, '0');
  const minute = pick('minute').padStart(2, '0');
  return { todayIso, nowTimeIso: `${hour}:${minute}` };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @returns {Promise<string>}
 */
export async function loadPetHomeTimezone(pool, petId) {
  const result = await pool.query(
    'SELECT home_timezone FROM pets WHERE id = $1',
    [petId],
  );
  if (result.rows.length === 0) {
    return DEFAULT_PET_HOME_TIMEZONE;
  }
  return normalizePetHomeTimezone(result.rows[0].home_timezone);
}

/**
 * Calendar as-of for occurrence missed/open predicates.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {{ pet_id: string }} entry
 * @param {import('express').Request|null|undefined} req
 * @returns {Promise<{ todayIso: string, nowTimeIso: string|null, timeZone: string }>}
 */
export async function resolveOccurrenceAsOf(pool, entry, req) {
  const body = req?.body || {};
  const q = req?.query || {};
  const explicit = normalizeCalendarDateInput(
    body.as_of || body.asOf || q.as_of || q.asOf,
  );
  const timeZone = await loadPetHomeTimezone(pool, entry.pet_id);
  const wall = wallClockInTimeZone(timeZone);
  if (explicit) {
    return {
      todayIso: explicit,
      nowTimeIso: explicit === wall.todayIso ? wall.nowTimeIso : null,
      timeZone,
    };
  }
  return {
    todayIso: wall.todayIso,
    nowTimeIso: wall.nowTimeIso,
    timeZone,
  };
}
