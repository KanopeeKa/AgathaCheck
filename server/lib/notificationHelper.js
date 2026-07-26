import { v4 as uuidv4 } from 'uuid';
import {
  defaultKindForType,
  normaliseKind,
  normalisePriority,
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

export function userDisplayName(row) {
  const full = `${row.first_name || ''} ${row.last_name || ''}`.trim();
  return full || row.email || 'Someone';
}
