import { NOTIFICATION_INBOX_ACTIVE_WHERE } from './notificationHelper.js';
import { SUGGESTION_INBOX_ACTIVE_WHERE } from '../routes/notifications/suggestionInbox.js';

const ACTIVITY_KINDS = "kind IN ('relationship', 'administrative', 'account')";

/**
 * SQL fragment (without user predicate) for tab-scoped mark-all-read.
 * @param {'activity' | 'for_you'} scope
 */
export function markAllReadKindFilter(scope) {
  if (scope === 'for_you') {
    return `kind = 'suggestion' AND ${SUGGESTION_INBOX_ACTIVE_WHERE}`;
  }
  return `${ACTIVITY_KINDS} AND ${NOTIFICATION_INBOX_ACTIVE_WHERE}`;
}

/**
 * @param {unknown} raw
 * @returns {'activity' | 'for_you'}
 */
export function parseMarkAllReadScope(raw) {
  const value = String(raw ?? 'activity')
    .trim()
    .toLowerCase()
    .replace('-', '_');
  if (value === 'for_you' || value === 'foryou') return 'for_you';
  return 'activity';
}
