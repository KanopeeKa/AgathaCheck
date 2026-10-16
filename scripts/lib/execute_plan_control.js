'use strict';

/**
 * Execute-plan v2 control derivation, lease and launch counting (pure; time comes from `now`).
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/state-machine.md §4.1.
 */

// L1
const RUNNING_SET = new Set(['CREATING', 'RUNNING']);
const LEASE_TTL_MS = 20 * 60 * 1000;

const ms = (iso) => Date.parse(iso);

/** @returns {{ epoch: string|null, deadline: string|null, stopped: boolean, reason: string|null }} */
function deriveControl(control, { now }) {
  const c = control || {};
  const auth = c.authorizing || null;
  const valid = Boolean(auth && auth.valid);
  const epoch = valid ? auth.created_at : null;
  const deadline = valid ? auth.until : null;
  const labels = c.labels || [];
  const status = c.status || null;
  const stop = status && status.stop ? status.stop : null;
  const stopCurrent = Boolean(stop && epoch && ms(stop.at) > ms(epoch)); // older stops are ignored

  let reason = null;
  if (!valid) reason = 'approval-invalid';
  else if (labels.includes('autonomous-revoked') || (c.revoke_comment_at && ms(c.revoke_comment_at) > ms(epoch))) {
    reason = 'revoked';
  } else if (labels.includes('needs-owner') && !stopCurrent) reason = 'escalation';
  else if (stopCurrent) reason = stop.reason;
  else if (ms(now) >= ms(deadline)) reason = 'expired';
  return { epoch, deadline, stopped: reason !== null, reason };
}

/** L2. `lease` is what the caller learned from Cursor (status UNKNOWN: only the time test applies). */
function leaseAlive(statusLease, lease, { now }) {
  if (!lease || !statusLease) return { alive: false };
  if (lease.status !== 'UNKNOWN' && !RUNNING_SET.has(lease.status)) return { alive: false };
  const last = statusLease.last_tick_at || statusLease.launched_at;
  if (!last) return { alive: false };
  return { alive: ms(now) - ms(last) < LEASE_TTL_MS };
}

/** @returns {{ phase: Record<string, number>, today: number }} */
function launchCounts(statusLaunches, { epoch, now }) {
  const phase = {};
  let today = 0;
  const day = String(now).slice(0, 10);
  for (const l of statusLaunches || []) {
    if (String(l.at).slice(0, 10) === day) today += 1; // daily cap spans resumes
    if (epoch && ms(l.at) <= ms(epoch)) continue;
    phase[l.phase] = (phase[l.phase] || 0) + 1;
  }
  return { phase, today };
}

module.exports = { RUNNING_SET, deriveControl, leaseAlive, launchCounts };
