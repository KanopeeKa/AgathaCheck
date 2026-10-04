import { todayCalendarIso } from '../../calendarDate.js';
import { CareCommandError } from '../occurrence/careCommandError.js';
import { loadAwayPlanProjection } from '../awayPlan/loadAwayPlanProjection.js';
import { RESOLUTION_DECISION_MOVE_AFTER } from './constants.js';
import { inferResolutionDecisionAfterSchedule } from './inferResolutionDecision.js';
import { loadAbsenceWindowForEntry } from './loadAbsenceWindowForEntry.js';
import { upsertResolution } from './resolutionRepository.js';

function throwSyncError(result) {
  if (result.ok) return;
  const status = result.status || 400;
  const code = status === 403 ? 'forbidden' : status === 404 ? 'absence_not_found' : 'invalid_resolution';
  throw new CareCommandError(status, code, result.error || 'Could not sync absence resolution');
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
  userId,
  absenceId,
  until,
  lookedAfterBy = null,
  absenceNote = null,
}) {
  if (!absenceId || !until) return { ok: true, skipped: true };
  const window = await loadAbsenceWindowForEntry(pool, { absenceId, petId, userId });
  if (!window.ok) {
    throwSyncError(window);
  }
  const projection = await loadAwayPlanProjection(
    pool,
    petId,
    window.startsOn,
    window.endsOn,
    todayCalendarIso(),
  );
  const result = await syncMoveAfterResolutionAfterAbsencePostpone(pool, {
    absenceId,
    healthEntryId,
    startsOn: window.startsOn,
    endsOn: window.endsOn,
    projectionItems: projection.items,
    lookedAfterBy,
    absenceNote,
  });
  if (!result.ok) {
    throwSyncError({ ok: false, status: 400, error: result.error });
  }
  return result;
}

/**
 * @param {import('pg').Pool} pool
 * @param {object} params
 */
export async function syncResolutionAfterAbsenceReschedule(pool, {
  healthEntryId,
  petId,
  userId,
  absenceId,
  newScheduledDate,
  body = {},
}) {
  if (!absenceId || !newScheduledDate) return { ok: true, skipped: true };
  const window = await loadAbsenceWindowForEntry(pool, { absenceId, petId, userId });
  if (!window.ok) {
    throwSyncError(window);
  }
  const projection = await loadAwayPlanProjection(
    pool,
    petId,
    window.startsOn,
    window.endsOn,
    todayCalendarIso(),
  );
  const result = await syncResolutionAfterSchedule(pool, {
    absenceId,
    healthEntryId,
    newScheduledDate,
    startsOn: window.startsOn,
    endsOn: window.endsOn,
    projectionItems: projection.items,
    body: { record_only: true, recordOnly: true, ...body },
  });
  if (!result.ok) {
    throwSyncError({ ok: false, status: 400, error: result.error });
  }
  return result;
}
