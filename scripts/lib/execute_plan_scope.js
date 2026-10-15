'use strict';

/**
 * Execute-plan v2 scope matcher (pure, no I/O).
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/work-packages-runtime.md §WP2;
 * reference: docs/agent-efficiency/execute-plan-schema.md §v2 scope check.
 */

const { globToRegExp } = require('./execute_plan_schema');
const { isForbiddenPath } = require('../../.github/scripts/agent-safety-lib');

/** Paths no plan PR may change (rule 3b). No brace expansion: one glob per entry. */
const PROTECTED_PATHS = Object.freeze([
  'scripts/execute_plan_runtime.js',
  'scripts/execute_plan_runtime.test.js',
  'scripts/lib/execute_plan_*',
  'scripts/validate_execute_plan_snapshot.js',
  'scripts/test/execute_plan_*',
  'scripts/test/helpers/execute_plan_*',
  'scripts/test/fixtures/execute-plan-v2/**',
  'scripts/pre-push.sh',
  'scripts/pre-push-changed.sh',
  '.github/**',
  '.cursor/rules/**',
  '.cursor/skills/**',
  '.cursor/hooks.json',
  '.claude/**',
  'AGENTS.md',
  'CLAUDE.md',
  '.agents/plans/**',
  'docs/agent-efficiency/plans/execute-plan-v2.md',
  'docs/agent-efficiency/plans/execute-plan-v2/**',
]);

/** Generated and barrel files any plan PR may carry, up to COMPANION_CAP (rule 3g). */
const FIXED_COMPANIONS = Object.freeze([
  '**/generated/**',
  '**/*.g.dart',
  '**/*.freezed.dart',
  'flutter_app/lib/l10n/*.arb',
  'docs/architecture/openapi/*.json',
  'flutter_app/lib/features/*/*.dart',
]);

/** Exception codes a phase may list in allowed_exceptions (rule 3f). */
const EXCEPTION_GLOBS = Object.freeze({
  tests: Object.freeze([
    '**/test/**',
    '**/*.test.js',
    '**/*.test.mjs',
    '**/*.test.ts',
    '**/*_test.dart',
    'e2e/**/*.spec.ts',
  ]),
  docs: Object.freeze(['docs/**', '**/*.md']),
});

const COMPANION_CAP = 5;

/** Most serious first (rule 4). */
const VIOLATION_PRIORITY = ['drift', 'protected', 'forbidden', 'unclassified', 'companion-cap'];

const regexCache = new Map();

function matchesAny(file, globs) {
  for (const glob of globs) {
    let re = regexCache.get(glob);
    if (!re) {
      re = globToRegExp(glob);
      regexCache.set(glob, re);
    }
    if (re.test(file)) return true;
  }
  return false;
}

