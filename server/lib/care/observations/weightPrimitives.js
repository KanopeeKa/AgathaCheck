/**
 * Domain-neutral weight observation primitives (care_observations).
 * No CIM or progression decision thresholds.
 */

const MS_PER_DAY = 24 * 60 * 60 * 1000;

export function parseDateMs(dateStr) {
  return Date.parse(`${dateStr}T00:00:00Z`);
}

export function daysBetween(startDate, endDate) {
  return Math.round((parseDateMs(endDate) - parseDateMs(startDate)) / MS_PER_DAY);
}

export function median(values) {
  if (!values.length) return 0;
  const sorted = [...values].sort((x, y) => x - y);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid];
}

export function stdDev(values, mean) {
  if (values.length < 2) return 0;
  const variance = values.reduce((sum, v) => sum + (v - mean) ** 2, 0) / values.length;
  return Math.sqrt(variance);
}

/**
 * @param {string | null | undefined} dateStr
 */
export function isValidWeightTimestamp(dateStr) {
  if (!dateStr || typeof dateStr !== 'string') return false;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
  const ms = parseDateMs(dateStr);
  return Number.isFinite(ms);
}

/**
 * @param {{ date?: string, weight?: number, unit?: string }} measurement
 */
export function isValidWeightMeasurementShape(measurement) {
  if (!measurement || typeof measurement !== 'object') return false;
  if (!isValidWeightTimestamp(measurement.date)) return false;
  if (typeof measurement.weight !== 'number' || !Number.isFinite(measurement.weight)) return false;
  if (measurement.weight <= 0) return false;
  if (measurement.unit != null && typeof measurement.unit !== 'string') return false;
  return true;
}

/**
 * @param {{ unit?: string }[]} measurements
 */
export function getWeightUnits(measurements) {
  return new Set(
    (measurements || []).map((m) => (m.unit || 'kg').toLowerCase()),
  );
}

/**
 * @param {{ unit?: string }[]} measurements
 */
export function hasConsistentWeightUnits(measurements) {
  return getWeightUnits(measurements).size <= 1;
}

/**
 * Keeps the last measurement per calendar date (deterministic duplicate handling).
 * @param {{ date: string, weight: number, unit?: string }[]} measurements
 */
export function dedupeWeightMeasurementsByDate(measurements) {
  const byDate = new Map();
  for (const measurement of measurements || []) {
    if (!isValidWeightMeasurementShape(measurement)) continue;
    byDate.set(measurement.date, measurement);
  }
  return [...byDate.values()].sort((a, b) => parseDateMs(a.date) - parseDateMs(b.date));
}

/**
 * @param {{ date: string, weight: number, unit?: string }[]} measurements
 */
export function prepareWeightMeasurements(measurements) {
  const valid = (measurements || []).filter(isValidWeightMeasurementShape);
  return dedupeWeightMeasurementsByDate(valid);
}
