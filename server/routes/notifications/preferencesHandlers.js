import {
  apiDtoToPreferenceUpdates,
  loadNotificationPreferences,
  upsertNotificationPreference,
} from '../../lib/notificationPreferences.js';
import { archiveActiveSuggestionsForUser } from './suggestionInbox.js';

async function upsertPreferenceRows(pool, userId, updates) {
  for (const [preference, value] of Object.entries(updates)) {
    await upsertNotificationPreference(pool, userId, preference, value);
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
