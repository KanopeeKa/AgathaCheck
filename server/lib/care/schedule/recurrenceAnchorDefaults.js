/**
 * Per-family recurrence anchor defaults (D-CSM-001).
 *
 * Clinical-interval families default to fixed cadence; guardian-paced families
 * default to completion-based scheduling.
 */

export const RECURRENCE_ANCHOR_FROM_COMPLETION = 'from_completion';
export const RECURRENCE_ANCHOR_FROM_DUE_DATE = 'from_due_date';

/** Care families that use clinical fixed-interval anchors when none is explicit. */
export const CLINICAL_DUE_DATE_CARE_FAMILIES = new Set([
  'vaccination',
  'parasite_prevention',
]);

const VALID_ANCHORS = new Set([
  RECURRENCE_ANCHOR_FROM_COMPLETION,
  RECURRENCE_ANCHOR_FROM_DUE_DATE,
]);

/**
 * @param {string|null|undefined} careFamily
 * @returns {string}
 */
export function defaultRecurrenceAnchorForCareFamily(careFamily) {
  if (careFamily && CLINICAL_DUE_DATE_CARE_FAMILIES.has(careFamily)) {
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
