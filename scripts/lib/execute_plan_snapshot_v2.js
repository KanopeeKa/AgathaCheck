'use strict';

/**
 * Execute-plan v2 snapshot + plan-file handling.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/contracts.md §3.1, §3.2.
 */

const crypto = require('crypto');
const { ExecutePlanError, V2_CAPS, V2_DEFAULTS } = require('./execute_plan_constants');
const { computeApprovalHash } = require('./execute_plan_approval');

const PLAN_ID_RE = /^[a-z0-9][a-z0-9-]{2,48}$/;
const ISO_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
const DAY_MS = 24 * 60 * 60 * 1000;
const TOP_KEYS = [
  'schema_version', 'plan_id', 'title', 'plan_file', 'plan_file_sha256', 'release_branch',
  'integration_branch', 'control_issue', 'created_at', 'approved_until', 'settings',
  'protected_paths_version', 'phases', 'approval_hash',
];
const BUDGET_KEYS = ['ci_per_phase', 'launches_per_phase', 'remedial_rounds', 'sync_attempts', 'daily_launches'];
const PHASE_EXCEPTIONS = new Set(['tests', 'docs']);
const FORBIDDEN_HEADINGS = new Set(['contract', 'rules', 'process']);

const sha256Hex = (text) => crypto.createHash('sha256').update(text, 'utf8').digest('hex');
const isStringArray = (v) => Array.isArray(v) && v.every((s) => typeof s === 'string' && s.length > 0);

function fail(message) {
  throw new ExecutePlanError(message);
}

function isV2(snapshot) {
  return Boolean(snapshot) && snapshot.schema_version === 2;
}

function validatePhase(phase, index, planId) {
  const at = `phases[${index}]`;
  if (!phase || typeof phase !== 'object') fail(`${at} must be an object`);
  const id = String(index + 1);
  if (phase.id !== id) fail(`${at}.id must be "${id}"`);
  if (typeof phase.title !== 'string' || !phase.title) fail(`${at}.title must be a non-empty string`);
  if (phase.branch !== `cursor/${planId}-p${id}`) fail(`${at}.branch must be cursor/${planId}-p${id}`);
  if (!isStringArray(phase.allowed_paths) || phase.allowed_paths.length === 0) {
    fail(`${at}.allowed_paths must be a non-empty array of globs`);
  }
  if (!Array.isArray(phase.forbidden_paths) || !isStringArray(phase.forbidden_paths)) {
    fail(`${at}.forbidden_paths must be an array of globs`);
  }
  if (!Array.isArray(phase.allowed_exceptions) || !phase.allowed_exceptions.every((e) => PHASE_EXCEPTIONS.has(e))) {
    fail(`${at}.allowed_exceptions must be a subset of tests, docs`);
  }
  if (!isStringArray(phase.companions) || phase.companions.length > V2_CAPS.companions) {
    fail(`${at}.companions must be at most ${V2_CAPS.companions} globs`);
  }
  if (!isStringArray(phase.exit_checklist) || phase.exit_checklist.length === 0) {
    fail(`${at}.exit_checklist must be a non-empty array of strings`);
  }
}

