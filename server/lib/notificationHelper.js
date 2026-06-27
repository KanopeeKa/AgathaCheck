import { v4 as uuidv4 } from 'uuid';

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
}) {
  await pool.query(
    `INSERT INTO notifications (id, user_id, pet_id, pet_name, title, message, type)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [uuidv4(), userId, petId, petName, title, message, type]
  );
}

export function userDisplayName(row) {
  const full = `${row.first_name || ''} ${row.last_name || ''}`.trim();
  return full || row.email || 'Someone';
}
