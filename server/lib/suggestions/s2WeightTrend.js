import {
  SUGGESTION_TYPE_WEIGHT_TREND,
  WEIGHT_TREND_MIN_ENTRIES,
  WEIGHT_TREND_THRESHOLD_PCT,
  WEIGHT_TREND_WINDOW_DAYS,
} from './suggestionConstants.js';

export function buildS2DedupeKey(petId) {
  return `weight_trend:${petId}:${WEIGHT_TREND_WINDOW_DAYS}d`;
}

function pctChange(from, to) {
  if (!from || !to) return 0;
  const base = Number(from);
  const latest = Number(to);
  if (!Number.isFinite(base) || base <= 0) return 0;
  return ((latest - base) / base) * 100;
}

function monthLabel(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleString('en-US', { month: 'long' });
}

/**
 * @param {object} pet
 * @param {object[]} weightEntries — ordered newest first
 * @returns {null | { dedupeKey, title, message, confidence, payload }}
 */
export function evaluateS2WeightTrend(pet, weightEntries, now = new Date()) {
  if (pet.passed_away) return null;
  if (!weightEntries || weightEntries.length < WEIGHT_TREND_MIN_ENTRIES) return null;

  const windowStart = new Date(now);
  windowStart.setUTCDate(windowStart.getUTCDate() - WEIGHT_TREND_WINDOW_DAYS);

  const inWindow = weightEntries.filter((row) => {
    const d = new Date(row.date || row.created_at);
    return d >= windowStart;
  });
  if (inWindow.length < WEIGHT_TREND_MIN_ENTRIES) return null;

  const latest = inWindow[0];
  const oldest = inWindow[inWindow.length - 1];
  const change = pctChange(oldest.weight, latest.weight);
  if (Math.abs(change) < WEIGHT_TREND_THRESHOLD_PCT) return null;

  const petName = pet.name || 'your pet';
  const direction = change > 0 ? 'up' : 'down';
  const rounded = Math.round(Math.abs(change));
  const since = monthLabel(oldest.date);
  const title = `${petName}: weight ${direction} ${rounded}%`;
  const message = `Based on ${inWindow.length} weight entries since ${since || 'earlier this year'}.`;

  return {
    wireType: SUGGESTION_TYPE_WEIGHT_TREND,
    dedupeKey: buildS2DedupeKey(pet.id),
    title,
    message,
    confidence: 0.88,
    payload: {
      health_adjacent: true,
      primary_action: 'open_weight_chart',
      evidence: {
        entry_count: inWindow.length,
        window_days: WEIGHT_TREND_WINDOW_DAYS,
        pct_change: change,
        from_weight: oldest.weight,
        to_weight: latest.weight,
        from_date: oldest.date,
        to_date: latest.date,
      },
    },
  };
}
