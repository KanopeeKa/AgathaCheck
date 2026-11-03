'use strict';

class ExecutePlanError extends Error {
  constructor(message, code = 'execute_plan_error') {
    super(message);
    this.name = 'ExecutePlanError';
    this.code = code;
  }
}

const ALLOWED_EXCEPTIONS = new Set([
  'tests',
  'docs',
  'file-split',
  'governance-allowlist',
  'spawn-integration',
]);

const PHASE_STATUS = new Set([
  'pending',
  'in_progress',
  'merged',
  'halted',
  'blocked',
]);

const STATUS_REASON = new Set([
  'expired',
  'revoked',
  'session_limit',
  'human_pause',
  'governance_approval_required',
  'model_selection_approval_required',
  'drift',
  'ci_exhausted',
  'merge_failed',
  'escalation',
  'issue_create_failed',
  'resume_mismatch',
  'uat_paused',
]);

const MERGE_MODES = new Set(['auto']);
const AUTONOMY = new Set(['active', 'completed', 'halted', 'revoked']);
const ARTIFACT_POLICY = new Set(['phase-branch', 'main']);

// Execute-plan v2 (contracts §3.1): hard caps in code, defaults for new plans. Generous on purpose:
// they only stop a run that loops or makes no progress, never ordinary day-to-day work.
const V2_CAPS = {
  window_days: 14,
  ci_per_phase: 15,
  launches_per_phase: 25,
  remedial_rounds: 10,
  sync_attempts: 8,
  daily_launches: 150,
  phases: 8,
  companions: 12,
};
const V2_DEFAULTS = {
  window_days: 7,
  budgets: { ci_per_phase: 8, launches_per_phase: 15, remedial_rounds: 6, sync_attempts: 5, daily_launches: 80 },
};

/** Status comment retains this many launch rows; must cover daily_launches and per-phase totals (contracts §3.1). */
const MAX_LAUNCH_HISTORY = Math.max(
  V2_CAPS.daily_launches,
  V2_CAPS.launches_per_phase * V2_CAPS.phases,
);

module.exports = {
  V2_CAPS,
  V2_DEFAULTS,
  MAX_LAUNCH_HISTORY,
  ALLOWED_EXCEPTIONS,
  ARTIFACT_POLICY,
  AUTONOMY,
  ExecutePlanError,
  MERGE_MODES,
  PHASE_STATUS,
  STATUS_REASON,
};
