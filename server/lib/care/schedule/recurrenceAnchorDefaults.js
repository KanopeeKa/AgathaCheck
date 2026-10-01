/**
 * Per-family schedule type defaults (D-CSM-020, amends D-CSM-001).
 *
 * Medication → Fixed schedule (`from_due_date`): each dose is recorded.
 * Every other family → After it's done (`from_completion`): the next date
 * counts from the day it is done (parasite labels, boosters, D-ACP-007).
 */

export const RECURRENCE_ANCHOR_FROM_COMPLETION = 'from_completion';
export const RECURRENCE_ANCHOR_FROM_DUE_DATE = 'from_due_date';

/** Care families that default to a Fixed schedule when none is explicit. */
export const FIXED_SCHEDULE_CARE_FAMILIES = new Set(['medication']);

/** @deprecated kept for older imports; use FIXED_SCHEDULE_CARE_FAMILIES. */
export const CLINICAL_DUE_DATE_CARE_FAMILIES = FIXED_SCHEDULE_CARE_FAMILIES;

const VALID_ANCHORS = new Set([
  RECURRENCE_ANCHOR_FROM_COMPLETION,
  RECURRENCE_ANCHOR_FROM_DUE_DATE,
]);

/**
 * @param {string|null|undefined} careFamily
 * @returns {string}
 */
export function defaultRecurrenceAnchorForCareFamily(careFamily) {
  if (careFamily && FIXED_SCHEDULE_CARE_FAMILIES.has(careFamily)) {
    return RECURRENCE_ANCHOR_FROM_DUE_DATE;
  }
  return RECURRENCE_ANCHOR_FROM_COMPLETION;
}

/**
 * Resolve anchor for create/update when the client may omit recurrence_anchor.
 *
 * @param {object} params
 * @param {string|null|undefined} params.careFamily
 * @param {string|null|undefined} params.explicitAnchor from request body
 * @returns {string}
 */
export function resolveRecurrenceAnchorForWrite({ careFamily, explicitAnchor }) {
  const raw = explicitAnchor == null || explicitAnchor === ''
    ? null
    : String(explicitAnchor).trim();
  if (raw) {
    if (!VALID_ANCHORS.has(raw)) {
      throw new Error(`Invalid recurrence anchor: ${raw}`);
    }
    return raw;
  }
  return defaultRecurrenceAnchorForCareFamily(careFamily);
}
