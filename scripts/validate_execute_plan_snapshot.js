#!/usr/bin/env node
/**
 * Validate execute-plan snapshot JSON and optional drift-classification tests.
 *
 * Usage:
 *   node scripts/validate_execute_plan_snapshot.js <path-to-snapshot.json>
 *   node scripts/validate_execute_plan_snapshot.js --fix-hash <path>
 *   node scripts/validate_execute_plan_snapshot.js --drift-test
 *
 * Exit codes:
 *   0  valid (or drift tests pass)
 *   1  validation or drift test failure
 */

'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const SCHEMA_PATH = path.join(
  REPO_ROOT,
  'docs/agent-efficiency/execute-plan-snapshot.schema.json'
);

const ALLOWED_EXCEPTIONS = new Set([
  'tests',
  'docs',
  'dual-backend-mirror',
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
]);

const MERGE_MODES = new Set(['manual', 'labeled', 'auto']);
const AUTONOMY = new Set(['active', 'completed', 'halted', 'revoked']);
const ARTIFACT_POLICY = new Set(['phase-branch', 'main']);

function fail(msg) {
  console.error(`validate_execute_plan_snapshot: ${msg}`);
  process.exit(1);
}

function isIsoDate(s) {
  return typeof s === 'string' && !Number.isNaN(Date.parse(s));
}

function canonicalizeForHash(obj) {
  const copy = JSON.parse(JSON.stringify(obj));
  copy.content_hash = 'sha256:0000000000000000000000000000000000000000000000000000000000000000';
  return JSON.stringify(copy);
}

function computeHash(obj) {
  const digest = crypto
    .createHash('sha256')
    .update(canonicalizeForHash(obj))
    .digest('hex');
  return `sha256:${digest}`;
}

function globToRegExp(glob) {
  let s = glob.replace(/[.+^${}()|[\]\\]/g, '\\$&');
  s = s.replace(/\*\*/g, '\0GLOBSTAR\0');
  s = s.replace(/\*/g, '[^/]*');
  s = s.replace(/\0GLOBSTAR\0/g, '.*');
  return new RegExp(`^${s}$`);
}

function matchesAnyGlob(filePath, globs) {
  return globs.some((g) => globToRegExp(g).test(filePath));
}

function classifyFile(filePath, phase) {
  if (matchesAnyGlob(filePath, phase.allowed_paths)) {
    return { ok: true, reason: 'allowed_path' };
  }
  if (matchesAnyGlob(filePath, phase.forbidden_paths)) {
    return { ok: false, reason: 'forbidden' };
  }
  return { ok: false, reason: 'unclassified' };
}

function classifyWithException(filePath, phase, exceptionCode) {
  if (!ALLOWED_EXCEPTIONS.has(exceptionCode)) {
    return { ok: false, reason: 'invalid_exception_code' };
  }
  if (!phase.allowed_exceptions.includes(exceptionCode)) {
    return { ok: false, reason: 'exception_not_in_phase' };
  }
  const base = classifyFile(filePath, phase);
  if (base.ok) {
    return { ok: true, reason: 'allowed_path' };
  }
  if (base.reason === 'forbidden') {
    return { ok: false, reason: 'forbidden' };
  }
  return { ok: true, reason: `exception:${exceptionCode}` };
}

function validatePhase(phase, index) {
  const p = `phases[${index}]`;
  for (const key of [
    'id',
    'title',
    'branch',
    'allowed_paths',
    'forbidden_paths',
    'allowed_exceptions',
    'spawn_allowed',
    'exit_checklist',
    'status',
  ]) {
    if (!(key in phase)) fail(`${p} missing required field "${key}"`);
  }
  if (!PHASE_STATUS.has(phase.status)) {
    fail(`${p}.status invalid: ${phase.status}`);
  }
  const needsReason = phase.status === 'halted' || phase.status === 'blocked';
  if (needsReason) {
    if (!phase.status_reason || !STATUS_REASON.has(phase.status_reason)) {
      fail(`${p}.status_reason required for status=${phase.status}`);
    }
  } else if (phase.status_reason != null) {
    fail(`${p}.status_reason must be null when status=${phase.status}`);
  }
  if (!Array.isArray(phase.allowed_paths) || phase.allowed_paths.length === 0) {
    fail(`${p}.allowed_paths must be non-empty array`);
  }
  for (const ex of phase.allowed_exceptions) {
    if (!ALLOWED_EXCEPTIONS.has(ex)) fail(`${p}.allowed_exceptions invalid code: ${ex}`);
  }
  if (phase.spawn_allowed && !phase.spawn_config) {
    fail(`${p}.spawn_config required when spawn_allowed is true`);
  }
  if (!phase.spawn_allowed && phase.spawn_config != null) {
    fail(`${p}.spawn_config must be null when spawn_allowed is false`);
  }
  if (phase.merge_mode && !MERGE_MODES.has(phase.merge_mode)) {
    fail(`${p}.merge_mode invalid`);
  }
}

