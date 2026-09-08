import { ENGINE_VERSION, KNOWLEDGE_VERSION } from './shared.js';

/**
 * Ephemeral internal evidence trace for Phase D evaluation runs.
 * Not persisted to production guardian surfaces in Phase D.
 *
 * @typedef {Object} PhaseDEvidenceTrace
 * @property {string} trace_id
 * @property {string} pet_id
 * @property {string} evaluated_at ISO-8601
 * @property {string} engine_version
 * @property {string} knowledge_version
 * @property {Object[]} measurements
 * @property {Object|null} weight_context
 * @property {Object|null} weight_change_spec
 * @property {string[]} suppressions
 * @property {string[]} rules_fired
 */

export function createPhaseDEvidenceTrace({
  traceId,
  petId,
  measurements = [],
  weightContext = null,
  weightChangeSpec = null,
  suppressions = [],
  rulesFired = [],
  evaluatedAt = new Date().toISOString(),
}) {
  return {
    trace_id: traceId,
    pet_id: petId,
    evaluated_at: evaluatedAt,
    engine_version: ENGINE_VERSION,
    knowledge_version: KNOWLEDGE_VERSION,
    measurements,
    weight_context: weightContext,
    weight_change_spec: weightChangeSpec,
    suppressions,
    rules_fired: rulesFired,
  };
}
