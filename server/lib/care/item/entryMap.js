/**
 * Health entry (care item) list/detail wire shape — no open occurrences.
 */

import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { careBlocksForApi } from '../categoryBlocks/index.js';
import { resolveScheduleFlexibility } from '../schedule/scheduleFlexibility.js';

const LEGACY_HEALTH_ENTRY_TYPES = new Set(['family_event', 'procedure']);

export function normalizeHealthEntryTypeForRead(type) {
  if (!type) return type;
  if (LEGACY_HEALTH_ENTRY_TYPES.has(type)) return 'other';
  return type;
}

/**
 * @param {object} row health_entries row (optional pet_name join)
 * @returns {object}
 */
export function healthEntryToMap(row) {
  const todayIso = todayCalendarIso();
  const scheduleFlexibility = resolveScheduleFlexibility(row, todayIso);
  return {
    id: row.id,
    pet_id: row.pet_id,
    user_id: row.user_id,
    pet_name: row.pet_name || null,
    name: row.name || '',
    type: normalizeHealthEntryTypeForRead(row.type),
    dosage: row.dosage || '',
    frequency: row.frequency || 'once',
    frequency_days: row.frequency_days || null,
    frequency_interval: row.frequency_interval ?? 1,
    start_date: row.start_date ? dateToIsoDate(row.start_date) : null,
    next_due_date: row.next_due_date ? dateToIsoDate(row.next_due_date) : null,
    completed_on: row.completed_on
      ? dateToIsoDate(row.completed_on)
      : null,
    recurrence_anchor: row.recurrence_anchor || 'from_completion',
    repeat_end_date: row.repeat_end_date ? dateToIsoDate(row.repeat_end_date) : null,
    notes: row.notes || '',
    health_issue_id: row.health_issue_id || null,
    remind_days_before: row.remind_days_before ?? 1,
    schedule_times: row.schedule_times ?? null,
    status: row.status || 'active',
    care_family: row.care_family ?? null,
    care_setting: row.care_setting ?? null,
    care_planning: row.care_planning ?? null,
    care_importance: row.care_importance ?? null,
    importance_overridden: row.importance_overridden ?? false,
    care_source: row.care_source || 'guardian_defined',
    schedule_flexibility: scheduleFlexibility,
    schedule_policy_version: row.schedule_policy_version ?? null,
    provider_contact_id: row.provider_contact_id ?? null,
    provider_typed_name: row.provider_typed_name ?? null,
    care_blocks: careBlocksForApi(row),
    completed_at: row.completed_at ? row.completed_at.toISOString?.() || String(row.completed_at) : null,
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
    updated_at: row.updated_at ? row.updated_at.toISOString?.() || String(row.updated_at) : null,
  };
}
