import { speciesSupportsVaccinationWelfare } from '../../../lib/pets/speciesVaccination.js';

export const VACCINATION_WELFARE_SUBJECT_KEY = 'vaccination_welfare';
export const VACCINATION_WELFARE_ENGINE_VERSION = '1.0.0';
export const VACCINATION_WELFARE_RATIONALE_KEY = 'careWelfareVaccinationWhy';
export const VACCINATION_WELFARE_SEVERITY = 4;

export function vaccinationWelfareDedupeKey(petId) {
  return `welfare:vaccination:${petId}`;
}

/**
 * AC-WF-11: offer welfare only when species is supported and vaccination
 * summary is available with zero records; silence when data quality is below threshold.
 *
 * @param {Record<string, unknown>} pet
 * @param {{ vaccinationSummary?: { record_count?: number } }} [context]
 */
export function evaluateVaccinationWelfare(pet, context = {}) {
  if (!pet || !pet.id) return null;
  if (pet.passed_away) return null;
  if (!speciesSupportsVaccinationWelfare(pet.species)) return null;

  const summary = context.vaccinationSummary;
  if (!summary || typeof summary.record_count !== 'number') {
    return null;
  }
  if (summary.record_count > 0) return null;

  return {
    subject_key: VACCINATION_WELFARE_SUBJECT_KEY,
    dedupe_key: vaccinationWelfareDedupeKey(pet.id),
    rationale_key: VACCINATION_WELFARE_RATIONALE_KEY,
    engine_version: VACCINATION_WELFARE_ENGINE_VERSION,
    severity: VACCINATION_WELFARE_SEVERITY,
  };
}
