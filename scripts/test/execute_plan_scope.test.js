'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  PROTECTED_PATHS,
  FIXED_COMPANIONS,
  EXCEPTION_GLOBS,
  categorizePull,
  classifyPath,
  evaluateDiff,
} = require('../lib/execute_plan_scope');

const PLAN = 'proof-build-label-7f3a';
const I = `cursor/${PLAN}-integration-7f3a`;

function phase(id, overrides = {}) {
  return {
    id,
    title: `Phase ${id}`,
    branch: `cursor/${PLAN}-p${id}`,
    allowed_paths: [],
    forbidden_paths: [],
    allowed_exceptions: [],
    companions: [],
    exit_checklist: ['done'],
    ...overrides,
  };
}

function snapshot(phases) {
  return { schema_version: 2, plan_id: PLAN, integration_branch: I, phases };
}

const SNAP = snapshot([
  phase('1', { allowed_paths: ['server/**', '.github/workflows/x.yml'], allowed_exceptions: ['tests'] }),
  phase('2', { allowed_paths: ['flutter_app/lib/features/care/**'], allowed_exceptions: ['docs'] }),
]);

const NOT_STOPPED = { stopped: false, reason: null };

function evaluate(files, category, phaseId = null, extra = {}) {
  return evaluateDiff({
    files,
    snapshot: SNAP,
    category,
    phaseId,
    ownPlanFilesVerified: false,
    stopped: NOT_STOPPED,
    ...extra,
  });
}

function verdict(file, category, phaseId = null, snap = SNAP) {
  return classifyPath(file, { snapshot: snap, category, phaseId }).verdict;
}

test('exported glob lists match the spec', () => {
  assert.equal(PROTECTED_PATHS.length, 19);
  assert.ok(PROTECTED_PATHS.includes('.github/**'));
  assert.ok(PROTECTED_PATHS.includes('docs/agent-efficiency/plans/execute-plan-v2/**'));
  assert.equal(FIXED_COMPANIONS.length, 6);
  assert.deepEqual(Object.keys(EXCEPTION_GLOBS), ['tests', 'docs']);
  assert.ok(PROTECTED_PATHS.every((g) => !g.includes('{')), 'no brace expansion');
});

test('forbidden beats allowed (server/** allowed, server/routes/auth/x.js)', () => {
  assert.equal(verdict('server/routes/auth/x.js', 'phase', '1'), 'forbidden');
  assert.equal(verdict('server/routes/pets.js', 'phase', '1'), 'allowed');
  const r = evaluate(['server/routes/auth/x.js'], 'phase', '1');
  assert.equal(r.conclusion, 'failure');
  assert.deepEqual(r.violations, [{ file: 'server/routes/auth/x.js', reason: 'forbidden' }]);
});

test('phase forbidden_paths beat allowed_paths', () => {
  const snap = snapshot([phase('1', { allowed_paths: ['server/**'], forbidden_paths: ['server/legacy/**'] })]);
  assert.equal(verdict('server/legacy/a.js', 'phase', '1', snap), 'forbidden');
  // Non-phase categories apply every phase's forbidden_paths.
  assert.equal(verdict('server/legacy/a.js', 'release', null, snap), 'forbidden');
});

test('protected beats allowed (.github/workflows/x.yml in allowed_paths)', () => {
  assert.equal(verdict('.github/workflows/x.yml', 'phase', '1'), 'protected');
  const r = evaluate(['.github/workflows/x.yml'], 'phase', '1');
  assert.equal(r.title, 'protected');
});

test('exception tests matches only test files', () => {
  for (const f of [
    'flutter_app/test/features/care/care_test.dart',
    'scripts/foo.test.js',
    'e2e/scripts/x.test.mjs',
    'web/a.test.ts',
    'flutter_app/lib/x_test.dart',
    'e2e/tests/care/visit.spec.ts',
  ]) {
    assert.equal(verdict(f, 'phase', '1'), 'exception:tests', f);
  }
  assert.equal(verdict('flutter_app/lib/main.dart', 'phase', '1'), 'unclassified');
  assert.equal(verdict('docs/x.md', 'phase', '1'), 'unclassified', 'phase 1 lists only tests');
});

