import { addCalendarDaysIso } from '../../calendarDate.js';
import { postponeCommand, runCareCommand } from '../occurrence/index.js';
import { CareCommandError } from '../occurrence/careCommandError.js';

/**
 * @param {string} endsOn YYYY-MM-DD
 * @returns {string}
 */
export function postponeUntilAfterReturn(endsOn) {
  return addCalendarDaysIso(endsOn, 1);
}

/**
 * Move after return = Postpone until day after return (D-CSM-028, D-ACP-011).
 *
 * @param {import('pg').Pool} pool
 * @param {object} params
 * @param {string} params.entryId
 * @param {string} params.userId
 * @param {import('express').Request|null} [params.req]
 * @param {string} params.absenceId
 * @param {string} params.endsOn
 * @param {string|null} [params.occurrenceId]
 */
export async function applyMoveAfterAbsenceReturn(pool, {
  entryId, userId, req = null, absenceId, endsOn, occurrenceId = null,
}) {
  const until = postponeUntilAfterReturn(endsOn);
  try {
    const out = await runCareCommand(pool, { entryId, userId, req }, (ctx) => postponeCommand(ctx, {
      until,
      reason: 'absence',
      absenceId,
      occurrenceId,
    }));
    if (!out) {
      return { ok: false, status: 404, error: 'Health entry not found' };
    }
    return { ok: true, until, undoToken: out.undoToken ?? null };
  } catch (err) {
    if (err instanceof CareCommandError) {
      return { ok: false, status: err.status, error: err.code, body: err.toBody() };
    }
    throw err;
  }
}
