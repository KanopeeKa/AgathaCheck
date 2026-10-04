/**
 * "Now" for care reads and commands (D-CIE-028, INV-7): the pet's home
 * calendar day and wall clock. The test clock header `X-Care-As-Of` replaces
 * the instant in development, test and ci only.
 */

import { normalizeCalendarDateInput } from '../../calendarDate.js';
import {
  loadPetHomeTimezone,
  wallClockInTimeZone,
} from '../../petHomeTimezone.js';
import { logger } from '../../logger.js';

export const CARE_TEST_CLOCK_HEADER = 'x-care-as-of';
const TEST_CLOCK_ENVS = new Set(['development', 'test', 'ci']);

/**
 * @returns {boolean}
 */
export function isCareTestClockEnabled() {
  const appEnv = process.env.APP_ENV;
  if (appEnv) return TEST_CLOCK_ENVS.has(appEnv);
  if (process.env.E2E === '1') return true;
  return process.env.NODE_ENV === 'test';
}

/**
 * Parse `YYYY-MM-DDTHH:MM` (seconds and zone suffix ignored).
 *
 * @param {string|null|undefined} raw
 * @returns {{ todayIso: string, nowTimeIso: string }|null}
 */
export function parseCareClock(raw) {
  if (!raw) return null;
  const value = String(Array.isArray(raw) ? raw[0] : raw).trim();
  const m = /^(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}):(\d{2}))?/.exec(value);
  if (!m) return null;
  return { todayIso: m[1], nowTimeIso: m[2] ? `${m[2]}:${m[3]}` : '12:00' };
}

/**
 * @param {import('express').Request|null|undefined} req
 * @returns {{ todayIso: string, nowTimeIso: string }|null}
 */
export function careClockFromRequest(req) {
  const raw = req?.headers?.[CARE_TEST_CLOCK_HEADER];
  if (!raw) return null;
  if (!isCareTestClockEnabled()) {
    logger.warn({ path: req?.path }, 'care test clock header ignored outside development/test/ci');
    return null;
  }
  return parseCareClock(raw);
}

/**
 * @param {string} timeZone
 * @param {{ todayIso: string, nowTimeIso: string }|null} [clock]
 * @param {Date} [instant]
 * @returns {{ todayIso: string, nowTimeIso: string, timeZone: string }}
 */
export function careAsOfForZone(timeZone, clock = null, instant = new Date()) {
  if (clock) return { ...clock, timeZone };
  return { ...wallClockInTimeZone(timeZone, instant), timeZone };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {{ pet_id: string }} entry
 * @param {import('express').Request|null|undefined} [req]
 * @returns {Promise<{ todayIso: string, nowTimeIso: string, timeZone: string }>}
 */
export async function resolveCareAsOf(db, entry, req = null) {
  const timeZone = await loadPetHomeTimezone(db, entry.pet_id);
  return careAsOfForZone(timeZone, careClockFromRequest(req));
}

/**
 * Read-only listings may still pass `as_of` (calendar day) explicitly.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {{ pet_id: string }} entry
 * @param {import('express').Request|null|undefined} req
 */
export async function resolveCareAsOfForRead(db, entry, req) {
  const asOf = await resolveCareAsOf(db, entry, req);
  const explicit = normalizeCalendarDateInput(req?.query?.as_of || req?.query?.asOf);
  if (explicit && explicit !== asOf.todayIso) {
    return { ...asOf, todayIso: explicit, nowTimeIso: explicit < asOf.todayIso ? '23:59' : '00:00' };
  }
  return asOf;
}

/**
 * @param {{ todayIso: string, nowTimeIso: string, timeZone: string }} asOf
 * @returns {{ date: string, time: string, timezone: string }}
 */
export function asOfToWire(asOf) {
  return { date: asOf.todayIso, time: asOf.nowTimeIso, timezone: asOf.timeZone };
}
