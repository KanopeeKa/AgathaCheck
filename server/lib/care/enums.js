/** Canonical care family and source enums (CP-0). */

export const CARE_FAMILIES = new Set([
  'medication',
  'vaccination',
  'parasite_prevention',
  'wellness_review',
  'dental',
  'weight_monitoring',
  'grooming',
  'nail_care',
  'other',
]);

/** Subset used by Phase C crisp-rule suggestions. */
export const CIM_SUGGESTION_CARE_FAMILIES = new Set([
  'weight_monitoring',
  'dental',
  'wellness_review',
]);

export const CARE_SOURCES = new Set([
  'guardian_defined',
  'vet_instruction',
  'treatment_schedule',
  'care_plan',
  'agatha_accepted',
  'agatha_adjusted',
  'system_default',
]);

export function validateCareFamily(value, { required = false } = {}) {
  if (value == null || value === '') {
    if (required) return { ok: false, error: 'care_family is required for recurring care' };
    return { ok: true, value: null };
  }
  if (!CARE_FAMILIES.has(value)) {
    return { ok: false, error: `Invalid care family: ${value}` };
  }
  return { ok: true, value };
}

export function validateCareSource(value) {
  if (value == null || value === '') return { ok: true, value: 'guardian_defined' };
  if (!CARE_SOURCES.has(value)) {
    return { ok: false, error: `Invalid care source: ${value}` };
  }
  return { ok: true, value };
}
