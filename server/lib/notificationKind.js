/**
 * Notification kind / priority wire values and type→kind defaults (experience-program §3.1).
 */

export const NOTIFICATION_KIND_CARE = 'care';
export const NOTIFICATION_KIND_ADMINISTRATIVE = 'administrative';

export const NOTIFICATION_PRIORITY_NORMAL = 'normal';
export const NOTIFICATION_PRIORITY_URGENT = 'urgent';

const VALID_KINDS = new Set([NOTIFICATION_KIND_CARE, NOTIFICATION_KIND_ADMINISTRATIVE]);
const VALID_PRIORITIES = new Set([
  NOTIFICATION_PRIORITY_NORMAL,
  NOTIFICATION_PRIORITY_URGENT,
]);

/** Existing notification `type` values default to care-kind at creation time. */
export function defaultKindForType(type = 'general') {
  void type;
  return NOTIFICATION_KIND_CARE;
}

export function normaliseKind(value) {
  const kind = String(value || NOTIFICATION_KIND_CARE).toLowerCase();
  return VALID_KINDS.has(kind) ? kind : NOTIFICATION_KIND_CARE;
}

export function normalisePriority(value) {
  const priority = String(value || NOTIFICATION_PRIORITY_NORMAL).toLowerCase();
  return VALID_PRIORITIES.has(priority) ? priority : NOTIFICATION_PRIORITY_NORMAL;
}