function validateSnapshotV2(snapshot, { planMarkdown } = {}) {
  if (!snapshot || typeof snapshot !== 'object' || Array.isArray(snapshot)) fail('snapshot must be an object');
  if (snapshot.schema_version !== 2) fail('schema_version must be 2');
  for (const key of Object.keys(snapshot)) {
    if (!TOP_KEYS.includes(key)) fail(`unknown snapshot field "${key}"`);
  }
  for (const key of TOP_KEYS) {
    if (snapshot[key] === undefined) fail(`missing snapshot field "${key}"`);
  }
  const { plan_id: planId } = snapshot;
  if (typeof planId !== 'string' || !PLAN_ID_RE.test(planId)) fail(`plan_id must match ${PLAN_ID_RE}`);
  if (typeof snapshot.title !== 'string' || !snapshot.title) fail('title must be a non-empty string');
  if (snapshot.plan_file !== `.agents/plans/${planId}.md`) fail(`plan_file must be .agents/plans/${planId}.md`);
  if (typeof snapshot.plan_file_sha256 !== 'string' || !/^[0-9a-f]{64}$/.test(snapshot.plan_file_sha256)) {
    fail('plan_file_sha256 must be 64 lowercase hex characters');
  }
  if (snapshot.release_branch !== 'main') fail('release_branch must be "main"');
  const integrationRe = new RegExp(`^cursor/${planId}-integration-[a-z0-9]{4}$`);
  if (typeof snapshot.integration_branch !== 'string' || !integrationRe.test(snapshot.integration_branch)) {
    fail(`integration_branch must match cursor/${planId}-integration-<4 chars>`);
  }
  if (!Number.isInteger(snapshot.control_issue) || snapshot.control_issue < 0) {
    fail('control_issue must be a non-negative integer');
  }
  for (const key of ['created_at', 'approved_until']) {
    if (typeof snapshot[key] !== 'string' || !ISO_RE.test(snapshot[key]) || Number.isNaN(Date.parse(snapshot[key]))) {
      fail(`${key} must be an ISO-8601 UTC timestamp (YYYY-MM-DDTHH:MM:SSZ)`);
    }
  }
  const created = Date.parse(snapshot.created_at);
  const until = Date.parse(snapshot.approved_until);
  if (until <= created) fail('approved_until must be after created_at');
  if (until - created > V2_CAPS.window_days * DAY_MS) {
    fail(`approved_until exceeds the ${V2_CAPS.window_days}-day window cap`);
  }

  const { settings } = snapshot;
  if (!settings || typeof settings !== 'object') fail('settings must be an object');
  for (const flag of ['release_owner_review', 'tier3_blocking']) {
    if (typeof settings[flag] !== 'boolean') fail(`settings.${flag} must be a boolean`);
  }
  const budgets = settings.budgets;
  if (!budgets || typeof budgets !== 'object') fail('settings.budgets must be an object');
  for (const key of BUDGET_KEYS) {
    const value = budgets[key];
    if (!Number.isInteger(value) || value < 1) fail(`settings.budgets.${key} must be an integer >= 1`);
    if (value > V2_CAPS[key]) fail(`settings.budgets.${key} exceeds the cap of ${V2_CAPS[key]}`);
  }
  for (const key of Object.keys(budgets)) {
    if (!BUDGET_KEYS.includes(key)) fail(`unknown budget "${key}"`);
  }
  if (!Number.isInteger(snapshot.protected_paths_version) || snapshot.protected_paths_version < 1) {
    fail('protected_paths_version must be an integer >= 1');
  }

  const { phases } = snapshot;
  if (!Array.isArray(phases) || phases.length < 1 || phases.length > V2_CAPS.phases) {
    fail(`phases must have 1 to ${V2_CAPS.phases} entries`);
  }
  phases.forEach((phase, i) => validatePhase(phase, i, planId));

  if (computeApprovalHash(snapshot) !== snapshot.approval_hash) {
    fail('approval_hash does not match the snapshot content');
  }
  if (planMarkdown !== undefined && sha256Hex(planMarkdown) !== snapshot.plan_file_sha256) {
    fail('plan_file_sha256 does not match the plan file');
  }
  return snapshot;
}

