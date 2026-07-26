import { v4 as uuidv4 } from 'uuid';
import {
  defaultKindForType,
  normaliseKind,
  normalisePriority,
  NOTIFICATION_KIND_ADMINISTRATIVE,
  NOTIFICATION_PRIORITY_NORMAL,
} from './notificationKind.js';

/**
 * Insert an in-app notification for a user.
 */
export async function createNotification(pool, {
  userId,
  petId = null,
  petName = null,
  title = '',
  message,
  type = 'general',
  kind = null,
  priority = NOTIFICATION_PRIORITY_NORMAL,
  resolvedAt = null,
}) {
  const resolvedKind = normaliseKind(kind ?? defaultKindForType(type));
  const resolvedPriority = normalisePriority(priority);
  await pool.query(
    `INSERT INTO notifications (
       id, user_id, pet_id, pet_name, title, message, type, kind, priority, resolved_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
    [
      uuidv4(),
      userId,
      petId,
      petName,
      title,
      message,
      type,
      resolvedKind,
      resolvedPriority,
      resolvedAt,
    ]
  );
}

/**
 * Mark open administrative notifications resolved when a pending object transitions.
 */
export async function resolveAdministrativeNotifications(pool, {
  userId,
  petId = null,
  type,
}) {
  if (!userId || !type) return;
  const params = [userId, type, NOTIFICATION_KIND_ADMINISTRATIVE];
  let petFilter = '';
  if (petId) {
    petFilter = ' AND pet_id = $4';
    params.push(petId);
  }
  await pool.query(
    `UPDATE notifications
     SET resolved_at = NOW()
     WHERE user_id = $1
       AND type = $2
       AND kind = $3
       AND resolved_at IS NULL${petFilter}`,
    params,
  );
}

export function userDisplayName(row) {
  const full = `${row.first_name || ''} ${row.last_name || ''}`.trim();
  return full || row.email || 'Someone';
}
