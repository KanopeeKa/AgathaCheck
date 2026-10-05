/**
 * Care Intelligence provenance enums (D0 contract).
 * Distinct from health_entries.care_source (rhythm provenance).
 */

export const MEASUREMENT_SOURCES = new Set([
  'guardian',
  'clinic',
  'device',
  'imported',
]);

export const REFERENCE_AUTHORITIES = new Set([
  'vet_target',
  'guardian_reference',
  'historical_baseline',
]);

export const MANAGEMENT_CONTEXTS = new Set([
  'none',
  'vet_managed',
  'care_plan',
  'treatment_related',
]);

export function validateMeasurementSource(value, { required = false } = {}) {
  if (value === undefined || value === null || value === '') {
    if (required) return { ok: false, error: 'measurement_source is required' };
    return { ok: true, value: 'guardian' };
  }
  const normalized = String(value).trim().toLowerCase();
  if (!MEASUREMENT_SOURCES.has(normalized)) {
    return { ok: false, error: 'invalid measurement_source' };
  }
  return { ok: true, value: normalized };
}

export function validateReferenceAuthority(value, { required = false } = {}) {
  if (value === undefined || value === null || value === '') {
    if (required) return { ok: false, error: 'weight_reference_authority is required' };
    return { ok: true, value: null };
  }
  const normalized = String(value).trim().toLowerCase();
  if (!REFERENCE_AUTHORITIES.has(normalized)) {
    return { ok: false, error: 'invalid weight_reference_authority' };
  }
  return { ok: true, value: normalized };
}

export function validateManagementContext(value, { required = false } = {}) {
  if (value === undefined || value === null || value === '') {
    if (required) return { ok: false, error: 'weight_management_context is required' };
    return { ok: true, value: 'none' };
  }
  const normalized = String(value).trim().toLowerCase();
  if (!MANAGEMENT_CONTEXTS.has(normalized)) {
    return { ok: false, error: 'invalid weight_management_context' };
  }
  return { ok: true, value: normalized };
}

/**
 * Pet-level weight context for review-relevance (not inferred from measurement_source).
 */
export function weightContextFromPetRow(row) {
  if (!row) return null;
  return {
    reference_value: row.weight_reference_value ?? null,
    reference_authority: row.weight_reference_authority ?? null,
    management_context: row.weight_management_context || 'none',
  };
}
