/**
 * Care item lifecycle status (CARE-STATUS-R-009 … R-011).
 */

export const CARE_ITEM_STATUS_ACTIVE = 'active';
export const CARE_ITEM_STATUS_PAUSED = 'paused';
export const CARE_ITEM_STATUS_CLOSED = 'closed';

export const CARE_CLOSED_REASON_ENDED = 'ended';
export const CARE_CLOSED_REASON_STOPPED = 'stopped_by_user';

/** @param {object} row health_entries row */
export function isItemClosed(row) {
  const status = row.status || CARE_ITEM_STATUS_ACTIVE;
  return status === CARE_ITEM_STATUS_CLOSED || status === 'completed';
}

/** @param {object} row */
export function careClosedReasonForWire(row) {
  if ((row.status || CARE_ITEM_STATUS_ACTIVE) !== CARE_ITEM_STATUS_CLOSED) return null;
  return row.care_closed_reason || CARE_CLOSED_REASON_ENDED;
}
