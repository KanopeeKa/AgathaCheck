/**
 * D1 — weight feature extraction for review-relevance evaluation.
 */

import { classifyWeightSeriesQuality } from './weightQualityClassifier.js';

function parseDateMs(dateStr) {
  return Date.parse(`${dateStr}T00:00:00Z`);
}

/**
 * @param {{ date: string, weight: number, unit?: string, measurement_source?: string }[]} measurements
 */
export function extractWeightFeatures(measurements) {
  const quality = classifyWeightSeriesQuality(measurements);
  if (!measurements?.length) {
    return { quality, series: null };
  }

  const sorted = [...measurements].sort((a, b) => parseDateMs(a.date) - parseDateMs(b.date));
  const weights = sorted.map((m) => m.weight);
  const first = weights[0];
  const last = weights[weights.length - 1];
  const delta = last - first;
  const deltaPct = first > 0 ? delta / first : 0;

  let direction = 'flat';
  if (deltaPct > 0.02) direction = 'up';
  else if (deltaPct < -0.02) direction = 'down';

  const recent = sorted.slice(-3);
  const recentWeights = recent.map((m) => m.weight);
  const recentTrend = recentWeights.length >= 2
    ? recentWeights[recentWeights.length - 1] - recentWeights[0]
    : 0;

  return {
    quality,
    series: {
      count: sorted.length,
      first_weight: first,
      last_weight: last,
      delta_kg: delta,
      delta_pct: deltaPct,
      direction,
      recent_trend_kg: recentTrend,
      measurement_sources: [...new Set(sorted.map((m) => m.measurement_source || 'guardian'))],
    },
  };
}