test('exception docs rejects care_item.dart', () => {
  assert.equal(verdict('docs/e2e/notes.md', 'phase', '2'), 'exception:docs');
  assert.equal(verdict('flutter_app/README.md', 'phase', '2'), 'exception:docs');
  assert.equal(verdict('flutter_app/lib/models/care_item.dart', 'phase', '2'), 'unclassified');
});

test('barrel care_item.dart is a companion and reported', () => {
  const file = 'flutter_app/lib/features/pets/care_item.dart';
  assert.equal(verdict(file, 'phase', '1'), 'companion');
  const r = evaluate([file], 'phase', '1');
  assert.equal(r.conclusion, 'success');
  assert.deepEqual(r.companionsUsed, [file]);
});

test('openapi json is a companion', () => {
  assert.equal(verdict('docs/architecture/openapi/pets.json', 'phase', '1'), 'companion');
});

test('phase companions apply to that phase only', () => {
  const snap = snapshot([
    phase('1', { allowed_paths: ['server/**'], companions: ['server/package-lock.json.txt'] }),
    phase('2', { allowed_paths: ['docs/x.md'], companions: ['tool/gen.txt'] }),
  ]);
  assert.equal(verdict('tool/gen.txt', 'phase', '1', snap), 'unclassified');
  assert.equal(verdict('tool/gen.txt', 'phase', '2', snap), 'companion');
  assert.equal(verdict('tool/gen.txt', 'release', null, snap), 'companion');
});

test('sixth companion is companion-cap', () => {
  const files = [1, 2, 3, 4, 5, 6, 7].map((n) => `flutter_app/lib/gen/m${n}.g.dart`);
  const r = evaluate(files, 'phase', '1');
  assert.equal(r.conclusion, 'failure');
  assert.equal(r.title, 'companion-cap');
  assert.deepEqual(r.companionsUsed, files.slice(0, 5));
  assert.deepEqual(
    r.violations,
    files.slice(5).map((file) => ({ file, reason: 'companion-cap' })),
  );
});

test('own plan file in phase PR is drift', () => {
  for (const file of [`.agents/plans/${PLAN}.md`, `.agents/plans/${PLAN}.snapshot.json`]) {
    assert.equal(verdict(file, 'phase', '1'), 'own-plan-file');
    const r = evaluate([file], 'phase', '1', { ownPlanFilesVerified: true });
    assert.deepEqual(r.violations, [{ file, reason: 'drift' }]);
    assert.equal(r.title, 'drift');
  }
});

test('own plan file in release PR verified is allowed', () => {
  const files = [`.agents/plans/${PLAN}.md`, `.agents/plans/${PLAN}.snapshot.json`];
  const r = evaluate(files, 'release', null, { ownPlanFilesVerified: true });
  assert.equal(r.conclusion, 'success');
  assert.deepEqual(r.violations, []);
});

test('own plan file in release PR unverified is drift', () => {
  const file = `.agents/plans/${PLAN}.md`;
  const r = evaluate([file], 'release', null, { ownPlanFilesVerified: false });
  assert.equal(r.conclusion, 'failure');
  assert.deepEqual(r.violations, [{ file, reason: 'drift' }]);
});

test('other plan file is protected', () => {
  assert.equal(verdict('.agents/plans/other-plan-1a2b.md', 'release', null), 'protected');
  assert.equal(verdict(`.agents/plans/${PLAN}-copy.md`, 'phase', '1'), 'protected');
  const r = evaluate(['.agents/plans/other-plan-1a2b.snapshot.json'], 'release', null, {
    ownPlanFilesVerified: true,
  });
  assert.equal(r.title, 'protected');
});

test('release uses union', () => {
  const files = ['server/a.js', 'flutter_app/lib/features/care/widgets/x.dart', 'docs/y.md', 'server/test/a.test.js'];
  for (const category of ['release', 'sync-resolve']) {
    const r = evaluate(files, category);
    assert.equal(r.conclusion, 'success', category);
    assert.deepEqual(r.violations, []);
  }
  // A phase PR sees only its own phase's scope.
  assert.equal(verdict('flutter_app/lib/features/care/widgets/x.dart', 'phase', '1'), 'unclassified');
});

