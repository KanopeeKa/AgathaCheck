import { v4 as uuidv4 } from 'uuid';

import { accessiblePetSql, petNotificationRecipientIds } from './petAccess.js';

function startOfDay(d) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

function parsePrefs(rows) {
  const prefs = {
    notifyOverdue: true,
    notifyDueSoon: true,
    reminderDaysBefore: 1,
    mutedPetIds: [],
  };
  for (const row of rows) {
    const key = row.preference;
    const val = row.value;
    if (key === 'notify_overdue') prefs.notifyOverdue = val !== 'false';
    else if (key === 'notify_due_soon') prefs.notifyDueSoon = val !== 'false';
    else if (key === 'reminder_days_before') prefs.reminderDaysBefore = parseInt(val, 10) || 1;
    else if (key === 'muted_pet_ids') {
      try {
        const parsed = JSON.parse(val);
        if (Array.isArray(parsed)) prefs.mutedPetIds = parsed.map(String);
      } catch (_) {
        prefs.mutedPetIds = [];
      }
    }
  }
  return prefs;
}

async function loadUserPrefs(pool, userId) {
  const result = await pool.query(
    'SELECT preference, value FROM notification_preferences WHERE user_id = $1',
    [userId]
  );
  return parsePrefs(result.rows);
}

async function hasRecentUnread(pool, userId, healthEntryId, type) {
  const result = await pool.query(
    `SELECT 1 FROM notifications
     WHERE user_id = $1 AND health_entry_id = $2 AND type = $3
       AND COALESCE(is_read, read, false) = false
     LIMIT 1`,
    [userId, healthEntryId, type]
  );
  return result.rows.length > 0;
}

async function insertDueNotification(pool, {
  userId, petId, petName, healthEntryId, title, message, type,
}) {
  if (await hasRecentUnread(pool, userId, healthEntryId, type)) return false;
  await pool.query(
    `INSERT INTO notifications (id, user_id, pet_id, pet_name, health_entry_id, title, message, type)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [uuidv4(), userId, petId, petName, healthEntryId, title, message, type]
  );
  return true;
}

/**
 * Scan health entries for pets the caller can access and create due/overdue
 * notifications for every owner and collaborator on each affected pet.
 */
export async function checkDueNotifications(pool, userId, petNamesFromClient = {}) {
  const entries = await pool.query(
    `SELECT he.id, he.pet_id, he.name, he.next_due_date, he.remind_days_before,
            p.name AS pet_name
     FROM health_entries he
     JOIN pets p ON p.id = he.pet_id
     WHERE ${accessiblePetSql('p', '$1')}
       AND he.next_due_date IS NOT NULL
       AND he.status != 'completed'
       AND (he.completed_on IS NULL)`,
    [userId]
  );

  const today = startOfDay(new Date());
  let created = 0;

  for (const entry of entries.rows) {
    const dueDate = startOfDay(entry.next_due_date);
    const petName = petNamesFromClient[entry.pet_id] || entry.pet_name || 'Pet';
    const recipients = await petNotificationRecipientIds(pool, entry.pet_id);

    for (const recipientId of recipients) {
      const prefs = await loadUserPrefs(pool, recipientId);
      if (prefs.mutedPetIds.includes(String(entry.pet_id))) continue;

      const remindBefore = entry.remind_days_before ?? prefs.reminderDaysBefore ?? 1;
      const daysUntilDue = Math.round((dueDate - today) / (24 * 60 * 60 * 1000));

      if (daysUntilDue < 0 && prefs.notifyOverdue) {
        const title = `${petName}: overdue`;
        const message = `"${entry.name}" was due on ${dueDate.toISOString().split('T')[0]}.`;
        if (await insertDueNotification(pool, {
          userId: recipientId,
          petId: entry.pet_id,
          petName,
          healthEntryId: entry.id,
          title,
          message,
          type: 'overdue',
        })) created += 1;
      } else if (daysUntilDue >= 0 && daysUntilDue <= remindBefore && prefs.notifyDueSoon) {
        const title = `${petName}: due soon`;
        const message = `"${entry.name}" is due on ${dueDate.toISOString().split('T')[0]}.`;
        if (await insertDueNotification(pool, {
          userId: recipientId,
          petId: entry.pet_id,
          petName,
          healthEntryId: entry.id,
          title,
          message,
          type: 'due_soon',
        })) created += 1;
      }
    }
  }

  return { checked: true, created };
}
