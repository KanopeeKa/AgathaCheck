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
  'revoked',
  'session_limit',
  'human_pause',
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

module.exports = {
  ALLOWED_EXCEPTIONS,
  ARTIFACT_POLICY,
  AUTONOMY,
  ExecutePlanError,
  MERGE_MODES,
  PHASE_STATUS,
  STATUS_REASON,
};
