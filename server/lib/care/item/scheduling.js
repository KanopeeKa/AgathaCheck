/**
 * Care item occurrence wire maps and schedule input helpers (pure).
 * Occurrence writes live in `server/lib/care/occurrence/`.
 */

import {
  dateToIsoDate,
  normalizeCalendarDateInput,
  todayCalendarIso,
} from '../../calendarDate.js';
import { normalizeTime, scheduleTimesFromEntry } from '../schedule/scheduleTimes.js';

export { normalizeTime, scheduleTimesFromEntry };

/**
 * @param {object} row health_entries row
 * @returns {boolean}
 */
export function isOnceEntry(row) {
  return (row.frequency || 'once') === 'once';
}

/**
 * @param {object} row
 * @returns {boolean}
 */
export function isMultiPerDayEntry(row) {
  const times = scheduleTimesFromEntry(row);
  return times.length > 1;
}

/**
 * Past its time (timed) or its day (untimed).
 *
 * @param {string} scheduledDateIso YYYY-MM-DD
 * @param {string|null} scheduledTime HH:MM or null (all-day)
 * @param {string} todayIso
 * @param {string|null} nowTimeIso HH:MM (pet home wall clock)
 */
export function isOccurrenceMissed(scheduledDateIso, scheduledTime, todayIso, nowTimeIso) {
  if (!scheduledDateIso) return false;
  if (scheduledDateIso < todayIso) return true;
  if (scheduledDateIso > todayIso) return false;
  if (scheduledTime == null) return false;
  const nowT = nowTimeIso || '00:00';
  return nowT > scheduledTime;
}

/**
 * @param {object} row DB row
 * @returns {object}
 */
export function occurrenceToMap(row) {
  const time = row.scheduled_time
    ? String(row.scheduled_time).slice(0, 5)
    : null;
  return {
    id: row.id,
    health_entry_id: row.health_entry_id,
    entry_id: row.health_entry_id,
    scheduled_date: dateToIsoDate(row.scheduled_date),
    scheduled_time: time,
    status: row.status,
    completed_on: row.completed_on ? dateToIsoDate(row.completed_on) : null,
    marked_at: row.marked_at ? row.marked_at.toISOString?.() || String(row.marked_at) : null,
    marked_by_user_id: row.marked_by_user_id || null,
    marked_by_name: row.marked_by_name?.trim() || null,
    marked_by_snapshot: row.marked_by_snapshot ?? null,
    performed_by_user_id: row.performed_by_user_id || null,
    performed_by_snapshot: row.performed_by_snapshot ?? null,
    notes: row.notes || '',
    completion_timing: row.completion_timing ?? null,
    provider_contact_id: row.provider_contact_id ?? null,
    provider_typed_name: row.provider_typed_name ?? null,
    provider_contact_snapshot: row.provider_contact_snapshot ?? null,
    origin: row.origin ?? null,
    close_reason: row.close_reason ?? null,
  };
}

/**
 * Parse schedule_times from create/update body.
 * @param {object} data
 * @returns {object|null} JSONB-ready value
 */
export function parseScheduleTimesInput(data) {
  const raw = data.schedule_times ?? data.scheduleTimes;
  if (raw === undefined) return undefined;
  if (raw === null) return null;
  if (!Array.isArray(raw)) return null;
  if (raw.length === 0) return null;
  return raw.map((t) => normalizeTime(t));
}

/**
 * @param {string|null|undefined} completedOnBody
 * @param {string} todayIso
 */
export function resolveCompletedOn(completedOnBody, todayIso = todayCalendarIso()) {
  return normalizeCalendarDateInput(completedOnBody) || todayIso;
}
