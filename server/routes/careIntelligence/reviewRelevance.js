import { v4 as uuidv4 } from 'uuid';

import { createPhaseDEvidenceTrace } from './evidenceTrace.js';
import { weightContextFromPetRow } from './provenance.js';
import { extractWeightFeatures } from './weightFeatureExtraction.js';
import { evaluateWeightChangeSpec } from './weightChangeSpec.js';

/**
 * Internal review-relevance evaluation (Phase D — not guardian-facing).
 *
 * @param {object} params
 * @param {object} params.pet pet row or map with date_of_birth, weight_reference_*
 * @param {object[]} params.measurements chronological weight entries
 * @param {object} [params.weightContext] optional override; defaults from pet row
 */
export function evaluateReviewRelevance({ pet, measurements, weightContext = null }) {
  const context = weightContext || weightContextFromPetRow(pet) || {
    reference_value: null,
    reference_authority: null,
    management_context: 'none',
  };

  const features = extractWeightFeatures(measurements);
  const quality = features.quality;

  if (!quality.adequate) {
    return {
      review_relevant: false,
      suppressed: true,
      suppression_reasons: quality.reasons,
      weight_change_spec: null,
      features,
      trace: createPhaseDEvidenceTrace({
        traceId: uuidv4(),
        petId: pet?.id || 'unknown',
        measurements,
        weightContext: context,
        weightChangeSpec: null,
        suppressions: quality.reasons,
        rulesFired: ['quality_classifier:inadequate'],
      }),
    };
  }

  const changeSpec = evaluateWeightChangeSpec(
    measurements,
    context,
    pet,
    measurements.length ? measurements[measurements.length - 1].date : null,
  );
  const suppressions = [];
  const rulesFired = [`weight_change_spec:${changeSpec.classification}`];

  if (changeSpec.classification === 'explained') {
    suppressions.push(...changeSpec.reasons);
  }
  if (changeSpec.classification === 'ordinary') {
    suppressions.push(...changeSpec.reasons);
  }
  if (changeSpec.classification === 'insufficient_data') {
    suppressions.push(...changeSpec.reasons);
  }

  const reviewRelevant = changeSpec.classification === 'unexplained_material';

  return {
    review_relevant: reviewRelevant,
    suppressed: !reviewRelevant,
    suppression_reasons: suppressions,
    weight_change_spec: changeSpec,
    features,
    trace: createPhaseDEvidenceTrace({
      traceId: uuidv4(),
      petId: pet?.id || 'unknown',
      measurements,
      weightContext: context,
      weightChangeSpec: changeSpec,
      suppressions,
      rulesFired,
    }),
  };
}
