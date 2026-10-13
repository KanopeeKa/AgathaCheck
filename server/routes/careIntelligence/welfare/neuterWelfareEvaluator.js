import { speciesSupportsNeutering } from '../../../lib/pets/speciesNeutering.js';

export const NEUTER_WELFARE_SUBJECT_KEY = 'neuter_welfare';
export const NEUTER_WELFARE_ENGINE_VERSION = '1.0.0';
export const NEUTER_WELFARE_RATIONALE_KEY = 'careWelfareNeuterWhy';
export const NEUTER_WELFARE_SEVERITY = 5;

export function neuterWelfareDedupeKey(petId) {
  return `welfare:neuter:${petId}`;
}

/**
 * PR-08: welfare when neuter_status is unknown (completeness slot uses chip only).
 *
 * @param {Record<string, unknown>} pet
 */
export function evaluateNeuterWelfare(pet) {
  if (!pet || !pet.id) return null;
  if (!speciesSupportsNeutering(pet.species)) return null;
  const status = String(pet.neuter_status ?? 'unknown').toLowerCase();
  if (status !== 'unknown') return null;
  if (pet.neuter_dismissed) return null;

  return {
    subject_key: NEUTER_WELFARE_SUBJECT_KEY,
    dedupe_key: neuterWelfareDedupeKey(pet.id),
    rationale_key: NEUTER_WELFARE_RATIONALE_KEY,
    engine_version: NEUTER_WELFARE_ENGINE_VERSION,
    severity: NEUTER_WELFARE_SEVERITY,
  };
}
