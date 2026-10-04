import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { loadAwayPlanProjection } from '../awayPlan/loadAwayPlanProjection.js';
import { RESOLUTION_DECISION_MOVE_AFTER } from './constants.js';
import { inferResolutionDecisionAfterSchedule } from './inferResolutionDecision.js';
import { upsertResolution } from './resolutionRepository.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 */
async function loadAbsenceWindow(pool, absenceId) {
  const result = await pool.query(
    'SELECT starts_on, ends_on FROM planned_absences WHERE id = $1',
    [absenceId],
  );
  const row = result.rows[0];
  if (!row) return null;
  const startsOn = dateToIsoDate(row.starts_on);
  const endsOn = dateToIsoDate(row.ends_on);
  if (!startsOn || !endsOn) return null;
  return { startsOn, endsOn };
}

/**
 * After reschedule/postpone with absence context, persist inferred move_before / move_after.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {string} params.absenceId
 * @param {string} params.healthEntryId
 * @param {string} params.newScheduledDate
 * @param {string} params.startsOn
 * @param {string} params.endsOn
 * @param {object[]} params.projectionItems
 * @param {object} [params.body] optional looked_after_by / absence_note from caller
 */
export async function syncResolutionAfterSchedule(pool, {
  absenceId,
  healthEntryId,
  newScheduledDate,
  startsOn,
  endsOn,
  projectionItems,
  body = {},
}) {
  const decision = body.decision
    ?? inferResolutionDecisionAfterSchedule(newScheduledDate, startsOn, endsOn);
  if (!decision) return { ok: true, skipped: true };

  return upsertResolution(pool, absenceId, healthEntryId, {
    ...body,
    decision,
  }, {
    startsOn,
    endsOn,
    projectionItems,
  });
}

/**
 * Postpone with reason absence stores a move_after resolution (PP-5).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 */
export async function syncMoveAfterResolutionAfterAbsencePostpone(pool, params) {
  return upsertResolution(pool, params.absenceId, params.healthEntryId, {
    decision: RESOLUTION_DECISION_MOVE_AFTER,
    looked_after_by: params.lookedAfterBy,
    absence_note: params.absenceNote,
  }, {
    startsOn: params.startsOn,
    endsOn: params.endsOn,
    projectionItems: params.projectionItems,
  });
}

/**
 * @param {import('pg').Pool} pool
 * @param {object} params
 */
export async function syncResolutionAfterAbsencePostpone(pool, {
  healthEntryId,
  petId,
  absenceId,
  until,
  lookedAfterBy = null,
  absenceNote = null,
}) {
  if (!absenceId || !until) return { ok: true, skipped: true };
  const window = await loadAbsenceWindow(pool, absenceId);
  if (!window) return { ok: false, error: 'Absence not found' };
  const projection = await loadAwayPlanProjection(
    pool,
    petId,
    window.startsOn,
    window.endsOn,
    todayCalendarIso(),
  );
  return syncMoveAfterResolutionAfterAbsencePostpone(pool, {
    absenceId,
    healthEntryId,
    startsOn: window.startsOn,
    endsOn: window.endsOn,
    projectionItems: projection.items,
    lookedAfterBy,
    absenceNote,
  });
}

/**
 * @param {import('pg').Pool} pool
 * @param {object} params
 */
export async function syncResolutionAfterAbsenceReschedule(pool, {
  healthEntryId,
  petId,
  absenceId,
  newScheduledDate,
  body = {},
}) {
  if (!absenceId || !newScheduledDate) return { ok: true, skipped: true };
  const window = await loadAbsenceWindow(pool, absenceId);
  if (!window) return { ok: false, error: 'Absence not found' };
  const projection = await loadAwayPlanProjection(
    pool,
    petId,
    window.startsOn,
    window.endsOn,
    todayCalendarIso(),
  );
  return syncResolutionAfterSchedule(pool, {
    absenceId,
    healthEntryId,
    newScheduledDate,
    startsOn: window.startsOn,
    endsOn: window.endsOn,
    projectionItems: projection.items,
    body,
  });
}
