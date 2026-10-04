/**
 * Observation hooks for care command undo and completion-date sync (WEIGHT W2).
 * The occurrence engine calls these; weight SQL stays in this package.
 */

/** @typedef {{
 *   onUndoEvent?: (ctx: object, event: object) => Promise<void>,
 *   onCompletionDateChange?: (ctx: object, occurrenceId: string, completedOn: string) => Promise<object|null>,
 * }} ObservationCompletionHook */

const hooks = [];

/**
 * @param {ObservationCompletionHook} hook
 */
export function registerObservationCompletionHook(hook) {
  hooks.push(hook);
}

/**
 * @param {object} ctx
 * @param {object} event care_schedule_events row being undone
 */
export async function runObservationUndoHooks(ctx, event) {
  for (const hook of hooks) {
    if (hook.onUndoEvent) {
      await hook.onUndoEvent(ctx, event);
    }
  }
}

/**
 * @param {object} ctx
 * @param {string} occurrenceId
 * @param {string} completedOn YYYY-MM-DD
 * @returns {Promise<object>} extra payload fields to merge into the ledger event
 */
export async function runObservationCompletionDateHooks(ctx, occurrenceId, completedOn) {
  const extra = {};
  for (const hook of hooks) {
    if (!hook.onCompletionDateChange) continue;
    const part = await hook.onCompletionDateChange(ctx, occurrenceId, completedOn);
    if (part && typeof part === 'object') {
      Object.assign(extra, part);
    }
  }
  return extra;
}
