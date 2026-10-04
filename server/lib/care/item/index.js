/**
 * Care item module — entry wire maps, occurrence wire helpers, API response shaping.
 */

export { healthEntryToMap, normalizeHealthEntryTypeForRead } from './entryMap.js';
export {
  applyLateCompletionChoice,
  LATE_COMPLETION_CHOICES,
  parseLateCompletionChoice,
} from './lateCompletionChoice.js';
export {
  isEntrySeriesClosed,
  isOccurrenceDateWithinSeries,
  repeatEndDateIso,
} from './seriesLifecycle.js';
export {
  isMultiPerDayEntry,
  isOccurrenceMissed,
  isOnceEntry,
  normalizeTime,
  occurrenceToMap,
  parseScheduleTimesInput,
  resolveCompletedOn,
  scheduleTimesFromEntry,
} from './scheduling.js';
export { careItemWire, careItemsWire, commandResponse } from './wire.js';
