export const MICROCHIP_WELFARE_SUBJECT_KEY = 'microchip_welfare';
export const MICROCHIP_WELFARE_ENGINE_VERSION = '1.0.0';
export const MICROCHIP_WELFARE_RATIONALE_KEY = 'careWelfareMicrochipWhy';
export const MICROCHIP_WELFARE_SEVERITY = 5;

export function microchipWelfareDedupeKey(petId) {
  return `welfare:microchip:${petId}`;
}

/**
 * AC-WF-10 / ACJ-WF-07: offer welfare when guardian recorded identification_status=no.
 * Completeness cards own `unknown`; welfare nudges after an explicit "no".
 *
 * @param {Record<string, unknown>} pet
 * @returns {null | { subject_key: string, dedupe_key: string, rationale_key: string, engine_version: string, severity: number }}
 */
export function evaluateMicrochipWelfare(pet) {
  if (!pet || !pet.id) return null;
  const status = String(pet.identification_status ?? 'unknown').toLowerCase();
  if (status !== 'no') return null;
  const chip = String(pet.chip_id ?? '').trim();
  if (chip) return null;
  if (pet.chip_dismissed) return null;

  return {
    subject_key: MICROCHIP_WELFARE_SUBJECT_KEY,
    dedupe_key: microchipWelfareDedupeKey(pet.id),
    rationale_key: MICROCHIP_WELFARE_RATIONALE_KEY,
    engine_version: MICROCHIP_WELFARE_ENGINE_VERSION,
    severity: MICROCHIP_WELFARE_SEVERITY,
  };
}
