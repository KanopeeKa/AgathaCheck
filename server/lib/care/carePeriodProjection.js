/**
 * Care-period projection — server-authoritative scheduling preview for a date window.
 *
 * Thin re-export wrapper over schedule/projectSchedule.js for Care Context backward compatibility.
 */

export {
  CERTAINTY_COMPLETE,
  CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
  PROJECTION_STATUS_COMPLETE,
  PROJECTION_STATUS_PARTIALLY_INDETERMINATE,
  UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN,
  UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
  isDateInCareWindow,
  loadAndProjectSchedule,
  projectCareForPeriod,
  projectEntryForPeriod,
  projectSchedule,
} from './schedule/projectSchedule.js';

/** @deprecated Use loadAndProjectSchedule from schedule/projectSchedule.js */
export { loadAndProjectSchedule as loadAndProjectCareForPeriod } from './schedule/projectSchedule.js';
