/**
 * Authoritative series cadence adjustment primitive (CSM-11).
 */

import {
  dateToIsoDate,
  normalizeCalendarDateInput,
  todayCalendarIso,
} from '../../calendarDate.js';
import {
  insertOccurrencesForDay,
  isOnceEntry,
  isWithinMaterialisationWindow,
} from '../../occurrenceScheduling.js';
import { isOccurrenceDateWithinSeries } from '../../occurrenceLifecycle.js';
import { advanceSeries } from './advanceSeries.js';
import { resolveRecurrenceAnchorForWrite } from './recurrenceAnchorDefaults.js';
import {
  insertCareScheduleEvent,
  SCHEDULE_EVENT_CADENCE_ADJUSTED,
} from './scheduleEventLedger.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} params.userId
 * @param {string|Date} params.effectiveFrom calendar day cadence change starts
 * @param {string} [params.frequency]
 * @param {number} [params.frequencyInterval]
 * @param {number|null} [params.frequencyDays]
 * @param {string} [params.recurrenceAnchor]
 * @param {string} [params.reasonCode]
 * @param {string} [params.reasonNote]
 * @param {Date} [params.occurredAt]
 * @param {string} [params.todayIso]
 * @returns {Promise<{ entry: object, nextDueDate: string|null, scheduleEventId: string }|null>}
 */
export async function adjustCadence(pool, {
  entry,
  userId,
  effectiveFrom,
  frequency,
  frequencyInterval,
  frequencyDays,
  recurrenceAnchor,
  reasonCode = null,
  reasonNote = null,
  occurredAt = new Date(),
  todayIso = todayCalendarIso(),
}) {
  if ((entry.status || 'active') !== 'active' || isOnceEntry(entry)) {
    return null;
  }

  const effectiveFromIso = normalizeCalendarDateInput(effectiveFrom);
  if (!effectiveFromIso) return null;

  const fromAnchor = entry.recurrence_anchor || 'from_completion';
  const nextFrequency = frequency ?? entry.frequency;
  const nextFrequencyInterval = frequencyInterval ?? entry.frequency_interval ?? 1;
  const nextFrequencyDays = frequencyDays !== undefined
    ? frequencyDays
    : entry.frequency_days;
  const nextAnchor = recurrenceAnchor !== undefined && recurrenceAnchor !== null
    ? resolveRecurrenceAnchorForWrite({
      careFamily: entry.care_family,
      explicitAnchor: recurrenceAnchor,
    })
    : entry.recurrence_anchor;

  await pool.query(
    `DELETE FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending' AND scheduled_date >= $2`,
    [entry.id, effectiveFromIso],
  );

  const updated = await pool.query(
    `UPDATE health_entries SET
      frequency = $1,
      frequency_interval = $2,
      frequency_days = $3,
      recurrence_anchor = $4,
      updated_at = NOW()
     WHERE id = $5 AND status = 'active'
     RETURNING *`,
    [
      nextFrequency,
      nextFrequencyInterval,
      nextFrequencyDays ?? null,
      nextAnchor,
      entry.id,
    ],
  );
  if (updated.rows.length === 0) return null;

  const updatedEntry = updated.rows[0];

  const pendingBefore = await pool.query(
    `SELECT 1 FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending' AND scheduled_date < $2
     LIMIT 1`,
    [entry.id, effectiveFromIso],
  );

  if (
    pendingBefore.rows.length === 0
    && isOccurrenceDateWithinSeries(updatedEntry, effectiveFromIso)
    && (isWithinMaterialisationWindow(effectiveFromIso, todayIso) || effectiveFromIso <= todayIso)
  ) {
    await insertOccurrencesForDay(pool, updatedEntry, effectiveFromIso);
  }

  await advanceSeries(pool, updatedEntry, todayIso);

  const scheduleEventId = await insertCareScheduleEvent(pool, {
    healthEntryId: entry.id,
    eventType: SCHEDULE_EVENT_CADENCE_ADJUSTED,
    fromAnchor,
    toAnchor: nextAnchor,
    reasonCode,
    reasonNote,
    actorUserId: userId,
    occurredAt,
    effectiveFrom: effectiveFromIso,
    idempotencyKey: `cadence_adjusted:${entry.id}:${effectiveFromIso}`,
  });

  const refreshed = await pool.query(
    'SELECT * FROM health_entries WHERE id = $1',
    [entry.id],
  );

  return {
    entry: refreshed.rows[0],
    nextDueDate: dateToIsoDate(refreshed.rows[0]?.next_due_date),
    scheduleEventId,
  };
}