function escapeRegExp(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * @returns {{ category: 'phase'|'sync'|'sync-resolve'|'release'|'remedial'|null, phaseId: string|null }}
 */
function categorizePull({ head_ref, base_ref }, snapshot) {
  const none = { category: null, phaseId: null };
  if (!snapshot || typeof snapshot.plan_id !== 'string') return none;
  const integration = snapshot.integration_branch;
  if (typeof integration !== 'string' || integration === '') return none;
  const id = escapeRegExp(snapshot.plan_id);

  if (base_ref === integration) {
    const phase = new RegExp(`^cursor/${id}-p(\\d+)$`).exec(head_ref);
    if (phase) return { category: 'phase', phaseId: phase[1] };
    if (head_ref === 'main') return { category: 'sync', phaseId: null };
    if (new RegExp(`^cursor/${id}-sync-\\d+$`).test(head_ref)) {
      return { category: 'sync-resolve', phaseId: null };
    }
    return none;
  }
  if (base_ref === 'main') {
    if (head_ref === integration) return { category: 'release', phaseId: null };
    if (new RegExp(`^cursor/${id}-remedial-\\d+$`).test(head_ref)) {
      return { category: 'remedial', phaseId: null };
    }
  }
  return none;
}

/**
 * Phases whose rules apply: the PR's own phase for `phase` (none if the id is unknown,
 * so every file ends unclassified), every phase otherwise.
 */
function scopePhases(snapshot, category, phaseId) {
  const phases = Array.isArray(snapshot && snapshot.phases) ? snapshot.phases : [];
  if (category === 'phase') return phases.filter((p) => String(p.id) === String(phaseId));
  return phases;
}

function collect(phases, key) {
  const out = [];
  for (const p of phases) {
    if (Array.isArray(p[key])) out.push(...p[key]);
  }
  return out;
}

function ownPlanFiles(snapshot) {
  const id = snapshot && snapshot.plan_id;
  return [`.agents/plans/${id}.md`, `.agents/plans/${id}.snapshot.json`];
}

/**
 * Rules 3a–3h for one file, before the companion cap and the own-plan-file verification.
 * @returns {{ file, verdict: 'own-plan-file'|'protected'|'forbidden'|'allowed'|'exception:tests'|'exception:docs'|'companion'|'unclassified' }}
 */
function classifyPath(file, { snapshot, category, phaseId }) {
  const verdict = (v) => ({ file, verdict: v });
  if (ownPlanFiles(snapshot).includes(file)) return verdict('own-plan-file');
  if (matchesAny(file, PROTECTED_PATHS)) return verdict('protected');
  if (isForbiddenPath(file)) return verdict('forbidden');

  const phases = scopePhases(snapshot, category, phaseId);
  if (matchesAny(file, collect(phases, 'forbidden_paths'))) return verdict('forbidden');

  const allowed = collect(phases, 'allowed_paths');
  if (category === 'remedial') allowed.push('e2e/**');
  if (matchesAny(file, allowed)) return verdict('allowed');

  const exceptions = new Set(collect(phases, 'allowed_exceptions'));
  if (category === 'remedial') exceptions.add('tests');
  for (const code of Object.keys(EXCEPTION_GLOBS)) {
    if (exceptions.has(code) && matchesAny(file, EXCEPTION_GLOBS[code])) {
      return verdict(`exception:${code}`);
    }
  }

  const companions = [...collect(phases, 'companions'), ...FIXED_COMPANIONS];
  if (matchesAny(file, companions)) return verdict('companion');
  return verdict('unclassified');
}

function titleFor(violations) {
  const present = new Set(violations.map((v) => v.reason));
  return VIOLATION_PRIORITY.find((r) => present.has(r)) || 'ok';
}

/**
 * @param {{ files: string[], snapshot, category, phaseId, ownPlanFilesVerified: boolean, stopped: { stopped: boolean, reason: string|null } }} args
 * @returns {{ conclusion: 'success'|'failure', title: string, violations: {file:string, reason:string}[], companionsUsed: string[] }}
 */
function evaluateDiff({ files, snapshot, category, phaseId, ownPlanFilesVerified, stopped }) {
  if (stopped && stopped.stopped) {
    return { conclusion: 'failure', title: 'plan-stopped', violations: [], companionsUsed: [] };
  }
  if (category == null || category === 'sync') {
    return { conclusion: 'success', title: 'ok', violations: [], companionsUsed: [] };
  }

  const violations = [];
  const companionsUsed = [];
  for (const file of files || []) {
    const { verdict } = classifyPath(file, { snapshot, category, phaseId });
    if (verdict === 'own-plan-file') {
      if (!(category === 'release' && ownPlanFilesVerified === true)) {
        violations.push({ file, reason: 'drift' });
      }
    } else if (verdict === 'companion') {
      if (companionsUsed.length < COMPANION_CAP) companionsUsed.push(file);
      else violations.push({ file, reason: 'companion-cap' });
    } else if (verdict === 'protected' || verdict === 'forbidden' || verdict === 'unclassified') {
      violations.push({ file, reason: verdict });
    }
  }

  return {
    conclusion: violations.length > 0 ? 'failure' : 'success',
    title: titleFor(violations),
    violations,
    companionsUsed,
  };
}

module.exports = {
  PROTECTED_PATHS,
  FIXED_COMPANIONS,
  EXCEPTION_GLOBS,
  categorizePull,
  classifyPath,
  evaluateDiff,
};