function validateSnapshot(obj, { checkHash }) {
  if (obj.schema_version !== 1) fail('schema_version must be 1');
  if (!obj.plan_id || typeof obj.plan_id !== 'string') fail('plan_id required');
  if (!isIsoDate(obj.approved_at)) fail('approved_at must be ISO-8601');
  if (!isIsoDate(obj.approved_until)) fail('approved_until must be ISO-8601');
  const approvedAt = new Date(obj.approved_at);
  const approvedUntil = new Date(obj.approved_until);
  if (approvedUntil <= approvedAt) {
    fail('approved_until must be after approved_at');
  }
  const maxMs = 48 * 60 * 60 * 1000;
  if (approvedUntil - approvedAt > maxMs) {
    console.warn(
      'validate_execute_plan_snapshot: warning: approved_until is more than 48h after approved_at'
    );
  }
  if (!obj.approved_by) fail('approved_by required');
  if (!AUTONOMY.has(obj.autonomy)) fail('autonomy invalid');
  if (!MERGE_MODES.has(obj.default_merge_mode)) fail('default_merge_mode invalid');
  if (!obj.base_branch) fail('base_branch required');
  if (!Number.isInteger(obj.control_issue) || obj.control_issue < 1) {
    fail('control_issue must be positive integer');
  }
  if (!ARTIFACT_POLICY.has(obj.artifact_branch_policy)) {
    fail('artifact_branch_policy invalid');
  }
  if (!Array.isArray(obj.phases) || obj.phases.length === 0) {
    fail('phases must be non-empty array');
  }
  if (
    !obj.content_hash ||
    !/^sha256:[a-f0-9]{64}$/.test(obj.content_hash)
  ) {
    fail('content_hash must match sha256:<hex>');
  }
  obj.phases.forEach((phase, i) => validatePhase(phase, i));

  if (checkHash) {
    const expected = computeHash(obj);
    if (obj.content_hash !== expected) {
      fail(`content_hash mismatch: expected ${expected}, got ${obj.content_hash}`);
    }
  }
}

function runDriftTests() {
  const phase = {
    allowed_paths: ['flutter_app/lib/features/foster/**'],
    forbidden_paths: ['server/**', '.github/workflows/**'],
    allowed_exceptions: ['tests', 'docs', 'file-split'],
  };

  const cases = [
    {
      file: 'flutter_app/lib/features/foster/presentation/foster_card.dart',
      exception: null,
      expectOk: true,
    },
    {
      file: 'server/routes/pets/index.js',
      exception: null,
      expectOk: false,
      reason: 'forbidden',
    },
    {
      file: 'flutter_app/test/features/foster/foster_card_test.dart',
      exception: 'tests',
      expectOk: true,
    },
    {
      file: 'flutter_app/test/features/foster/foster_card_test.dart',
      exception: null,
      expectOk: false,
      reason: 'unclassified',
    },
    {
      file: 'docs/architecture/index.md',
      exception: 'docs',
      expectOk: true,
    },
  ];

  for (const c of cases) {
    const result = c.exception
      ? classifyWithException(c.file, phase, c.exception)
      : classifyFile(c.file, phase);
    if (result.ok !== c.expectOk) {
      fail(
        `drift test failed for ${c.file}: expected ok=${c.expectOk}, got ${JSON.stringify(result)}`
      );
    }
    if (!c.expectOk && c.reason && result.reason !== c.reason) {
      fail(
        `drift test reason mismatch for ${c.file}: expected ${c.reason}, got ${result.reason}`
      );
    }
  }
  console.log('validate_execute_plan_snapshot: drift tests passed');
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes('--drift-test')) {
    runDriftTests();
    process.exit(0);
  }

  const fixHash = args.includes('--fix-hash');
  const fileArg = args.find((a) => !a.startsWith('--'));
  if (!fileArg) {
    console.error(
      'Usage: node scripts/validate_execute_plan_snapshot.js <snapshot.json> [--fix-hash]'
    );
    console.error('       node scripts/validate_execute_plan_snapshot.js --drift-test');
    process.exit(1);
  }

  const filePath = path.resolve(fileArg);
  if (!fs.existsSync(filePath)) fail(`file not found: ${filePath}`);

  const raw = fs.readFileSync(filePath, 'utf8');
  let obj;
  try {
    obj = JSON.parse(raw);
  } catch (e) {
    fail(`invalid JSON: ${e.message}`);
  }

  if (fixHash) {
  obj.content_hash = computeHash(obj);
  const nextContent = `${JSON.stringify(obj, null, 2)}\n`;

  const fd = fs.openSync(filePath, "r+");
  try {
    fs.ftruncateSync(fd, 0);
    fs.writeFileSync(fd, nextContent, "utf8");
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }

  console.log(`validate_execute_plan_snapshot: updated content_hash in ${filePath}`);
}

  validateSnapshot(obj, { checkHash: !fixHash });

  if (!fs.existsSync(SCHEMA_PATH)) {
    console.warn('validate_execute_plan_snapshot: schema file missing (skipped)');
  }

  console.log(`validate_execute_plan_snapshot: OK ${path.relative(REPO_ROOT, filePath)}`);
}

main();
