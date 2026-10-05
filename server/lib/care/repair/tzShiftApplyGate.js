/**
 * DC-1 / DC-3: reset path uses truncate or UAT refresh — never repair_tz_shift --apply.
 */

const FORCE_ENV = 'TZ_SHIFT_REPAIR_FORCE_APPLY';

function resolveAppEnv() {
  return process.env.APP_ENV || process.env.NODE_ENV || 'development';
}

export function isTzShiftForceApply() {
  const v = process.env[FORCE_ENV];
  return v === '1' || v === 'true';
}

/**
 * @param {string} [appEnv]
 * @returns {string | null} refusal reason, or null when apply may proceed
 */
export function tzShiftApplyRefusalReason(appEnv = resolveAppEnv()) {
  if (isTzShiftForceApply()) return null;
  if (appEnv === 'uat') {
    return (
      'Refusing repair_tz_shift --apply on UAT (DC-1): reset demo data via ' +
      'Actions → UAT reset demo data; do not repair TZ-shift damage on UAT.'
    );
  }
  return null;
}

/**
 * @param {object[]} dryRunReports output of repairTzShift with apply: false
 * @returns {string | null}
 */
export function tzShiftApplyNoWorkRefusalReason(dryRunReports) {
  if (isTzShiftForceApply()) return null;
  const hasWork = dryRunReports.some(
    (r) => r.deleted?.length || r.reopened?.length || r.flagged?.length,
  );
  if (!hasWork) {
    return (
      'Refusing repair_tz_shift --apply: dry-run reports no TZ-shift repair work. ' +
      'After an empty or Oct 2026 production wipe (DC-1), use repair_occurrences.js ' +
      '--dry-run only — do not run --apply.'
    );
  }
  return null;
}

/**
 * @param {object[]} dryRunReports
 */
export function assertTzShiftApplyAllowed(dryRunReports) {
  const envReason = tzShiftApplyRefusalReason();
  if (envReason) {
    const err = new Error(envReason);
    err.code = 'tz_shift_apply_refused';
    throw err;
  }
  const workReason = tzShiftApplyNoWorkRefusalReason(dryRunReports);
  if (workReason) {
    const err = new Error(workReason);
    err.code = 'tz_shift_apply_no_work';
    throw err;
  }
}
