import { dateToIsoDate } from './calendarDate.js';
import {
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
  normalizePlacementStatus,
} from './fosterPlacements.js';

export const DERIVED_STATUS_NEARLY_FINISHED = 'nearly_finished';
const NEARLY_FINISHED_DAYS = 10;

const OPEN_FOR_NEARLY_FINISHED = [
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
];

function calendarDateToUtcMs(isoDate) {
  const [year, month, day] = isoDate.split('-').map(Number);
  return Date.UTC(year, month - 1, day);
}

function daysUntilCalendarDate(now, isoDate) {
  const today = dateToIsoDate(now);
  if (!today || !isoDate) return null;
  const diffMs = calendarDateToUtcMs(isoDate) - calendarDateToUtcMs(today);
  return Math.round(diffMs / (24 * 60 * 60 * 1000));
}

/**
 * Derive list display status for a fostering session row.
 * "nearly_finished" when an open session ends within 10 calendar days.
 */
export function deriveSessionStatus(placement, now = new Date()) {
  const sessionStatus = placement.session_status
    || normalizePlacementStatus(placement.status);
  const endDate = placement.end_date ? dateToIsoDate(placement.end_date) : null;

  let derivedStatus = sessionStatus;
  let nearlyFinished = false;

  if (endDate && OPEN_FOR_NEARLY_FINISHED.includes(sessionStatus)) {
    const daysUntilEnd = daysUntilCalendarDate(now, endDate);
    if (daysUntilEnd != null && daysUntilEnd >= 0 && daysUntilEnd <= NEARLY_FINISHED_DAYS) {
      derivedStatus = DERIVED_STATUS_NEARLY_FINISHED;
      nearlyFinished = true;
    }
  }

  return {
    session_status: sessionStatus,
    derived_status: derivedStatus,
    nearly_finished: nearlyFinished,
    in_view_to_adopt: (placement.session_type || '') === SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
  };
}
