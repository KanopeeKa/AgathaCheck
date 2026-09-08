/**
 * WeightChangeSpec — D2 material, persistent weight change evaluation.
 */

import { monthsBetween } from './shared.js';

export const CHANGE_THRESHOLDS = {
  MIN_MEASUREMENTS: 3,
  MATERIAL_PCT: 0.05,
  MATERIAL_ABSOLUTE_KG: 0.3,
  ORDINARY_FLUCTUATION_PCT: 0.03,
  PUPPY_KITTEN_MONTHS: 12,
  REFERENCE_TOLERANCE_PCT: 0.05,
};

function parseDateMs(dateStr) {
  return Date.parse(`${dateStr}T00:00:00Z`);
}

function sortedMeasurements(measurements) {
  return [...measurements].sort((a, b) => parseDateMs(a.date) - parseDateMs(b.date));
}

function isLifeStageGrowthOrdinary(pet, direction, asOf) {
  if (!pet?.date_of_birth) return false;
  const ageMonths = monthsBetween(pet.date_of_birth, asOf);
  return ageMonths < CHANGE_THRESHOLDS.PUPPY_KITTEN_MONTHS && direction === 'up';
}

function isWithinReferenceTolerance(lastWeight, referenceValue) {
  if (!referenceValue || referenceValue <= 0) return false;
  const diffPct = Math.abs(lastWeight - referenceValue) / referenceValue;
  return diffPct <= CHANGE_THRESHOLDS.REFERENCE_TOLERANCE_PCT;
}

function isMaterialChange(deltaKg, deltaPct) {
  return Math.abs(deltaPct) >= CHANGE_THRESHOLDS.MATERIAL_PCT
    || Math.abs(deltaKg) >= CHANGE_THRESHOLDS.MATERIAL_ABSOLUTE_KG;
}

function isPersistentDown(measurements) {
  const recent = sortedMeasurements(measurements).slice(-3);
  if (recent.length < 3) return false;
  return recent[0].weight > recent[1].weight && recent[1].weight > recent[2].weight;
}

function isPersistentUp(measurements) {
  const recent = sortedMeasurements(measurements).slice(-3);
  if (recent.length < 3) return false;
  return recent[0].weight < recent[1].weight && recent[1].weight < recent[2].weight;
}

/**
 * @param {import('./weightChangeSpec.js').WeightMeasurement[]} measurements
 * @param {import('./weightChangeSpec.js').WeightContext} context
 * @param {{ date_of_birth?: string|null }} [pet]
 * @param {Date|string} [asOf] calendar date for life-stage checks (defaults to last measurement)
 */
export function evaluateWeightChangeSpec(measurements, context, pet = null, asOf = null) {
  if (!Array.isArray(measurements) || measurements.length < CHANGE_THRESHOLDS.MIN_MEASUREMENTS) {
    return {
      classification: 'insufficient_data',
      direction: null,
      persistent: false,
      reasons: ['measurement_count_below_minimum'],
    };
  }

  const sorted = sortedMeasurements(measurements);
  const evaluationDate = asOf
    || sorted[sorted.length - 1]?.date
    || new Date();
  const first = sorted[0].weight;
  const last = sorted[sorted.length - 1].weight;
  const deltaKg = last - first;
  const deltaPct = first > 0 ? deltaKg / first : 0;
  let direction = 'flat';
  if (deltaPct > 0.02) direction = 'up';
  else if (deltaPct < -0.02) direction = 'down';

  const managementContext = context?.management_context || 'none';
  if (managementContext !== 'none') {
    return {
      classification: 'explained',
      direction,
      persistent: false,
      reasons: [`management_context:${managementContext}`],
    };
  }

  if (context?.reference_authority && context?.reference_value) {
    if (isWithinReferenceTolerance(last, context.reference_value)) {
      return {
        classification: 'explained',
        direction,
        persistent: false,
        reasons: [`reference_authority:${context.reference_authority}`],
      };
    }
  }

  if (!isMaterialChange(deltaKg, deltaPct)) {
    return {
      classification: 'ordinary',
      direction,
      persistent: false,
      reasons: ['change_below_material_threshold'],
    };
  }

  if (isLifeStageGrowthOrdinary(pet, direction, evaluationDate)) {
    return {
      classification: 'ordinary',
      direction,
      persistent: true,
      reasons: ['life_stage_growth'],
    };
  }

  if (Math.abs(deltaPct) < CHANGE_THRESHOLDS.ORDINARY_FLUCTUATION_PCT * 2 && !isPersistentDown(sorted) && !isPersistentUp(sorted)) {
    return {
      classification: 'ordinary',
      direction,
      persistent: false,
      reasons: ['short_term_fluctuation'],
    };
  }

  const persistent = direction === 'down'
    ? isPersistentDown(sorted)
    : direction === 'up'
      ? isPersistentUp(sorted)
      : false;

  if (!persistent) {
    return {
      classification: 'ordinary',
      direction,
      persistent: false,
      reasons: ['not_persistent'],
    };
  }

  return {
    classification: 'unexplained_material',
    direction,
    persistent: true,
    reasons: ['material_persistent_change'],
  };
}
