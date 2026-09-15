/**
 * Authoritative series pause/resume primitives (CSM-9).
 */

import {
  dateToIsoDate,
  normalizeCalendarDateInput,
  todayCalendarIso,
} from '../../calendarDate.js';
import {
  insertCareScheduleEvent,
  SCHEDULE_EVENT_PAUSED,
  SCHEDULE_EVENT_RESUMED,
} from './scheduleEventLedger.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} params.userId
 * @param {string|Date} [params.pausedFrom] calendar day pause starts (defaults to today)
 * @param {string} [params.reasonCode]
 * @param {string} [params.reasonNote]
 * @param {Date} [params.occurredAt]
 * @returns {Promise<{ entry: object, pausedSince: string, scheduleEventId: string }|null>}
 */
export async function pauseSeries(pool, {
  entry,
  userId,
  pausedFrom,
  reasonCode = null,
  reasonNote = null,
  occurredAt = new Date(),
}) {
  if (entry.status !== 'active') return null;

  const pausedSinceIso = normalizeCalendarDateInput(pausedFrom) || todayCalendarIso();

  const result = await pool.query(
    `UPDATE health_entries SET status = 'paused', paused_since = $1, updated_at = NOW()
     WHERE id = $2 AND status = 'active'
     RETURNING *`,
    [pausedSinceIso, entry.id],
  );
  if (result.rows.length === 0) return null;

  const scheduleEventId = await insertCareScheduleEvent(pool, {
    healthEntryId: entry.id,
    eventType: SCHEDULE_EVENT_PAUSED,
    fromDate: pausedSinceIso,
    reasonCode,
    reasonNote,
    actorUserId: userId,
    occurredAt,
    idempotencyKey: `paused:${entry.id}:${pausedSinceIso}`,
  });

  return {
    entry: result.rows[0],
    pausedSince: pausedSinceIso,
    scheduleEventId,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} params.userId
 * @param {string} [params.reasonCode]
 * @param {string} [params.reasonNote]
 * @param {Date} [params.occurredAt]
 * @returns {Promise<{ entry: object, scheduleEventId: string }|null>}
 */
export async function resumeSeries(pool, {
  entry,
  userId,
  reasonCode = null,
  reasonNote = null,
  occurredAt = new Date(),
}) {
  if (entry.status !== 'paused') return null;

  const pausedSinceIso = dateToIsoDate(entry.paused_since);

  const result = await pool.query(
    `UPDATE health_entries SET status = 'active', paused_since = NULL, updated_at = NOW()
     WHERE id = $1 AND status = 'paused'
     RETURNING *`,
    [entry.id],
  );
  if (result.rows.length === 0) return null;

  const scheduleEventId = await insertCareScheduleEvent(pool, {
    healthEntryId: entry.id,
    eventType: SCHEDULE_EVENT_RESUMED,
    fromDate: pausedSinceIso,
    reasonCode,
    reasonNote,
    actorUserId: userId,
    occurredAt,
    idempotencyKey: `resumed:${entry.id}:${pausedSinceIso || 'unknown'}`,
  });

  return {
    entry: result.rows[0],
    scheduleEventId,
  };
}