test('remedial allows e2e and tests', () => {
  const snap = snapshot([phase('1', { allowed_paths: ['server/**'] })]);
  const remedial = (f) => verdict(f, 'remedial', null, snap);
  assert.equal(remedial('e2e/pages/care.page.ts'), 'allowed');
  assert.equal(remedial('server/a.js'), 'allowed');
  assert.equal(remedial('flutter_app/test/a_test.dart'), 'exception:tests');
  assert.equal(remedial('docs/x.md'), 'unclassified', 'no phase lists docs');
  assert.equal(remedial('flutter_app/lib/main.dart'), 'unclassified');
});

test('sync category green without evaluation', () => {
  const r = evaluate(['.github/workflows/x.yml', 'server/routes/auth/x.js'], 'sync');
  assert.deepEqual(r, { conclusion: 'success', title: 'ok', violations: [], companionsUsed: [] });
  const none = evaluate(['.github/workflows/x.yml'], null);
  assert.equal(none.conclusion, 'success');
  assert.equal(none.title, 'ok');
});

test('stopped plan red plan-stopped', () => {
  for (const category of [null, 'sync', 'phase', 'release']) {
    const r = evaluate(['server/a.js'], category, category === 'phase' ? '1' : null, {
      stopped: { stopped: true, reason: 'revoked' },
    });
    assert.deepEqual(r, { conclusion: 'failure', title: 'plan-stopped', violations: [], companionsUsed: [] });
  }
});

test('unclassified red', () => {
  const r = evaluate(['flutter_app/lib/main.dart'], 'phase', '1');
  assert.equal(r.conclusion, 'failure');
  assert.equal(r.title, 'unclassified');
  // A phase id missing from the snapshot fails closed.
  assert.equal(evaluate(['server/a.js'], 'phase', '9').title, 'unclassified');
});

test('categorizePull for each category and null', () => {
  const cases = [
    [`cursor/${PLAN}-p1`, I, { category: 'phase', phaseId: '1' }],
    [`cursor/${PLAN}-p12`, I, { category: 'phase', phaseId: '12' }],
    ['main', I, { category: 'sync', phaseId: null }],
    [`cursor/${PLAN}-sync-2`, I, { category: 'sync-resolve', phaseId: null }],
    [I, 'main', { category: 'release', phaseId: null }],
    [`cursor/${PLAN}-remedial-1`, 'main', { category: 'remedial', phaseId: null }],
    [`cursor/${PLAN}-p1`, 'main', { category: null, phaseId: null }],
    [`cursor/${PLAN}-remedial-1`, I, { category: null, phaseId: null }],
    [`cursor/other-plan-p1`, I, { category: null, phaseId: null }],
    [`cursor/${PLAN}-p1-extra`, I, { category: null, phaseId: null }],
    [`cursor/${PLAN}-sync-x`, I, { category: null, phaseId: null }],
    ['feature/x', 'main', { category: null, phaseId: null }],
    [I, 'cursor/other-integration-abcd', { category: null, phaseId: null }],
  ];
  for (const [head_ref, base_ref, expected] of cases) {
    assert.deepEqual(categorizePull({ head_ref, base_ref }, SNAP), expected, `${head_ref} -> ${base_ref}`);
  }
  assert.deepEqual(categorizePull({ head_ref: 'main', base_ref: I }, null), { category: null, phaseId: null });
});

test('title priority', () => {
  const companions = [1, 2, 3, 4, 5, 6].map((n) => `a/generated/f${n}.js`);
  const all = [
    ...companions,
    'flutter_app/lib/main.dart',
    'server/routes/billing/x.js',
    'AGENTS.md',
    `.agents/plans/${PLAN}.md`,
  ];
  const ladder = [
    [all, 'drift'],
    [all.slice(0, -1), 'protected'],
    [all.slice(0, -2), 'forbidden'],
    [all.slice(0, -3), 'unclassified'],
    [all.slice(0, -4), 'companion-cap'],
    [companions.slice(0, 5), 'ok'],
  ];
  for (const [files, title] of ladder) {
    const r = evaluate(files, 'phase', '1');
    assert.equal(r.title, title);
    assert.equal(r.conclusion, title === 'ok' ? 'success' : 'failure');
  }
});
