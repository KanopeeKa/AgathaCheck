/**
 * Phase E — weight-only guardian safeguard evaluation.
 * Reuses Phase D review-relevance pipeline; surfaces only when high bar met.
 */

import { evaluateReviewRelevance } from './reviewRelevance.js';

export const SAFEGUARD_POLICY_VERSION = '1.0.0';

export const SAFEGUARD_TYPES = {
  WEIGHT_TREND_DOWN: 'weight_trend_down',
};

/**
 * @param {{ pet: object, measurements: object[], weightContext?: object|null }} params
 * @returns {null | {
 *   safeguard_type: string,
 *   safeguard_key: string,
 *   copy_key: string,
 *   evidence: object,
 *   policy_version: string,
 * }}
 */
export function evaluateWeightSafeguard({ pet, measurements, weightContext = null }) {
  const result = evaluateReviewRelevance({
    pet,
    measurements,
    weightContext,
  });

  if (!result.review_relevant) {
    return null;
  }

  const changeSpec = result.weight_change_spec;
  if (!changeSpec || changeSpec.classification !== 'unexplained_material') {
    return null;
  }

  if (changeSpec.direction !== 'down') {
    return null;
  }

  const managementContext = weightContext?.management_context
    || result.trace?.weight_context?.management_context
    || 'none';
  if (managementContext !== 'none') {
    return null;
  }

  const petId = pet?.id || 'unknown';
  return {
    safeguard_type: SAFEGUARD_TYPES.WEIGHT_TREND_DOWN,
    safeguard_key: `weight_trend_down:${petId}`,
    copy_key: 'careSafeguardWeightTrendDown',
    evidence: {
      measurement_count: measurements.length,
      direction: changeSpec.direction,
      classification: changeSpec.classification,
      reasons: changeSpec.reasons,
      rules_fired: result.trace?.rules_fired || [],
      suppression_reasons: result.suppression_reasons || [],
    },
    policy_version: SAFEGUARD_POLICY_VERSION,
  };
}
