/**
 * Pure merge-coordination logic for babysit_merge_preflight.
 * @module scripts/lib/babysit_merge_preflight_lib
 */

/** @type {string} */
const MERGE_LEASE_LABEL = 'merge-lease';

/** @type {number} */
const DEFAULT_BASE_HOT_MINUTES = 10;

/** @type {number} */
const DEFAULT_LEASE_STALE_MINUTES = 45;

/**
 * @param {string|null|undefined} iso
 * @param {number} nowMs
 * @param {number} [hotMinutes]
 */
function isBaseHot(iso, nowMs, hotMinutes = DEFAULT_BASE_HOT_MINUTES) {
  if (!iso) {
    return false;
  }
  const pushedMs = Date.parse(iso);
  if (Number.isNaN(pushedMs)) {
    return false;
  }
  return nowMs - pushedMs < hotMinutes * 60 * 1000;
}

/**
 * @param {{ state?: string }[]|null|undefined} statusCheckRollup
 */
function isPrCiGreen(statusCheckRollup) {
  if (!Array.isArray(statusCheckRollup) || statusCheckRollup.length === 0) {
    return false;
  }
  return statusCheckRollup.every((check) =>
    ['SUCCESS', 'SKIPPED', 'NEUTRAL'].includes(String(check.state || '')),
  );
}

/**
 * @param {object[]} openPrs
 * @param {string} [leaseLabel]
 */
function findLeaseHolder(openPrs, leaseLabel = MERGE_LEASE_LABEL) {
  if (!Array.isArray(openPrs)) {
    return null;
  }
  return (
    openPrs.find((pr) =>
      (pr.labels || []).some((label) => label.name === leaseLabel),
    ) || null
  );
}

/**
 * @param {object[]} openPrs
 * @param {{ prNumber: number }} options
 */
function findCompetingGreenPrs(openPrs, { prNumber }) {
  if (!Array.isArray(openPrs)) {
    return [];
  }
  return openPrs.filter(
    (pr) =>
      pr.number !== prNumber &&
      pr.mergeable === 'MERGEABLE' &&
      isPrCiGreen(pr.statusCheckRollup),
  );
}

/**
 * @param {Date|string|number|null|undefined} isoOrMs
 * @param {number} nowMs
 * @param {number} [staleMinutes]
 */
function isLeaseStale(isoOrMs, nowMs, staleMinutes = DEFAULT_LEASE_STALE_MINUTES) {
  if (!isoOrMs) {
    return true;
  }
  const ms =
    typeof isoOrMs === 'number'
      ? isoOrMs
      : isoOrMs instanceof Date
        ? isoOrMs.getTime()
        : Date.parse(String(isoOrMs));
  if (Number.isNaN(ms)) {
    return true;
  }
  return nowMs - ms >= staleMinutes * 60 * 1000;
}

/**
 * @param {{
 *   prNumber: number,
 *   behindBase?: boolean,
 *   leaseHolder?: object|null,
 *   competingGreenPrs?: object[],
 *   baseHot?: boolean,
 *   hasDoNotMerge?: boolean,
 *   force?: boolean,
 *   nowMs?: number,
 *   leaseStale?: boolean,
 * }} input
 */
function evaluateMergePreflight(input) {
  const {
    prNumber,
    behindBase = false,
    leaseHolder = null,
    competingGreenPrs = [],
    baseHot = false,
    hasDoNotMerge = false,
    force = false,
    leaseStale = false,
  } = input;

  if (hasDoNotMerge) {
    return {
      allowed: false,
      exitCode: 3,
      reason: 'do_not_merge',
      action: 'halt',
    };
  }

  if (behindBase) {
    return {
      allowed: false,
      exitCode: 1,
      reason: 'behind_base',
      action: 'rebase',
    };
  }

  if (
    leaseHolder &&
    leaseHolder.number !== prNumber &&
    !(force && leaseStale)
  ) {
    return {
      allowed: false,
      exitCode: 2,
      reason: 'merge_lease_held',
      action: 'wait',
      lease_holder: {
        number: leaseHolder.number,
        url: leaseHolder.url,
        updatedAt: leaseHolder.updatedAt,
      },
    };
  }

  const lowerCompetitors = competingGreenPrs
    .filter((pr) => pr.number < prNumber)
    .sort((a, b) => a.number - b.number);

  if (!force && baseHot && lowerCompetitors.length > 0) {
    const yieldTo = lowerCompetitors[0];
    return {
      allowed: false,
      exitCode: 2,
      reason: 'fifo_yield',
      action: 'wait',
      yield_to: {
        number: yieldTo.number,
        url: yieldTo.url,
      },
    };
  }

  return {
    allowed: true,
    exitCode: 0,
    reason: 'clear',
    action: 'merge',
  };
}

module.exports = {
  DEFAULT_BASE_HOT_MINUTES,
  DEFAULT_LEASE_STALE_MINUTES,
  MERGE_LEASE_LABEL,
  evaluateMergePreflight,
  findCompetingGreenPrs,
  findLeaseHolder,
  isBaseHot,
  isLeaseStale,
  isPrCiGreen,
};
