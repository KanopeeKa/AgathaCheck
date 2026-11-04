/**
 * Seed care through the same commands as the app (D-CSM-033): no SQL on
 * health_occurrences. Clocks are pet-home wall clocks relative to the seed
 * day, so time-dependent statuses (Overdue, Not recorded) come out right.
 */
import {
  applyCareCommand,
  careAsOfForZone,
  completeOccurrenceCommand,
  createInitialOccurrences,
  listOpenRows,
  planAnotherDateCommand,
  postponeCommand,
  resolveStackCommand,
  skipOccurrenceCommand,
} from '../../../lib/care/occurrence/index.js';
import { addDaysIso } from '../../../lib/care/schedule/seriesDates.js';
import { resolveRecurrenceAnchorForWrite } from '../../../lib/care/schedule/recurrenceAnchorDefaults.js';
import { SCHEDULE_POLICY_VERSION } from '../../../lib/care/schedule/schedulePolicy.js';
import { defaultsForCareFamily, deriveLegacyHealthEntryType } from '../../../lib/care/taxonomy/index.js';

export const SEED_PET_TIMEZONE = 'Europe/Paris';

/**
 * Seed "now": the real pet-home clock, or `SEED_CARE_CLOCK=YYYY-MM-DDTHH:MM`
 * (DB tests pin it so the dataset is identical whatever the time of day).
 *
 * @param {string} [timeZone]
 * @returns {{ todayIso: string, nowTimeIso: string, timeZone: string }}
 */
export function seedNow(timeZone = SEED_PET_TIMEZONE) {
  const pinned = process.env.SEED_CARE_CLOCK;
  if (pinned) {
    const [todayIso, time] = pinned.split('T');
    return careAsOfForZone(timeZone, { todayIso, nowTimeIso: (time || '12:00').slice(0, 5) });
  }
  return careAsOfForZone(timeZone);
}

/**
 * A clock `offsetDays` from the seed day at a wall-clock time.
 *
 * @param {{ todayIso: string, timeZone: string }} now
 * @param {number} offsetDays
 * @param {string} time HH:MM
 */
export function clockAt(now, offsetDays, time) {
  return { todayIso: addDaysIso(now.todayIso, offsetDays), nowTimeIso: time, timeZone: now.timeZone };
}

/**
 * @param {{ todayIso: string }} now
 * @param {number} offsetDays
 */
export function dayFrom(now, offsetDays) {
  return addDaysIso(now.todayIso, offsetDays);
}

/**
 * Create (or recreate) a care item and its first occurrences. Idempotent:
 * an existing row with the same id is deleted first (its occurrences cascade).
 *
 * @param {import('pg').PoolClient} client open transaction
 * @param {object} item
 * @param {{ todayIso: string, nowTimeIso: string, timeZone: string }} clock creation clock
 */
export async function createSeedCareItem(client, item, clock) {
  const defaults = defaultsForCareFamily(item.careFamily);
  const setting = item.setting || defaults.care_setting || 'home';
  const planning = item.completedOn ? 'unplanned' : 'planned';
  const frequency = item.frequency || 'once';
  const anchor = resolveRecurrenceAnchorForWrite({
    careFamily: item.careFamily,
    explicitAnchor: item.scheduleType || null,
  });
  await client.query('DELETE FROM health_entries WHERE id = $1', [item.id]);
  await client.query(
    `INSERT INTO health_entries (
       id, pet_id, user_id, type, name, dosage, frequency, frequency_interval,
       start_date, next_due_date, completed_on, status, remind_days_before, notes,
       care_family, care_setting, care_planning, care_importance, recurrence_anchor,
       schedule_times, late_completion_choice, schedule_policy_version
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
       $15, $16, $17, $18, $19, $20::jsonb, $21, $22)`,
    [
      item.id,
      item.petId,
      item.userId,
      deriveLegacyHealthEntryType(item.careFamily, setting),
      item.name,
      item.dosage || '',
      frequency,
      item.interval || 1,
      item.firstDate || item.completedOn,
      planning === 'planned' ? item.firstDate : null,
      item.completedOn || null,
      planning === 'planned' ? 'active' : 'completed',
      planning === 'planned' ? (item.remindDaysBefore ?? 1) : 0,
      item.notes || '',
      item.careFamily,
      setting,
      planning,
      item.importance || defaults.care_importance || 'recommended',
      anchor,
      item.times ? JSON.stringify(item.times) : null,
      item.lateChoice || null,
      SCHEDULE_POLICY_VERSION,
    ],
  );
  if (planning === 'unplanned') return null;
  return applyCareCommand(client, { entryId: item.id, userId: item.userId, asOf: clock }, (ctx) =>
    createInitialOccurrences(ctx, { firstDate: item.firstDate, plannedDates: item.plannedDates || [] }));
}

async function openRows(client, entryId) {
  return listOpenRows(client, entryId);
}

/**
 * Record every open dose dated `dateIso` as given, at `clock`.
 */
export async function recordDay(client, { entryId, userId }, dateIso, clock, { onlyTimes = null } = {}) {
  const rows = (await openRows(client, entryId)).filter((o) => o.scheduled_date === dateIso
    && (!onlyTimes || onlyTimes.includes(o.scheduled_time)));
  if (rows.length === 0) return null;
  return applyCareCommand(client, { entryId, userId, asOf: clock }, (ctx) =>
    resolveStackCommand(ctx, { given: rows.map((o) => o.id) }));
}

/**
 * Mark the earliest open date done at `clock` (Keep when a choice is needed).
 */
export async function completeEarliest(client, { entryId, userId }, clock, extra = {}) {
  const [first] = await openRows(client, entryId);
  if (!first) return null;
  return applyCareCommand(client, { entryId, userId, asOf: clock }, (ctx) =>
    completeOccurrenceCommand(ctx, { occurrenceId: first.id, nextChoice: 'keep', ...extra }));
}

export async function skipEarliest(client, { entryId, userId }, clock) {
  const [first] = await openRows(client, entryId);
  if (!first) return null;
  return applyCareCommand(client, { entryId, userId, asOf: clock }, (ctx) =>
    skipOccurrenceCommand(ctx, { occurrenceId: first.id }));
}

export async function planDate(client, { entryId, userId }, dateIso, clock) {
  return applyCareCommand(client, { entryId, userId, asOf: clock }, (ctx) =>
    planAnotherDateCommand(ctx, { date: dateIso }));
}

export async function postpone(client, { entryId, userId }, until, clock, extra = {}) {
  return applyCareCommand(client, { entryId, userId, asOf: clock }, (ctx) =>
    postponeCommand(ctx, { until, reason: until ? 'manual' : 'pause', ...extra }));
}

/**
 * Bring an item to "now" (catch-up only).
 */
export async function catchUp(client, { entryId, userId }, clock) {
  return applyCareCommand(client, { entryId, userId, asOf: clock }, async () => ({ event: null }));
}
