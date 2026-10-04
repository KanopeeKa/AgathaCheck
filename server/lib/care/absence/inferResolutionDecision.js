import {
  RESOLUTION_DECISION_MOVE_AFTER,
  RESOLUTION_DECISION_MOVE_BEFORE,
} from './constants.js';

/**
 * Infer absence resolution decision after a schedule change (mirrors Flutter sync).
 *
 * @param {string} newScheduledDate YYYY-MM-DD
 * @param {string} absenceStartsOn YYYY-MM-DD
 * @param {string} absenceEndsOn YYYY-MM-DD
 * @returns {'move_before'|'move_after'|null}
 */
export function inferResolutionDecisionAfterSchedule(
  newScheduledDate,
  absenceStartsOn,
  absenceEndsOn,
) {
  if (!newScheduledDate || !absenceStartsOn || !absenceEndsOn) return null;
  if (newScheduledDate < absenceStartsOn) {
    return RESOLUTION_DECISION_MOVE_BEFORE;
  }
  if (newScheduledDate > absenceEndsOn) {
    return RESOLUTION_DECISION_MOVE_AFTER;
  }
  return null;
}
