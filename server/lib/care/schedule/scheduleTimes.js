/**
 * Times of day for a care series — pure helpers shared by schedule rules.
 */

/**
 * @param {string|null|undefined} value
 * @returns {string|null} HH:MM
 */
export function normalizeTime(value) {
  if (value == null || value === '') return null;
  const s = String(value).trim();
  const m = /^(\d{1,2}):(\d{2})(?::\d{2})?$/.exec(s);
  if (!m) return null;
  const hh = Number(m[1]);
  const mm = Number(m[2]);
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
  return `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}`;
}

/**
 * @param {object|null|undefined} row health_entries row or body
 * @returns {(string|null)[]} sorted wall-clock HH:MM, or [null] for any time of day
 */
export function scheduleTimesFromEntry(row) {
  const raw = row?.schedule_times ?? row?.scheduleTimes;
  let list = raw;
  if (typeof raw === 'string') {
    try {
      list = JSON.parse(raw);
    } catch {
      list = null;
    }
  }
  if (!Array.isArray(list) || list.length === 0) return [null];
  const times = list.map((t) => normalizeTime(t)).filter((t) => t != null);
  if (times.length === 0) return [null];
  return [...new Set(times)].sort();
}
