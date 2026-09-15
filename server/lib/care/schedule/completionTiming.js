/**
 * Informational completion timing (D-CSM-002). Does not affect advanceSeries.
 */

export const COMPLETION_TIMING_EARLY = 'early';
export const COMPLETION_TIMING_ON_TIME = 'on_time';
export const COMPLETION_TIMING_LATE = 'late';

const VALID = new Set([
  COMPLETION_TIMING_EARLY,
  COMPLETION_TIMING_ON_TIME,
  COMPLETION_TIMING_LATE,
]);

/**
 * @param {string} scheduledDateIso YYYY-MM-DD
 * @param {string} completedOnIso YYYY-MM-DD
 * @returns {'early'|'on_time'|'late'}
 */
export function deriveCompletionTiming(scheduledDateIso, completedOnIso) {
  if (!scheduledDateIso || !completedOnIso) {
    return COMPLETION_TIMING_ON_TIME;
  }
  if (completedOnIso < scheduledDateIso) return COMPLETION_TIMING_EARLY;
  if (completedOnIso > scheduledDateIso) return COMPLETION_TIMING_LATE;
  return COMPLETION_TIMING_ON_TIME;
}

export function isValidCompletionTiming(value) {
  return value == null || VALID.has(value);
}
