/**
 * Append-only care_schedule_events ledger writes.
 */

import { v4 as uuidv4 } from 'uuid';

import { SCHEDULE_POLICY_VERSION } from './schedulePolicy.js';

export const SCHEDULE_EVENT_SKIPPED = 'skipped';
export const SCHEDULE_EVENT_RESCHEDULED = 'rescheduled';
export const SCHEDULE_EVENT_PAUSED = 'paused';
export const SCHEDULE_EVENT_RESUMED = 'resumed';
export const SCHEDULE_EVENT_CADENCE_ADJUSTED = 'cadence_adjusted';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @returns {Promise<string>} inserted event id
 */
export async function insertCareScheduleEvent(pool, {
  id = uuidv4(),
  healthEntryId,
  healthOccurrenceId = null,
  eventType,
  fromDate = null,
  toDate = null,
  fromAnchor = null,
  toAnchor = null,
  reasonCode = null,
  reasonNote = null,
  actorUserId = null,
  occurredAt = new Date(),
  effectiveFrom = null,
  idempotencyKey = null,
  policyVersion = SCHEDULE_POLICY_VERSION,
}) {
  await pool.query(
    `INSERT INTO care_schedule_events (
      id, health_entry_id, health_occurrence_id, event_type,
      from_date, to_date, from_anchor, to_anchor,
      reason_code, reason_note, actor_user_id, occurred_at,
      effective_from, idempotency_key, policy_version
    ) VALUES (
      $1, $2, $3, $4,
      $5, $6, $7, $8,
      $9, $10, $11, $12,
      $13, $14, $15
    )`,
    [
      id,
      healthEntryId,
      healthOccurrenceId,
      eventType,
      fromDate,
      toDate,
      fromAnchor,
      toAnchor,
      reasonCode,
      reasonNote,
      actorUserId,
      occurredAt,
      effectiveFrom,
      idempotencyKey,
      policyVersion,
    ],
  );
  return id;
}
