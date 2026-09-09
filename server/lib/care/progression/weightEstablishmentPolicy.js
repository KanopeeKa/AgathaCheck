/**
 * Weight establishment policy (care_progression) — full evaluator ships in CP-3.
 */

export const WEIGHT_ESTABLISHMENT_POLICY_VERSION = '0.0.0-stub';

/**
 * @param {string} _petId
 * @param {string} _healthEntryId
 * @param {object} [_facts]
 * @returns {{ maturity: null, reasonCodes: string[], policyVersion: string }}
 */
export function evaluateWeightEstablishment(_petId, _healthEntryId, _facts = {}) {
  return {
    maturity: null,
    reasonCodes: ['not_implemented'],
    policyVersion: WEIGHT_ESTABLISHMENT_POLICY_VERSION,
  };
}
