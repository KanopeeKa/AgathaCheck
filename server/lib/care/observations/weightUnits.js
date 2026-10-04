export const KG_PER_LB = 0.45359237;

/**
 * @param {unknown} raw
 * @returns {number|null}
 */
function parseNumericWeight(raw) {
  if (raw === undefined || raw === null || raw === '') {
    return null;
  }
  if (typeof raw === 'number') {
    return Number.isFinite(raw) ? raw : null;
  }
  const normalized = String(raw).trim().replace(',', '.');
  const value = parseFloat(normalized);
  return Number.isFinite(value) ? value : null;
}

/**
 * @param {{ weight: unknown, unit?: unknown }} input
 * @returns {{ kg: number } | { error: string }}
 */
export function parseWeightInput({ weight, unit }) {
  const weightVal = parseNumericWeight(weight);
  if (weightVal === null) {
    return { error: 'weight is required' };
  }
  if (weightVal <= 0) {
    return { error: 'weight must be positive' };
  }

  let unitNorm = 'kg';
  if (unit !== undefined && unit !== null && String(unit).trim() !== '') {
    unitNorm = String(unit).trim().toLowerCase();
  }

  if (unitNorm === 'kg') {
    return { kg: weightVal };
  }
  if (unitNorm === 'lb' || unitNorm === 'lbs') {
    return { kg: weightVal * KG_PER_LB };
  }
  return { error: 'unit must be kg or lb' };
}
