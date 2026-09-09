/**
 * Weight establishment policy (care_progression) — cadence-relative, versioned.
 * @see docs/domains/pet_care/features/care-progression.md
 */

import { CareFamilyCapabilityPolicy } from '../capabilities.js';
import {
  daysBetween,
  hasConsistentWeightUnits,
  isValidWeightMeasurementShape,
  prepareWeightMeasurements,
} from '../observations/weightPrimitives.js';

export const WEIGHT_ESTABLISHMENT_POLICY_VERSION = '1.0.0';

/** @typedef {'high' | 'medium' | 'low_deferred' | 'not_recurring'} CadenceBand */

export const CADENCE_BAND_REQUIREMENTS = {
  high: {
    minCompletedOccurrences: 4,
    minSpanDays: 21,
    minMeasurements: 3,
  },
  medium: {
    minCompletedOccurrences: 3,
    minSpanDays: 56,
    minMeasurements: 3,
  },
};

/**
 * @param {{ frequency?: string, frequency_interval?: number, frequency_days?: number }} entry
 * @returns {CadenceBand}
 */
export function resolveCadenceBand(entry) {
  const freq = entry?.frequency || 'once';
  const interval = Math.max(1, entry?.frequency_interval ?? 1);

  if (freq === 'once') return 'not_recurring';
  if (freq === 'yearly') return 'low_deferred';

  let daysBetweenOccurrences;
  switch (freq) {
    case 'daily':
      daysBetweenOccurrences = interval;
      break;
    case 'weekly':
      daysBetweenOccurrences = 7 * interval;
      break;
    case 'monthly':
      daysBetweenOccurrences = 30 * interval;
      break;
    case 'custom':
      daysBetweenOccurrences = Math.max(1, entry?.frequency_days || interval);
      break;
    default:
      daysBetweenOccurrences = interval;
  }

  if (daysBetweenOccurrences <= 14) return 'high';
  if (daysBetweenOccurrences <= 45) return 'medium';
  return 'low_deferred';
}

/**
 * @param {{ date: string, weight: number, unit?: string }[]} measurements
 */
export function passesProgressionQualityPrimitives(measurements) {
  const prepared = prepareWeightMeasurements(measurements);
  if (prepared.length < CADENCE_BAND_REQUIREMENTS.high.minMeasurements) {
    return { ok: false, reason: 'measurement_count_below_minimum' };
  }
  if (!hasConsistentWeightUnits(prepared)) {
    return { ok: false, reason: 'mixed_units' };
  }
  if (!prepared.every(isValidWeightMeasurementShape)) {
    return { ok: false, reason: 'invalid_measurement_shape' };
  }
  return { ok: true, measurements: prepared };
}

/**
 * @param {object} facts
 * @param {object | null} facts.entry
 * @param {object | null} [facts.existingEstablishment]
 * @param {object[]} [facts.completedEvidence]
 * @param {number} [facts.skippedCount]
 * @param {number} [facts.legacyCompletedWithoutWeight]
 * @returns {{ maturity: null | 'established', reasonCodes: string[], policyVersion: string }}
 */
export function evaluateWeightEstablishment(_petId, _healthEntryId, facts = {}) {
  const reasonCodes = [];
  const policyVersion = WEIGHT_ESTABLISHMENT_POLICY_VERSION;
  const entry = facts.entry || null;

  if (facts.existingEstablishment) {
    return {
      maturity: null,
      reasonCodes: ['already_established'],
      policyVersion,
    };
  }

  if (!entry) {
    return { maturity: null, reasonCodes: ['entry_not_found'], policyVersion };
  }

  const careFamily = entry.care_family;
  if (!careFamily || !CareFamilyCapabilityPolicy.supportsEstablishment(careFamily)) {
    return { maturity: null, reasonCodes: ['ambiguous_family'], policyVersion };
  }

  if (careFamily !== 'weight_monitoring') {
    return { maturity: null, reasonCodes: ['ambiguous_family'], policyVersion };
  }

  if ((entry.status || 'active') !== 'active') {
    return { maturity: null, reasonCodes: ['inactive_rhythm'], policyVersion };
  }

  const cadenceBand = resolveCadenceBand(entry);
  if (cadenceBand === 'not_recurring' || cadenceBand === 'low_deferred') {
    return { maturity: null, reasonCodes: ['not_evaluable'], policyVersion };
  }

  const requirements = CADENCE_BAND_REQUIREMENTS[cadenceBand];
  const evidence = (facts.completedEvidence || []).filter((item) => item?.measurement);
  const measurements = evidence.map((item) => item.measurement);

  if ((facts.legacyCompletedWithoutWeight || 0) > 0) {
    reasonCodes.push('legacy_completion_ignored');
  }
  if ((facts.skippedCount || 0) > 0) {
    reasonCodes.push('skipped_occurrences_excluded');
  }

  if (evidence.length < requirements.minCompletedOccurrences) {
    reasonCodes.push(
      evidence.length === 0 ? 'insufficient_evidence' : 'accumulating_evidence',
    );
    return { maturity: null, reasonCodes, policyVersion };
  }

  const quality = passesProgressionQualityPrimitives(measurements);
  if (!quality.ok) {
    reasonCodes.push(quality.reason);
    return { maturity: null, reasonCodes, policyVersion };
  }

  const prepared = quality.measurements;
  const spanDays = prepared.length >= 2
    ? daysBetween(prepared[0].date, prepared[prepared.length - 1].date)
    : 0;

  if (spanDays < requirements.minSpanDays) {
    reasonCodes.push('accumulating_evidence');
    return { maturity: null, reasonCodes, policyVersion };
  }

  if (prepared.length < requirements.minMeasurements) {
    reasonCodes.push('insufficient_evidence');
    return { maturity: null, reasonCodes, policyVersion };
  }

  return {
    maturity: 'established',
    reasonCodes: ['established'],
    policyVersion,
  };
}
