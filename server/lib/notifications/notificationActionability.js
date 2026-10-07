/**
 * Wire-type actionability matrix (Notifications v2 §5.4, §6.3, D10).
 * Keep in sync with Flutter `notification_actionability.dart`.
 */
import {
  NOTIFICATION_KIND_ACCOUNT,
  NOTIFICATION_KIND_ADMINISTRATIVE,
  NOTIFICATION_KIND_RELATIONSHIP,
  NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
  NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
  NOTIFICATION_TYPE_HOUSEHOLD_INVITE_RECEIVED,
  NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_CUSTODY_TRANSFER_RECEIVED,
  NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
} from '../notificationKind.js';

/** Unresolved rows of these types need a user response (bell + Needs your response). */
export const NOTIFICATION_TYPES_NEEDING_RESPONSE = new Set([
  NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
  NOTIFICATION_TYPE_HOUSEHOLD_INVITE_RECEIVED,
  NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_CUSTODY_TRANSFER_RECEIVED,
  'connectionRequestReceived',
  NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
]);

const ACCOUNT_INFORMATIONAL_TYPES = new Set([
  NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
  'accountSessionsRevoked',
  'accountDeletionRequested',
]);

/**
 * @param {string} kind
 * @param {string} wireType
 * @param {{ resolvedAt?: Date | null }} [row]
 */
export function notificationNeedsResponse(kind, wireType, row = {}) {
  if (row.resolvedAt) return false;
  const type = String(wireType || '');
  if (kind === NOTIFICATION_KIND_RELATIONSHIP) {
    return NOTIFICATION_TYPES_NEEDING_RESPONSE.has(type);
  }
  if (kind === NOTIFICATION_KIND_ADMINISTRATIVE) {
    return NOTIFICATION_TYPES_NEEDING_RESPONSE.has(type);
  }
  if (kind === NOTIFICATION_KIND_ACCOUNT) {
    if (ACCOUNT_INFORMATIONAL_TYPES.has(type)) return false;
    return NOTIFICATION_TYPES_NEEDING_RESPONSE.has(type);
  }
  return false;
}
