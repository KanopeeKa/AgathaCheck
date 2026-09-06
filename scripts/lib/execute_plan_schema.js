'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const {
  ALLOWED_EXCEPTIONS,
  ARTIFACT_POLICY,
  AUTONOMY,
  ExecutePlanError,
  MERGE_MODES,
  PHASE_STATUS,
  STATUS_REASON,
} = require('./execute_plan_constants');
const { isRoadmap, validateRoadmap } = require('./execute_plan_roadmap');

const REPO_ROOT = path.resolve(__dirname, '../..');
const PLANS_DIR = path.join(REPO_ROOT, '.agents/plans');

function isIsoDate(s) {
  return typeof s === 'string' && !Number.isNaN(Date.parse(s));
}

function canonicalizeForHash(obj) {
  const copy = JSON.parse(JSON.stringify(obj));
  copy.content_hash =
    'sha256:0000000000000000000000000000000000000000000000000000000000000000';
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
  if (base.ok) return { ok: true, reason: 'allowed_path' };
  if (base.reason === 'forbidden') return { ok: false, reason: 'forbidden' };
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
    if (!(key in phase)) throw new ExecutePlanError(`${p} missing required field "${key}"`);
  }
  if (!PHASE_STATUS.has(phase.status)) {
    throw new ExecutePlanError(`${p}.status invalid: ${phase.status}`);
  }
  const needsReason = phase.status === 'halted' || phase.status === 'blocked';
  if (needsReason) {
    if (!phase.status_reason || !STATUS_REASON.has(phase.status_reason)) {
      throw new ExecutePlanError(`${p}.status_reason required for status=${phase.status}`);
    }
  } else if (phase.status_reason != null) {
    throw new ExecutePlanError(`${p}.status_reason must be null when status=${phase.status}`);
  }
  if (!Array.isArray(phase.allowed_paths) || phase.allowed_paths.length === 0) {
    throw new ExecutePlanError(`${p}.allowed_paths must be non-empty array`);
  }
  for (const ex of phase.allowed_exceptions) {
    if (!ALLOWED_EXCEPTIONS.has(ex)) {
      throw new ExecutePlanError(`${p}.allowed_exceptions invalid code: ${ex}`);
    }
  }
  if (phase.spawn_allowed && !phase.spawn_config) {
    throw new ExecutePlanError(`${p}.spawn_config required when spawn_allowed is true`);
  }
  if (!phase.spawn_allowed && phase.spawn_config != null) {
    throw new ExecutePlanError(`${p}.spawn_config must be null when spawn_allowed is false`);
  }
  if (phase.merge_mode && !MERGE_MODES.has(phase.merge_mode)) {
    throw new ExecutePlanError(`${p}.merge_mode invalid`);
  }
}

function validateSnapshot(obj, { checkHash = true } = {}) {
  if (obj.schema_version !== 1) throw new ExecutePlanError('schema_version must be 1');
  if (!obj.plan_id || typeof obj.plan_id !== 'string') {
    throw new ExecutePlanError('plan_id required');
  }
  if (!isIsoDate(obj.approved_at)) throw new ExecutePlanError('approved_at must be ISO-8601');
  if (!isIsoDate(obj.approved_until)) {
    throw new ExecutePlanError('approved_until must be ISO-8601');
  }
  const approvedAt = new Date(obj.approved_at);
  const approvedUntil = new Date(obj.approved_until);
  if (approvedUntil <= approvedAt) {
    throw new ExecutePlanError('approved_until must be after approved_at');
  }
  if (!obj.approved_by) throw new ExecutePlanError('approved_by required');
  if (!AUTONOMY.has(obj.autonomy)) throw new ExecutePlanError('autonomy invalid');
  if (!MERGE_MODES.has(obj.default_merge_mode)) {
    throw new ExecutePlanError('default_merge_mode invalid');
  }
  if (!obj.base_branch) throw new ExecutePlanError('base_branch required');
  if (!Number.isInteger(obj.control_issue) || obj.control_issue < 1) {
    throw new ExecutePlanError('control_issue must be positive integer');
  }
  if (!ARTIFACT_POLICY.has(obj.artifact_branch_policy)) {
    throw new ExecutePlanError('artifact_branch_policy invalid');
  }
  if (!Array.isArray(obj.phases) || obj.phases.length === 0) {
    throw new ExecutePlanError('phases must be non-empty array');
  }
  if (!obj.content_hash || !/^sha256:[a-f0-9]{64}$/.test(obj.content_hash)) {
    throw new ExecutePlanError('content_hash must match sha256:<hex>');
  }
  obj.phases.forEach((phase, i) => validatePhase(phase, i));
  if (obj.plan_kind != null && obj.plan_kind !== 'roadmap') {
    throw new ExecutePlanError('plan_kind must be "roadmap" when set');
  }
  if (isRoadmap(obj)) {
    validateRoadmap(obj);
  }
  if (checkHash) {
    const expected = computeHash(obj);
    if (obj.content_hash !== expected) {
      throw new ExecutePlanError(
        `content_hash mismatch: expected ${expected}, got ${obj.content_hash}`
      );
    }
  }
}

function atomicWriteFile(filePath, content) {
  const dir = path.dirname(filePath);
  const tempPath = path.join(dir, `.execute_plan.${process.pid}.${Date.now()}.tmp`);
  try {
    fs.writeFileSync(tempPath, content, { mode: 0o600 });
    fs.renameSync(tempPath, filePath);
  } finally {
    try {
      fs.unlinkSync(tempPath);
    } catch (e) {
      if (!e || e.code !== 'ENOENT') throw e;
    }
  }
}

function planPaths(planId) {
  const base = path.join(PLANS_DIR, planId);
  return {
    planMd: `${base}.md`,
    snapshotJson: `${base}.snapshot.json`,
  };
}

function loadSnapshotFromPath(snapshotPath) {
  return JSON.parse(fs.readFileSync(snapshotPath, 'utf8'));
}

function loadSnapshot(planId) {
  const { snapshotJson } = planPaths(planId);
  if (!fs.existsSync(snapshotJson)) {
    throw new ExecutePlanError(`snapshot not found: ${snapshotJson}`);
  }
  const obj = loadSnapshotFromPath(snapshotJson);
  if (obj.plan_id !== planId) {
    throw new ExecutePlanError(
      `plan_id mismatch: file has ${obj.plan_id}, expected ${planId}`
    );
  }
  return obj;
}

function saveSnapshot(planId, obj) {
  const { snapshotJson } = planPaths(planId);
  obj.content_hash = computeHash(obj);
  validateSnapshot(obj, { checkHash: true });
  atomicWriteFile(snapshotJson, `${JSON.stringify(obj, null, 2)}\n`);
}

function getPhase(snapshot, phaseId) {
  const phase = snapshot.phases.find((p) => p.id === phaseId);
  if (!phase) throw new ExecutePlanError(`unknown phase id: ${phaseId}`);
  return phase;
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
      throw new ExecutePlanError(
        `drift test failed for ${c.file}: expected ok=${c.expectOk}, got ${JSON.stringify(result)}`
      );
    }
    if (!c.expectOk && c.reason && result.reason !== c.reason) {
      throw new ExecutePlanError(
        `drift test reason mismatch for ${c.file}: expected ${c.reason}, got ${result.reason}`
      );
    }
  }
}

module.exports = {
  REPO_ROOT,
  PLANS_DIR,
  atomicWriteFile,
  classifyFile,
  classifyWithException,
  computeHash,
  getPhase,
  loadSnapshot,
  loadSnapshotFromPath,
  planPaths,
  runDriftTests,
  saveSnapshot,
  validateSnapshot,
};
