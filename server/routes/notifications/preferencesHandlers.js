import { v4 as uuidv4 } from 'uuid';

import {
  apiDtoToPreferenceUpdates,
  loadNotificationPreferences,
} from '../../lib/notificationPreferences.js';
import { archiveActiveSuggestionsForUser } from './suggestionInbox.js';

async function upsertPreferenceRows(pool, userId, updates) {
  for (const [preference, value] of Object.entries(updates)) {
    const existing = await pool.query(
      'SELECT id FROM notification_preferences WHERE user_id = $1 AND preference = $2',
      [userId, preference],
    );
    if (existing.rows.length > 0) {
      await pool.query(
        'UPDATE notification_preferences SET value = $1 WHERE user_id = $2 AND preference = $3',
        [String(value), userId, preference],
      );
    } else {
      await pool.query(
        'INSERT INTO notification_preferences (id, user_id, preference, value) VALUES ($1, $2, $3, $4)',
        [uuidv4(), userId, preference, String(value)],
      );
    }
  }
}

export async function getNotificationPreferences(pool, userId) {
  return loadNotificationPreferences(pool, userId);
}

export async function patchNotificationPreferences(pool, userId, body) {
  const { updates, agathaTurnedOff } = apiDtoToPreferenceUpdates(body || {});
  if (Object.keys(updates).length > 0) {
    await upsertPreferenceRows(pool, userId, updates);
  }
  if (agathaTurnedOff) {
    await archiveActiveSuggestionsForUser(pool, userId);
  }
  return loadNotificationPreferences(pool, userId);
}
