/**
 * WeightChangeSpec — material, persistent weight change evaluation (D0 interface; D2 implementation).
 *
 * @typedef {Object} WeightMeasurement
 * @property {string} date YYYY-MM-DD
 * @property {number} weight
 * @property {string} unit
 * @property {string} measurement_source
 *
 * @typedef {Object} WeightContext
 * @property {number|null} reference_value
 * @property {string|null} reference_authority
 * @property {string} management_context
 *
 * @typedef {Object} WeightChangeSpecResult
 * @property {'insufficient_data'|'ordinary'|'explained'|'unexplained_material'} classification
 * @property {string|null} direction 'up'|'down'|null
 * @property {boolean} persistent
 * @property {string[]} reasons
 */

const MIN_MEASUREMENTS = 3;

/**
 * Sketch evaluator — returns insufficient_data until D2 thresholds ship.
 * @param {WeightMeasurement[]} measurements newest last
 * @param {WeightContext} context
 * @returns {WeightChangeSpecResult}
 */
export function evaluateWeightChangeSpec(measurements, context) {
  const reasons = [];
  if (!Array.isArray(measurements) || measurements.length < MIN_MEASUREMENTS) {
    return {
      classification: 'insufficient_data',
      direction: null,
      persistent: false,
      reasons: ['measurement_count_below_minimum'],
    };
  }

  if (context?.management_context && context.management_context !== 'none') {
    return {
      classification: 'explained',
      direction: null,
      persistent: false,
      reasons: [`management_context:${context.management_context}`],
    };
  }

  if (context?.reference_authority) {
    reasons.push(`reference_authority:${context.reference_authority}`);
  }

  return {
    classification: 'insufficient_data',
    direction: null,
    persistent: false,
    reasons: reasons.length ? reasons : ['d2_thresholds_not_implemented'],
  };
}
