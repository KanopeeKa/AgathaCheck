'use strict';

/** Marker wrapping canonical JSON ledger on the coordination issue. */
const STATE_MARKER = '<!-- uat-queue-state:v1 -->';

/** Entry states (see docs/agent-efficiency/uat-coordinator-plan.md). */
const ENTRY_STATES = new Set([
  'pending',
  'deploying',
  'complete',
  'failed',
  'infra_failed',
  'remedial',
  'frozen',
  'superseded',
]);

/**
 * GitHub issue number for `[uat-coordinator] UAT deploy queue`.
 * Override with UAT_COORDINATION_ISSUE env; 0 = not bootstrapped (CLI still works with --issue).
 */
const COORDINATION_ISSUE_NUMBER = Number(process.env.UAT_COORDINATION_ISSUE || '0');

/** Default watcher lease (minutes) for acquire-watcher. */
const DEFAULT_WATCHER_LEASE_MINUTES = 90;

module.exports = {
  COORDINATION_ISSUE_NUMBER,
  DEFAULT_WATCHER_LEASE_MINUTES,
  ENTRY_STATES,
  STATE_MARKER,
};
