import { v4 as uuidv4 } from 'uuid';
import {
  defaultKindForType,
  normaliseKind,
  normalisePriority,
  NOTIFICATION_PRIORITY_NORMAL,
  assertAllowedNotificationType,
} from './notificationKind.js';

/** SQL fragment: active (non-archived) inbox rows for list/count queries. */
export const NOTIFICATION_INBOX_ACTIVE_WHERE = 'archived_at IS NULL';

/**
 * Insert an in-app notification for a user.
 */
export async function createNotification(pool, {
  userId,
  petId = null,
  petName = null,
  healthEntryId = null,
  organizationId = null,
  title = '',
  message,
  type = 'general',
  kind = null,
  priority = NOTIFICATION_PRIORITY_NORMAL,
  resolvedAt = null,
}) {
  assertAllowedNotificationType(type);
  const resolvedKind = normaliseKind(kind ?? defaultKindForType(type));
  const resolvedPriority = normalisePriority(priority);
  await pool.query(
    `INSERT INTO notifications (
       id, user_id, pet_id, pet_name, health_entry_id, organization_id,
       title, message, type, kind, priority, resolved_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
    [
      uuidv4(),
      userId,
      petId,
      petName,
      healthEntryId,
      organizationId,
      title,
      message,
      type,
      resolvedKind,
      resolvedPriority,
      resolvedAt,
    ],
  );
}

/**
 * Mark open inbox rows resolved when a pending object transitions (any kind).
 *
 * @param {string} [referenceId] — invite code / object ref stored in `health_entry_id`
 *   (legacy column reused for non–health-entry references).
 * @param {string} [petId] — fallback when referenceId absent (legacy rows).
 */
export async function resolveNotifications(pool, {
  userId,
  type,
  petId = null,
  referenceId = null,
}) {
  if (!userId || !type) return;
  const params = [userId, type];
  let scopeFilter = '';
  if (referenceId != null && String(referenceId).length > 0) {
    scopeFilter = ` AND health_entry_id = $${params.length + 1}`;
    params.push(String(referenceId));
  } else if (petId) {
    scopeFilter = ` AND pet_id = $${params.length + 1}`;
    params.push(petId);
  }
  await pool.query(
    `UPDATE notifications
     SET resolved_at = NOW()
     WHERE user_id = $1
       AND type = $2
       AND resolved_at IS NULL${scopeFilter}`,
    params,
  );
}

/** @deprecated Prefer resolveNotifications with referenceId when available. */
export async function resolveNotificationsByType(pool, options) {
  await resolveNotifications(pool, options);
}

/** @deprecated Use resolveNotificationsByType — kept for call-site compatibility. */
export async function resolveAdministrativeNotifications(pool, options) {
  await resolveNotificationsByType(pool, options);
}

export function userDisplayName(row) {
  const full = `${row.first_name || ''} ${row.last_name || ''}`.trim();
  return full || row.email || 'Someone';
}
