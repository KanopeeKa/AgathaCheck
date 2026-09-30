/**
 * Pure calendar arithmetic for care series (D-CSM-023, D-CSM-024).
 *
 * Dates are calendar days (`YYYY-MM-DD`). Month and year steps clamp to the
 * last day of the target month and are always counted from the anchor, never
 * chained from a clamped date: 31 Jan → 28/29 Feb → 31 Mar.
 */

/**
 * @param {string} iso YYYY-MM-DD
 * @returns {{ y: number, m: number, d: number }}
 */
function parts(iso) {
  const [y, m, d] = String(iso).slice(0, 10).split('-').map(Number);
  return { y, m, d };
}

/**
 * @param {number} y
 * @param {number} m 1-12
 * @param {number} d
 * @returns {string}
 */
function toIso(y, m, d) {
  return `${String(y).padStart(4, '0')}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

/**
 * @param {number} y
 * @param {number} m 1-12
 * @returns {number}
 */
export function daysInMonth(y, m) {
  return new Date(Date.UTC(y, m, 0)).getUTCDate();
}

/**
 * @param {string} iso
 * @returns {number} UTC epoch day
 */
function epochDay(iso) {
  const { y, m, d } = parts(iso);
  return Math.floor(Date.UTC(y, m - 1, d) / 86_400_000);
}

/**
 * @param {number} day epoch day
 * @returns {string}
 */
function fromEpochDay(day) {
  const dt = new Date(day * 86_400_000);
  return toIso(dt.getUTCFullYear(), dt.getUTCMonth() + 1, dt.getUTCDate());
}

/**
 * @param {string} iso
 * @param {number} days
 * @returns {string}
 */
export function addDaysIso(iso, days) {
  return fromEpochDay(epochDay(iso) + days);
}

/**
 * Signed whole days from `fromIso` to `toIso`.
 *
 * @param {string} fromIso
 * @param {string} toIso
 * @returns {number}
 */
export function daysBetween(fromIso, toIso) {
  return epochDay(toIso) - epochDay(fromIso);
}

/**
 * Add months to a date, clamping to the month's last day (D-CSM-024).
 *
 * @param {string} iso
 * @param {number} months
 * @returns {string}
 */
export function addMonthsClamped(iso, months) {
  const { y, m, d } = parts(iso);
  const zeroBased = (m - 1) + months;
  const ty = y + Math.floor(zeroBased / 12);
  const tm = ((zeroBased % 12) + 12) % 12 + 1;
  return toIso(ty, tm, Math.min(d, daysInMonth(ty, tm)));
}

/**
 * Series step for an entry: `{ unit: 'day' | 'month', count }`, or null for once.
 *
 * @param {object} entry health_entries row (frequency, frequency_interval, frequency_days)
 * @returns {{ unit: 'day'|'month', count: number }|null}
 */
export function seriesStep(entry) {
  const freq = entry?.frequency || 'once';
  const interval = Math.max(1, Number(entry?.frequency_interval ?? 1) || 1);
  switch (freq) {
    case 'once':
      return null;
    case 'daily':
      return { unit: 'day', count: interval };
    case 'weekly':
      return { unit: 'day', count: 7 * interval };
    case 'monthly':
      return { unit: 'month', count: interval };
    case 'yearly':
      return { unit: 'month', count: 12 * interval };
    case 'custom': {
      const days = Math.max(1, Number(entry?.frequency_days || interval) || interval);
      return { unit: 'day', count: days };
    }
    default:
      return { unit: 'day', count: interval };
  }
}

/**
 * `n` steps from `baseIso` (n may be 0). Month steps clamp from the base day.
 *
 * @param {string} baseIso
 * @param {object} entry
 * @param {number} [n]
 * @returns {string}
 */
export function addSteps(baseIso, entry, n = 1) {
  const step = seriesStep(entry) || { unit: 'day', count: 1 };
  if (step.unit === 'month') return addMonthsClamped(baseIso, step.count * n);
  return addDaysIso(baseIso, step.count * n);
}

/**
 * Nominal interval length in days (for "half an interval" rules).
 *
 * @param {object} entry
 * @param {string} [fromIso] reference date for month-based steps
 * @returns {number}
 */
export function nominalIntervalDays(entry, fromIso = '2001-01-01') {
  const step = seriesStep(entry);
  if (!step) return 0;
  if (step.unit === 'day') return step.count;
  return Math.max(1, daysBetween(fromIso, addMonthsClamped(fromIso, step.count)));
}

/**
 * Smallest n ≥ 0 with seriesDate(n) ≥ targetIso.
 *
 * @param {string} anchorIso
 * @param {object} entry
 * @param {string} targetIso
 * @returns {number}
 */
function firstIndexOnOrAfter(anchorIso, entry, targetIso) {
  if (targetIso <= anchorIso) return 0;
  const step = seriesStep(entry);
  if (!step) return 0;
  let n;
  if (step.unit === 'day') {
    n = Math.ceil(daysBetween(anchorIso, targetIso) / step.count);
  } else {
    const a = parts(anchorIso);
    const t = parts(targetIso);
    const monthGap = (t.y - a.y) * 12 + (t.m - a.m);
    n = Math.max(0, Math.floor(monthGap / step.count) - 1);
  }
  while (n > 0 && addSteps(anchorIso, entry, n - 1) >= targetIso) n -= 1;
  while (addSteps(anchorIso, entry, n) < targetIso) n += 1;
  return n;
}

/**
 * First series date on or after `targetIso`.
 *
 * @param {string} anchorIso
 * @param {object} entry
 * @param {string} targetIso
 * @returns {string}
 */
export function seriesDateOnOrAfter(anchorIso, entry, targetIso) {
  return addSteps(anchorIso, entry, firstIndexOnOrAfter(anchorIso, entry, targetIso));
}

/**
 * First series date strictly after `targetIso`.
 *
 * @param {string} anchorIso
 * @param {object} entry
 * @param {string} targetIso
 * @returns {string}
 */
export function seriesDateAfter(anchorIso, entry, targetIso) {
  return seriesDateOnOrAfter(anchorIso, entry, addDaysIso(targetIso, 1));
}

/**
 * Series dates within `[fromIso, toIso]` (inclusive), never before the anchor.
 *
 * @param {string} anchorIso
 * @param {object} entry
 * @param {string} fromIso
 * @param {string} toIso
 * @param {number} [limit]
 * @returns {string[]}
 */
export function seriesDatesBetween(anchorIso, entry, fromIso, toIso, limit = 400) {
  if (!seriesStep(entry)) {
    return anchorIso >= fromIso && anchorIso <= toIso ? [anchorIso] : [];
  }
  const out = [];
  let n = firstIndexOnOrAfter(anchorIso, entry, fromIso);
  let date = addSteps(anchorIso, entry, n);
  while (date <= toIso && out.length < limit) {
    out.push(date);
    n += 1;
    date = addSteps(anchorIso, entry, n);
  }
  return out;
}

/**
 * Whether `dateIso` is a date of the series anchored at `anchorIso`.
 *
 * @param {string} anchorIso
 * @param {object} entry
 * @param {string} dateIso
 * @returns {boolean}
 */
export function isSeriesDate(anchorIso, entry, dateIso) {
  if (dateIso < anchorIso) return false;
  return seriesDateOnOrAfter(anchorIso, entry, dateIso) === dateIso;
}

/**
 * Latest series date on or before `targetIso`, or null when the series starts later.
 *
 * @param {string} anchorIso
 * @param {object} entry
 * @param {string} targetIso
 * @returns {string|null}
 */
export function seriesDateOnOrBefore(anchorIso, entry, targetIso) {
  if (targetIso < anchorIso) return null;
  const next = firstIndexOnOrAfter(anchorIso, entry, addDaysIso(targetIso, 1));
  return next === 0 ? null : addSteps(anchorIso, entry, next - 1);
}
