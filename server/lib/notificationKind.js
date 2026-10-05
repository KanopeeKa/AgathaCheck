/**
 * Notification kind / priority wire values and type→kind defaults (Notifications v2 PR3+).
 */

export const NOTIFICATION_KIND_CARE = 'care';
export const NOTIFICATION_KIND_ADMINISTRATIVE = 'administrative';
export const NOTIFICATION_KIND_RELATIONSHIP = 'relationship';
export const NOTIFICATION_KIND_SUGGESTION = 'suggestion';
export const NOTIFICATION_KIND_ACCOUNT = 'account';

export const NOTIFICATION_PRIORITY_NORMAL = 'normal';
export const NOTIFICATION_PRIORITY_URGENT = 'urgent';

export const NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED = 'shareInviteReceived';
export const NOTIFICATION_TYPE_SHARE_INVITE_ACCEPTED = 'shareInviteAccepted';
export const NOTIFICATION_TYPE_SHARE_INVITE_DECLINED = 'shareInviteDeclined';
export const NOTIFICATION_TYPE_SHARE_LINK_FOLLOWED = 'shareLinkFollowed';
export const NOTIFICATION_TYPE_SHARE_MEMBER_LEFT = 'shareMemberLeft';
export const NOTIFICATION_TYPE_SHARE_ACCESS_REMOVED = 'shareAccessRemoved';
export const NOTIFICATION_TYPE_OWNERSHIP_TRANSFER_COMPLETED = 'ownershipTransferCompleted';
export const NOTIFICATION_TYPE_PET_PASSED_AWAY = 'petPassedAway';
export const NOTIFICATION_TYPE_HOUSEHOLD_INVITE_RECEIVED = 'householdInviteReceived';
export const NOTIFICATION_TYPE_ABSENCE_GUEST_GRANTED = 'absenceGuestGranted';
export const NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED = 'pendingFosterPlacementReceived';
export const NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED = 'pendingAdoptionPlacementReceived';
export const NOTIFICATION_TYPE_PENDING_CUSTODY_TRANSFER_RECEIVED = 'pendingCustodyTransferReceived';

export const NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN = 'accountNewSignIn';
export const NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED = 'accountPasswordChanged';
export const NOTIFICATION_TYPE_ACCOUNT_SESSIONS_REVOKED = 'accountSessionsRevoked';
export const NOTIFICATION_TYPE_ACCOUNT_DELETION_REQUESTED = 'accountDeletionRequested';

const ACCOUNT_TYPES = new Set([
  NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
  NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
  NOTIFICATION_TYPE_ACCOUNT_SESSIONS_REVOKED,
  NOTIFICATION_TYPE_ACCOUNT_DELETION_REQUESTED,
]);

const VALID_KINDS = new Set([
  NOTIFICATION_KIND_CARE,
  NOTIFICATION_KIND_ADMINISTRATIVE,
  NOTIFICATION_KIND_RELATIONSHIP,
  NOTIFICATION_KIND_SUGGESTION,
  NOTIFICATION_KIND_ACCOUNT,
]);
const VALID_PRIORITIES = new Set([
  NOTIFICATION_PRIORITY_NORMAL,
  NOTIFICATION_PRIORITY_URGENT,
]);

const RELATIONSHIP_TYPES = new Set([
  NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
  NOTIFICATION_TYPE_SHARE_INVITE_ACCEPTED,
  NOTIFICATION_TYPE_SHARE_INVITE_DECLINED,
  NOTIFICATION_TYPE_SHARE_LINK_FOLLOWED,
  NOTIFICATION_TYPE_SHARE_MEMBER_LEFT,
  NOTIFICATION_TYPE_SHARE_ACCESS_REMOVED,
  NOTIFICATION_TYPE_OWNERSHIP_TRANSFER_COMPLETED,
  NOTIFICATION_TYPE_PET_PASSED_AWAY,
  NOTIFICATION_TYPE_HOUSEHOLD_INVITE_RECEIVED,
  NOTIFICATION_TYPE_ABSENCE_GUEST_GRANTED,
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
  NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_CUSTODY_TRANSFER_RECEIVED,
  'adminMessageReceived',
  'fosterPlacementAccepted',
  'fosterPlacementDeclined',
  'fosterSessionEndingAwaitingReturn',
  'fosterPeriodEnded',
  'adoptionReadyToConfirm',
  'adoptionConfirmedOrg',
  'adoptionCompleteOwner',
  'adoptionCancelled',
  'adoptionJourneyUpdate',
  'placementActionUpdate',
]);

/** Map notification `type` to kind at creation time. */
export function defaultKindForType(type = 'general') {
  if (ACCOUNT_TYPES.has(type)) {
    return NOTIFICATION_KIND_ACCOUNT;
  }
  if (RELATIONSHIP_TYPES.has(type)) {
    return NOTIFICATION_KIND_RELATIONSHIP;
  }
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

export function isRelationshipType(type) {
  return RELATIONSHIP_TYPES.has(type);
}

export function assertAllowedNotificationType(type) {
  if (String(type || '').toLowerCase() === 'general') {
    throw new Error(
      'createNotification: type "general" is not allowed for new inbox rows (notifications v2 PR3)',
    );
  }
}
