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

/** `cursor/*-integration-*` — protected, non-fast-forward, not rebased onto main. */
function isIntegrationHead(headRefName) {
  return typeof headRefName === 'string' && /^cursor\/.+-integration-/.test(headRefName);
}

/**
 * @param {{
 *   prNumber: number,
 *   behindBase?: boolean,
 *   headRefName?: string,
 *   mergeable?: string,
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
    headRefName = '',
    mergeable = '',
    leaseHolder = null,
    competingGreenPrs = [],
    baseHot = false,
    hasDoNotMerge = false,
    force = false,
    leaseStale = false,
  } = input;
  const integrationHead = isIntegrationHead(headRefName);

  if (hasDoNotMerge) {
    return {
      allowed: false,
      exitCode: 3,
      reason: 'do_not_merge',
      action: 'halt',
    };
  }

  // A clean integration → main release merges while behind. Catching the
  // integration branch up to main races every other open programme.
  if (integrationHead && mergeable === 'CONFLICTING') {
    return {
      allowed: false,
      exitCode: 4,
      reason: 'integration_conflict',
      action: 'resolve_on_release',
    };
  }

  if (behindBase && !(integrationHead && mergeable === 'MERGEABLE')) {
    if (integrationHead) {
      return {
        allowed: false,
        exitCode: 1,
        reason: 'integration_mergeability_unknown',
        action: 'recheck_mergeable',
      };
    }
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

/**
 * Numeric PR from a number or a GitHub pull/issue URL. Null when the caller
 * must resolve the ref (for example a head branch name) another way.
 * @param {string|number|null|undefined} ref
 * @returns {string|null}
 */
function parsePrNumber(ref) {
  const text = String(ref ?? '').trim();
  if (/^\d+$/.test(text)) {
    return text;
  }
  const match = text.match(/\/(?:pull|issues)\/(\d+)(?:[/?#]|$)/i);
  return match ? match[1] : null;
}

/**
 * `gh` argv that adds or removes `merge-lease` through the REST issue-labels
 * API. `gh pr edit --add-label` fetches org team login/name/slug and Projects
 * fields first; a `repo`-only token fails that GraphQL call, and the script
 * would exit 3 (halt) on a clear preflight.
 * @param {string|number} prNumber
 * @param {'add'|'remove'} action
 * @returns {string[]}
 */
function leaseLabelApiArgs(prNumber, action) {
  const number = String(prNumber);
  if (!/^\d+$/.test(number)) {
    throw new Error(`lease label requires a numeric PR, got ${number}`);
  }
  if (action === 'add') {
    return [
      'api',
      '--method',
      'POST',
      `repos/{owner}/{repo}/issues/${number}/labels`,
      '-f',
      `labels[]=${MERGE_LEASE_LABEL}`,
    ];
  }
  if (action === 'remove') {
    return [
      'api',
      '--method',
      'DELETE',
      `repos/{owner}/{repo}/issues/${number}/labels/${encodeURIComponent(MERGE_LEASE_LABEL)}`,
    ];
  }
  throw new Error(`unknown lease label action: ${action}`);
}

/**
 * DELETE of a label that is not on the issue. A missing issue is a different
 * 404 and must still fail the release.
 * @param {string|null|undefined} stderr
 * @param {string|null|undefined} stdout
 */
function isLabelAlreadyAbsent(stderr, stdout) {
  return /Label does not exist/i.test(`${stderr || ''}\n${stdout || ''}`);
}

module.exports = {
  DEFAULT_BASE_HOT_MINUTES,
  DEFAULT_LEASE_STALE_MINUTES,
  MERGE_LEASE_LABEL,
  evaluateMergePreflight,
  isIntegrationHead,
  findCompetingGreenPrs,
  findLeaseHolder,
  isBaseHot,
  isLeaseStale,
  isPrCiGreen,
  parsePrNumber,
  leaseLabelApiArgs,
  isLabelAlreadyAbsent,
};
