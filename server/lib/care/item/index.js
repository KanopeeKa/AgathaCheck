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
  CARE_CLOSED_REASON_ENDED,
  CARE_CLOSED_REASON_STOPPED,
  CARE_ITEM_STATUS_CLOSED,
  careClosedReasonForWire,
  isItemClosed,
} from './itemStatus.js';
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
export { careItemReadResponse } from './readResponse.js';
export { careItemWire, careItemsWire, commandResponse } from './wire.js';
