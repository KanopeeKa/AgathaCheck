/**
 * Timestamp-aware undo of the most recent schedule action (CSM-8).
 */

import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { syncNextDueDateFromOccurrences } from '../../occurrenceScheduling.js';
import { advanceSeries } from './advanceSeries.js';
import {
  SCHEDULE_EVENT_CADENCE_ADJUSTED,
  SCHEDULE_EVENT_PAUSED,
  SCHEDULE_EVENT_RESCHEDULED,
  SCHEDULE_EVENT_RESUMED,
  SCHEDULE_EVENT_SKIPPED,
} from './scheduleEventLedger.js';

/**
 * @typedef {'complete'|'skip'|'rescheduled'|'paused'|'resumed'|'cadence_adjusted'} ScheduleActionType
 */

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} entryId
 * @returns {Promise<{
 *   kind: ScheduleActionType,
 *   occurrence?: object,
 *   event?: object,
 *   timestamp: number,
 * }|null>}
 */
async function resolveLastScheduleAction(pool, entryId) {
  const [occResult, eventResult] = await Promise.all([
    pool.query(
      `SELECT * FROM health_occurrences
       WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')
       ORDER BY marked_at DESC NULLS LAST
       LIMIT 1`,
      [entryId],
    ),
    pool.query(
      `SELECT * FROM care_schedule_events
       WHERE health_entry_id = $1
       ORDER BY occurred_at DESC
       LIMIT 1`,
      [entryId],
    ),
  ]);

  const occurrence = occResult.rows[0] || null;
  const event = eventResult.rows[0] || null;
  if (!occurrence && !event) return null;

  const occTs = occurrence?.marked_at ? new Date(occurrence.marked_at).getTime() : -1;
  const eventTs = event?.occurred_at ? new Date(event.occurred_at).getTime() : -1;

  if (
    occurrence?.status === 'skipped'
    && event?.event_type === SCHEDULE_EVENT_SKIPPED
    && event.health_occurrence_id === occurrence.id
  ) {
    return {
      kind: 'skip',
      occurrence,
      event,
      timestamp: Math.max(occTs, eventTs),
    };
  }

  if (occurrence && (occTs >= eventTs || !event)) {
    if (occurrence.status === 'completed') {
      return { kind: 'complete', occurrence, timestamp: occTs };
    }
    if (occurrence.status === 'skipped') {
      return { kind: 'skip', occurrence, event, timestamp: occTs };
    }
  }

  if (event) {
    return {
      kind: event.event_type,
      event,
      timestamp: eventTs,
    };
  }

  return null;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} occurrenceId
 * @param {string} entryId
 */
async function reopenOccurrence(pool, occurrenceId, entryId) {
  const result = await pool.query(
    `UPDATE health_occurrences SET status = 'pending', completed_on = NULL,
      completion_timing = NULL, marked_at = NULL, marked_by_user_id = NULL,
      notes = '', updated_at = NOW()
     WHERE id = $1 AND health_entry_id = $2
       AND status IN ('completed', 'skipped')
     RETURNING *`,
    [occurrenceId, entryId],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} params.userId
 * @param {string} [params.occurrenceId] optional constraint for per-occurrence undo
 * @param {string} [params.todayIso]
 * @returns {Promise<{
 *   actionType: ScheduleActionType,
 *   entry: object,
 *   occurrence?: object,
 *   nextDueDate?: string|null,
 *   scheduleEventId?: string,
 * }|null>}
 */
export async function undoLastAction(pool, {
  entry,
  userId: _userId,
  occurrenceId = null,
  todayIso = todayCalendarIso(),
}) {
  const action = await resolveLastScheduleAction(pool, entry.id);
  if (!action) return null;

  if (occurrenceId) {
    const matchesOccurrence = action.occurrence?.id === occurrenceId
      || action.event?.health_occurrence_id === occurrenceId;
    const seriesLevel = ['paused', 'resumed', 'cadence_adjusted'].includes(action.kind);
    if (!matchesOccurrence && !seriesLevel) return null;
    if (seriesLevel) return null;
  }

  switch (action.kind) {
    case 'complete':
    case 'skip': {
      const reopened = await reopenOccurrence(pool, action.occurrence.id, entry.id);
      if (!reopened) return null;
      const nextDueDate = await syncNextDueDateFromOccurrences(pool, entry.id);
      const refreshed = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entry.id],
      );
      return {
        actionType: action.kind,
        entry: refreshed.rows[0],
        occurrence: reopened,
        nextDueDate,
        scheduleEventId: action.event?.id,
      };
    }

    case SCHEDULE_EVENT_RESCHEDULED: {
      if (!action.event.health_occurrence_id || !action.event.from_date) return null;
      const result = await pool.query(
        `UPDATE health_occurrences SET scheduled_date = $1, updated_at = NOW()
         WHERE id = $2 AND health_entry_id = $3 AND status = 'pending'
         RETURNING *`,
        [action.event.from_date, action.event.health_occurrence_id, entry.id],
      );
      if (result.rows.length === 0) return null;
      const refreshed = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entry.id],
      );
      return {
        actionType: 'rescheduled',
        entry: refreshed.rows[0],
        occurrence: result.rows[0],
        scheduleEventId: action.event.id,
      };
    }

    case SCHEDULE_EVENT_PAUSED: {
      const result = await pool.query(
        `UPDATE health_entries SET status = 'active', paused_since = NULL, updated_at = NOW()
         WHERE id = $1 AND status = 'paused'
         RETURNING *`,
        [entry.id],
      );
      if (result.rows.length === 0) return null;
      return {
        actionType: 'paused',
        entry: result.rows[0],
        scheduleEventId: action.event.id,
      };
    }

    case SCHEDULE_EVENT_RESUMED: {
      const pausedSince = action.event.from_date;
      const result = await pool.query(
        `UPDATE health_entries SET status = 'paused', paused_since = $1, updated_at = NOW()
         WHERE id = $2 AND status = 'active'
         RETURNING *`,
        [pausedSince, entry.id],
      );
      if (result.rows.length === 0) return null;
      return {
        actionType: 'resumed',
        entry: result.rows[0],
        scheduleEventId: action.event.id,
      };
    }

    case SCHEDULE_EVENT_CADENCE_ADJUSTED: {
      const effectiveFrom = action.event.effective_from;
      if (!effectiveFrom || !action.event.from_anchor) return null;

      const updated = await pool.query(
        `UPDATE health_entries SET recurrence_anchor = $1, updated_at = NOW()
         WHERE id = $2 AND status = 'active'
         RETURNING *`,
        [action.event.from_anchor, entry.id],
      );
      if (updated.rows.length === 0) return null;

      await pool.query(
        `DELETE FROM health_occurrences
         WHERE health_entry_id = $1 AND status = 'pending' AND scheduled_date >= $2`,
        [entry.id, effectiveFrom],
      );

      await advanceSeries(pool, updated.rows[0], todayIso);

      const refreshed = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entry.id],
      );

      return {
        actionType: 'cadence_adjusted',
        entry: refreshed.rows[0],
        nextDueDate: dateToIsoDate(refreshed.rows[0]?.next_due_date),
        scheduleEventId: action.event.id,
      };
    }

    default:
      return null;
  }
}
