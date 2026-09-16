import {
  CERTAINTY_COMPLETE,
  CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
} from '../schedule/projectSchedule.js';

const CERTAINTY_RANK = {
  [CERTAINTY_COMPLETE]: 0,
  [CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION]: 1,
};

/**
 * Pick the least-certain value among constituents (D-AWAY-006).
 *
 * @param {string[]} certainties
 * @returns {string}
 */
export function leastCertain(certainties) {
  if (!certainties.length) {
    return CERTAINTY_COMPLETE;
  }

  return certainties.reduce((least, certainty) => {
    const rank = CERTAINTY_RANK[certainty] ?? CERTAINTY_RANK[CERTAINTY_COMPLETE];
    const leastRank = CERTAINTY_RANK[least] ?? CERTAINTY_RANK[CERTAINTY_COMPLETE];
    return rank > leastRank ? certainty : least;
  }, CERTAINTY_COMPLETE);
}