function parsePlanMarkdown(markdown) {
  const lines = String(markdown).replace(/\r\n/g, '\n').split('\n');
  let title = null;
  const headings = [];
  let inFence = false;
  lines.forEach((line, i) => {
    if (/^\s*```/.test(line)) inFence = !inFence;
    if (inFence) return;
    const m = /^(#{1,6})\s+(.*?)\s*#*\s*$/.exec(line);
    if (!m) return;
    const name = m[2];
    if (FORBIDDEN_HEADINGS.has(name.toLowerCase())) {
      fail(`plan file must not contain process rules (heading "${name}")`);
    }
    if (m[1] === '#' && title === null) title = name;
    headings.push({ line: i, level: m[1].length, name });
  });
  if (!title) fail('plan file must start with a "# <title>" heading');

  const phases = [];
  headings.forEach((h, idx) => {
    const pm = h.level === 3 ? /^Phase (\S+) — (.+)$/.exec(h.name) : null;
    if (!pm) return;
    const end = headings.slice(idx + 1).find((n) => n.level <= 3);
    const section = lines.slice(h.line + 1, end ? end.line : lines.length);
    const open = section.findIndex((l) => /^```json\s*$/.test(l));
    const close = open < 0 ? -1 : section.findIndex((l, j) => j > open && /^```\s*$/.test(l));
    if (open < 0 || close < 0) fail(`Phase ${pm[1]} has no json scope block`);
    let scope;
    try {
      scope = JSON.parse(section.slice(open + 1, close).join('\n'));
    } catch (e) {
      fail(`Phase ${pm[1]} scope block is not valid JSON: ${e.message}`);
    }
    if (!scope || typeof scope !== 'object' || Array.isArray(scope)) fail(`Phase ${pm[1]} scope block must be a JSON object`);
    phases.push({ id: pm[1], title: pm[2], scope });
  });
  if (phases.length === 0) fail('plan file has no "### Phase <id> — <title>" headings');
  phases.forEach((p, i) => {
    if (p.id !== String(i + 1)) fail(`Phase ids must be 1, 2, … in order (found "${p.id}" at position ${i + 1})`);
  });
  return { title, phases };
}

function integrationSuffixFor(planId) {
  const m = /-([a-z0-9]{4})$/.exec(planId);
  return m ? m[1] : sha256Hex(planId).slice(0, 4);
}

function isoSeconds(date) {
  return `${date.toISOString().slice(0, 19)}Z`;
}

function buildSnapshotFromPlan({ planId, planMarkdown, controlIssue, now, windowDays = V2_DEFAULTS.window_days, integrationSuffix, settings = {} }) {
  if (!PLAN_ID_RE.test(planId || '')) fail(`plan_id must match ${PLAN_ID_RE}`);
  if (!Number.isInteger(windowDays) || windowDays < 1 || windowDays > V2_CAPS.window_days) {
    fail(`window_days must be an integer from 1 to ${V2_CAPS.window_days}`);
  }
  const parsed = parsePlanMarkdown(planMarkdown);
  const nowDate = new Date(now);
  if (Number.isNaN(nowDate.getTime())) fail('now must be a valid date');
  const until = new Date(nowDate.getTime() + windowDays * DAY_MS);
  until.setUTCSeconds(0, 0);
  const suffix = integrationSuffix || integrationSuffixFor(planId);
  const snapshot = {
    schema_version: 2,
    plan_id: planId,
    title: parsed.title,
    plan_file: `.agents/plans/${planId}.md`,
    plan_file_sha256: sha256Hex(planMarkdown),
    release_branch: 'main',
    integration_branch: `cursor/${planId}-integration-${suffix}`,
    control_issue: controlIssue,
    created_at: isoSeconds(nowDate),
    approved_until: isoSeconds(until),
    settings: {
      release_owner_review: false,
      tier3_blocking: false,
      ...settings,
      budgets: { ...V2_DEFAULTS.budgets, ...(settings.budgets || {}) },
    },
    protected_paths_version: 1,
    phases: parsed.phases.map((p) => ({
      id: p.id,
      title: p.title,
      branch: `cursor/${planId}-p${p.id}`,
      allowed_paths: p.scope.allowed_paths,
      forbidden_paths: p.scope.forbidden_paths || [],
      allowed_exceptions: p.scope.allowed_exceptions || [],
      companions: p.scope.companions || [],
      exit_checklist: p.scope.exit_checklist,
    })),
  };
  snapshot.approval_hash = computeApprovalHash(snapshot);
  return snapshot;
}

async function loadSnapshotAtRef(client, planId, ref) {
  const snapFile = await client.getFileAtRef(`.agents/plans/${planId}.snapshot.json`, ref);
  if (!snapFile) fail(`snapshot .agents/plans/${planId}.snapshot.json not found at ${ref}`);
  const planFile = await client.getFileAtRef(`.agents/plans/${planId}.md`, ref);
  if (!planFile) fail(`plan file .agents/plans/${planId}.md not found at ${ref}`);
  let snapshot;
  try {
    snapshot = JSON.parse(snapFile.content);
  } catch (e) {
    fail(`snapshot at ${ref} is not valid JSON: ${e.message}`);
  }
  if (snapshot.plan_id !== planId) fail(`snapshot plan_id "${snapshot.plan_id}" does not match "${planId}"`);
  validateSnapshotV2(snapshot, { planMarkdown: planFile.content });
  return { snapshot, planMarkdown: planFile.content };
}

module.exports = {
  buildSnapshotFromPlan,
  integrationSuffixFor,
  isV2,
  loadSnapshotAtRef,
  parsePlanMarkdown,
  validateSnapshotV2,
};
