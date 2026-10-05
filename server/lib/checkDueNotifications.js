import { accessiblePetSql, petNotificationRecipientIds } from './petAccess.js';
import { dateToIsoDate } from './calendarDate.js';
import { careAsOfForZone } from './care/occurrence/careAsOf.js';
import { normalizePetHomeTimezone } from './petHomeTimezone.js';

/**
 * In-app deep link for a care notification tied to a health entry (view screen).
 * Returns null when pet or entry id is missing.
 */
export function buildNotificationDeepLink(petId, healthEntryId) {
  if (!petId || !healthEntryId) return null;
  return `/pet/${petId}/events/${healthEntryId}`;
}

function daysBetweenCalendarDates(isoFrom, isoTo) {
  const [fy, fm, fd] = isoFrom.split('-').map(Number);
  const [ty, tm, td] = isoTo.split('-').map(Number);
  const fromMs = Date.UTC(fy, fm - 1, fd);
  const toMs = Date.UTC(ty, tm - 1, td);
  return Math.round((toMs - fromMs) / (24 * 60 * 60 * 1000));
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

/**
 * Scan health entries for pets the caller can access.
 *
 * Notifications v2 (FR-CR-1): due/overdue reminders MUST NOT create inbox rows.
 * This endpoint still runs the scan so clients can refresh care state; push/local
 * reminders are handled outside the inbox pipeline.
 *
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @param {Record<string, string>} [petNamesFromClient]
 * @param {{ clock?: { todayIso: string, nowTimeIso: string }|null }} [options] test clock
 */
export async function checkDueNotifications(pool, userId, petNamesFromClient = {}, { clock = null } = {}) {
  const entries = await pool.query(
    `SELECT he.id, he.pet_id, he.name, he.next_due_date, he.remind_days_before,
            p.name AS pet_name, p.home_timezone AS pet_home_timezone
     FROM health_entries he
     JOIN pets p ON p.id = he.pet_id
     WHERE ${accessiblePetSql('p', '$1')}
       AND he.next_due_date IS NOT NULL
       AND he.status = 'active'
       AND COALESCE(he.care_planning, 'planned') <> 'unplanned'
       AND (he.completed_on IS NULL OR COALESCE(he.frequency, 'once') <> 'once')`,
    [userId]
  );

  const todayByZone = new Map();

  for (const entry of entries.rows) {
    const dueIso = dateToIsoDate(entry.next_due_date);
    if (!dueIso) continue;
    const zone = normalizePetHomeTimezone(entry.pet_home_timezone);
    if (!todayByZone.has(zone)) todayByZone.set(zone, careAsOfForZone(zone, clock).todayIso);
    const todayIso = todayByZone.get(zone);
    const recipients = await petNotificationRecipientIds(pool, entry.pet_id);

    for (const recipientId of recipients) {
      const prefs = await loadUserPrefs(pool, recipientId);
      if (prefs.mutedPetIds.includes(String(entry.pet_id))) continue;

      const remindBefore = entry.remind_days_before ?? prefs.reminderDaysBefore ?? 1;
      const daysUntilDue = daysBetweenCalendarDates(todayIso, dueIso);

      if (daysUntilDue < 0 && prefs.notifyOverdue) {
        // Inbox row intentionally not created (v2).
      } else if (daysUntilDue >= 0 && daysUntilDue <= remindBefore && prefs.notifyDueSoon) {
        // Inbox row intentionally not created (v2).
      }
    }
  }

  return { checked: true, created: 0 };
}
