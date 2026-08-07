/**
 * Notification kind / priority wire values and type→kind defaults (experience-program §3.1).
 */

export const NOTIFICATION_KIND_CARE = 'care';
export const NOTIFICATION_KIND_ADMINISTRATIVE = 'administrative';

export const NOTIFICATION_PRIORITY_NORMAL = 'normal';
export const NOTIFICATION_PRIORITY_URGENT = 'urgent';

export const NOTIFICATION_TYPE_PENDING_SHARE_RECEIVED = 'pendingShareReceived';
export const NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED = 'pendingFosterPlacementReceived';
export const NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED = 'pendingAdoptionPlacementReceived';
export const NOTIFICATION_TYPE_PENDING_CUSTODY_TRANSFER_RECEIVED = 'pendingCustodyTransferReceived';

const VALID_KINDS = new Set([NOTIFICATION_KIND_CARE, NOTIFICATION_KIND_ADMINISTRATIVE]);
const VALID_PRIORITIES = new Set([
  NOTIFICATION_PRIORITY_NORMAL,
  NOTIFICATION_PRIORITY_URGENT,
]);

const ADMINISTRATIVE_TYPES = new Set([
  'fosterRequestReceived',
  'fosterRequestResponded',
  'fosterInvitationReceived',
  'fosterApprovalGranted',
  'fosterApprovalDeclined',
  'sessionStartingSoon',
  'sessionEndingSoon',
  'agreementWithdrawn',
  'connectionRequestReceived',
  NOTIFICATION_TYPE_PENDING_SHARE_RECEIVED,
  NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_CUSTODY_TRANSFER_RECEIVED,
  'adminMessageReceived',
]);

/** Map notification `type` to kind at creation time. */
export function defaultKindForType(type = 'general') {
  if (ADMINISTRATIVE_TYPES.has(type)) {
    return NOTIFICATION_KIND_ADMINISTRATIVE;
  }
  return NOTIFICATION_KIND_CARE;
}

export function normaliseKind(value) {
  const kind = String(value || NOTIFICATION_KIND_CARE).toLowerCase();
  return VALID_KINDS.has(kind) ? kind : NOTIFICATION_KIND_CARE;
}

export function normalisePriority(value) {
  const priority = String(value || NOTIFICATION_PRIORITY_NORMAL).toLowerCase();
  return VALID_PRIORITIES.has(priority) ? priority : NOTIFICATION_PRIORITY_NORMAL;
}

export function isAdministrativeType(type) {
  return ADMINISTRATIVE_TYPES.has(type);
}
