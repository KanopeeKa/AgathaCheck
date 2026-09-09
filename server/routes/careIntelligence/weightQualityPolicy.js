/**
 * CIM weight series adequacy policy (care_intelligence).
 * Uses shared observation primitives — thresholds stay in CIM.
 */

import {
  daysBetween,
  hasConsistentWeightUnits,
  median,
  parseDateMs,
  stdDev,
} from '../../lib/care/observations/weightPrimitives.js';

export const QUALITY_THRESHOLDS = {
  MIN_MEASUREMENTS: 3,
  MIN_SPAN_DAYS: 14,
  MAX_SINGLE_GAP_DAYS: 60,
  MIN_MEDIAN_SPACING_DAYS: 3,
  MAX_OUTLIER_Z_SCORE: 3.5,
};

/**
 * @param {{ date: string, weight: number, unit?: string }[]} measurements chronological
 */
export function classifyWeightSeriesQuality(measurements) {
  const reasons = [];
  if (!Array.isArray(measurements) || measurements.length === 0) {
    return { adequate: false, reasons: ['no_measurements'], metrics: {} };
  }

  const sorted = [...measurements].sort((a, b) => parseDateMs(a.date) - parseDateMs(b.date));

  if (!hasConsistentWeightUnits(sorted)) {
    reasons.push('mixed_units');
  }

  if (sorted.length < QUALITY_THRESHOLDS.MIN_MEASUREMENTS) {
    reasons.push('measurement_count_below_minimum');
  }

  const spanDays = sorted.length >= 2
    ? daysBetween(sorted[0].date, sorted[sorted.length - 1].date)
    : 0;
  if (spanDays < QUALITY_THRESHOLDS.MIN_SPAN_DAYS) {
    reasons.push('span_below_minimum');
  }

  const gaps = [];
  for (let i = 1; i < sorted.length; i += 1) {
    gaps.push(daysBetween(sorted[i - 1].date, sorted[i].date));
  }
  const maxGap = gaps.length ? Math.max(...gaps) : 0;
  if (maxGap > QUALITY_THRESHOLDS.MAX_SINGLE_GAP_DAYS) {
    reasons.push('gap_too_large');
  }

  const medianSpacing = gaps.length ? median(gaps) : 0;
  if (gaps.length && medianSpacing < QUALITY_THRESHOLDS.MIN_MEDIAN_SPACING_DAYS) {
    reasons.push('measurements_too_clustered');
  }

  const weights = sorted.map((m) => m.weight);
  const mean = weights.reduce((s, w) => s + w, 0) / weights.length;
  const sd = stdDev(weights, mean);
  if (sd > 0) {
    const outliers = weights.filter(
      (w) => Math.abs((w - mean) / sd) > QUALITY_THRESHOLDS.MAX_OUTLIER_Z_SCORE,
    );
    if (outliers.length > 0) {
      reasons.push('outlier_present');
    }
  }

  const units = new Set(sorted.map((m) => (m.unit || 'kg').toLowerCase()));
  const metrics = {
    count: sorted.length,
    span_days: spanDays,
    max_gap_days: maxGap,
    median_spacing_days: medianSpacing,
    unit: units.size === 1 ? [...units][0] : 'mixed',
  };

  return {
    adequate: reasons.length === 0,
    reasons,
    metrics,
  };
}
