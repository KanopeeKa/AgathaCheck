/**
 * Care occurrence engine — public API (D-CSM-019 … D-CSM-033).
 *
 * Routes: parse → authorise → `runCareCommand` → map → post-commit effects.
 */

import { withCareItemLock } from './careItemLock.js';
import { resolveCareAsOf } from './careAsOf.js';
import { executeCareCommand } from './commandRunner.js';
import { CareCommandError } from './careCommandError.js';

export { withCareItemLock } from './careItemLock.js';
export {
  CARE_TEST_CLOCK_HEADER,
  asOfToWire,
  careAsOfForZone,
  isCareTestClockEnabled,
  parseCareClock,
  resolveCareAsOf,
  resolveCareAsOfForRead,
} from './careAsOf.js';
export { CareCommandError } from './careCommandError.js';
export { executeCareCommand } from './commandRunner.js';
export { syncOpenOccurrences } from './syncOpenOccurrences.js';
export {
  listOpenRows,
  listOpenRowsByEntry,
  normalizeOccurrenceRow,
  updateCompletedDetails,
} from './occurrenceRepository.js';
export { careItemReadAdditions, openOccurrenceToWire } from './occurrenceDto.js';
export { completeOccurrenceCommand, EARLIER_CHOICES } from './commands/complete.js';
export { skipOccurrenceCommand } from './commands/skip.js';
export { recordAsGivenCommand, resolveStackCommand } from './commands/stack.js';
export {
  CHANGE_SCOPE_FOLLOWING,
  CHANGE_SCOPE_THIS,
  changeDateCommand,
  planAnotherDateCommand,
} from './commands/changeDate.js';
export {
  POSTPONE_REASONS,
  defaultResumeDate,
  postponeCommand,
  resumeCommand,
} from './commands/postpone.js';
export { undoCommand, undoCompletionOfOccurrence } from './commands/undo.js';
export { adjustCadenceCommand } from './commands/cadence.js';
export {
  closeSeriesCommand,
  createInitialOccurrences,
  reconcileScheduleEdit,
  reopenSeriesCommand,
} from './commands/lifecycle.js';
export { runCareTick } from './careTick.js';

/**
 * Lock the item, resolve "now", run one command.
 *
 * @template T
 * @param {import('pg').Pool} pool
 * @param {object} params
 * @param {string} params.entryId
 * @param {string|null} params.userId
 * @param {import('express').Request|null} [params.req] for the pet timezone and test clock
 * @param {{ todayIso: string, nowTimeIso: string, timeZone: string }} [params.asOf] explicit clock
 * @param {(ctx: object) => Promise<{ event: object|null, result?: T }>} command
 * @param {(db: object, entry: object) => Promise<void>} [params.beforeCommand] same-transaction pre-step
 * @param {(db: object) => Promise<void>} [params.beforeLock] same-transaction step before the row lock
 * @returns {Promise<(T & { entry: object, openOccurrences: object[], undoToken: string|null, asOf: object })|null>}
 */
export async function runCareCommand(pool, {
  entryId, userId, req = null, asOf = null, beforeCommand = null, beforeLock = null,
}, command) {
  return withCareItemLock(pool, entryId, async (db, entry) => {
    const clock = asOf || await resolveCareAsOf(db, entry, req);
    if (beforeCommand) await beforeCommand(db, entry);
    const out = await executeCareCommand({ db, entry, asOf: clock, userId }, command);
    return { ...out, asOf: clock };
  }, { beforeLock });
}

/**
 * Run one command inside a transaction the caller already opened (seeds,
 * migration hooks). Locks the item row; never BEGINs or COMMITs.
 *
 * @template T
 * @param {import('pg').PoolClient} db client inside an open transaction
 * @param {{ entryId: string, userId?: string|null, asOf: object }} params
 * @param {(ctx: object) => Promise<{ event: object|null, result?: T }>} command
 */
export async function applyCareCommand(db, { entryId, userId = null, asOf }, command) {
  const locked = await db.query('SELECT * FROM health_entries WHERE id = $1 FOR UPDATE', [entryId]);
  if (!locked.rows[0]) return null;
  const out = await executeCareCommand({ db, entry: locked.rows[0], asOf, userId }, command);
  return { ...out, asOf };
}

/**
 * Map a command error to an HTTP response; returns false for other errors.
 *
 * @param {import('express').Response} res
 * @param {unknown} err
 * @returns {boolean}
 */
export function sendCareCommandError(res, err) {
  if (err instanceof CareCommandError) {
    res.status(err.status).json(err.toBody());
    return true;
  }
  return false;
}
