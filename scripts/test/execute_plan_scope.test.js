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
  validateBundleBudgetRatchet,
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
    snapshot: extra.snapshot || SNAP,
    category,
    phaseId,
    ownPlanFilesVerified: extra.ownPlanFilesVerified || false,
    stopped: extra.stopped || NOT_STOPPED,
    unchangedOnMain: extra.unchangedOnMain || new Set(),
    scopeAckReview: extra.scopeAckReview || null,
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

test('phase forbidden_paths beat allowed_paths; release skips non-protected files', () => {
  const snap = snapshot([phase('1', { allowed_paths: ['server/**'], forbidden_paths: ['server/legacy/**'] })]);
  assert.equal(verdict('server/legacy/a.js', 'phase', '1', snap), 'forbidden');
  assert.equal(evaluate(['server/legacy/a.js'], 'release', null, { snapshot: snap, ownPlanFilesVerified: true }).title, 'ok');
});

test('release and remedial: phase allowed_paths override another phase migration ban', () => {
  const snap = snapshot([
    phase('1', { allowed_paths: ['server/scripts/migrations/084_*'] }),
    phase('2', { allowed_paths: ['flutter_app/**'], forbidden_paths: ['server/scripts/migrations/**'] }),
    phase('4', { allowed_paths: ['server/scripts/migrations/085_*'], forbidden_paths: [] }),
  ]);
  const f84 = 'server/scripts/migrations/084_care_date_outcome.js';
  const f85 = 'server/scripts/migrations/085_care_item_closed.js';
  const orphan = 'server/scripts/migrations/099_orphan.js';
  for (const category of ['remedial', 'sync-resolve']) {
    assert.equal(verdict(f84, category, null, snap), 'allowed', category);
    assert.equal(verdict(f85, category, null, snap), 'allowed', category);
    assert.equal(verdict(orphan, category, null, snap), 'forbidden', category);
  }
  assert.equal(evaluate([f84, f85], 'release', null, { snapshot: snap, ownPlanFilesVerified: true }).title, 'ok');
  assert.equal(verdict(f84, 'phase', '2', snap), 'forbidden', 'phase 2 ban applies to its own PR');
  assert.equal(verdict(f84, 'phase', '1', snap), 'allowed');
});

test('release ignores non-protected files; sync-resolve keeps union scope', () => {
  const snap = snapshot([
    phase('1', {
      allowed_paths: ['server/lib/care/**', 'server/test/careContext/**'],
      forbidden_paths: ['flutter_app/**', 'e2e/**'],
      allowed_exceptions: ['tests'],
    }),
    phase('4', {
      allowed_paths: ['flutter_app/lib/features/pet_care/context/**'],
      forbidden_paths: ['server/**'],
      allowed_exceptions: ['tests'],
    }),
  ]);
  const serverTest = 'server/test/care/absence/absenceVisibility.test.js';
  const flutterTest = 'flutter_app/test/core/router/guardian_routes_test.dart';
  const barrel = 'flutter_app/lib/features/pet_care/pet_care.dart';
  assert.equal(evaluate([serverTest, flutterTest, barrel], 'release', null, { ownPlanFilesVerified: true }).conclusion, 'success');
  for (const category of ['sync-resolve', 'remedial']) {
    assert.equal(verdict(serverTest, category, null, snap), 'exception:tests', category);
    assert.equal(verdict(flutterTest, category, null, snap), 'exception:tests', category);
    assert.equal(verdict(barrel, category, null, snap), 'companion', category);
  }
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

test('validateBundleBudgetRatchet allows a small increase only', () => {
  const base = JSON.stringify({ version: 1, description: 'x', maxTotalBytes: 66000000, maxMainDartJsBytes: 7015000 });
  const ok = JSON.stringify({ version: 1, description: 'y', maxTotalBytes: 66000000, maxMainDartJsBytes: 7018000 });
  const badDecrease = JSON.stringify({ maxTotalBytes: 66000000, maxMainDartJsBytes: 7010000 });
  const badHuge = JSON.stringify({ maxTotalBytes: 66000000, maxMainDartJsBytes: 7200000 });
  assert.equal(validateBundleBudgetRatchet(base, ok), null);
  assert.match(validateBundleBudgetRatchet(base, badDecrease), /may only increase/);
  assert.match(validateBundleBudgetRatchet(base, badHuge), /1\.5%/);
  assert.match(validateBundleBudgetRatchet(base, JSON.stringify({ maxMainDartJsBytes: 1e400, maxTotalBytes: 66000000 })), /finite/);
});

test('web bundle budget file is a companion only where a phase is scoped under flutter_app/', () => {
  const budget = 'scripts/ci/web-bundle-budget.json';
  assert.equal(verdict(budget, 'phase', '2'), 'companion');
  assert.equal(verdict(budget, 'phase', '1'), 'unclassified');
  assert.equal(verdict(budget, 'release', null), 'companion');
  const serverOnly = snapshot([phase('1', { allowed_paths: ['server/**'] })]);
  assert.equal(verdict(budget, 'phase', '1', serverOnly), 'unclassified');
  assert.equal(verdict(budget, 'release', null, serverOnly), 'unclassified');
  assert.equal(verdict('scripts/ci/check-web-bundle-budget.mjs', 'phase', '2'), 'unclassified');
});

test('companions beyond the cap are companion-cap', () => {
  const files = Array.from({ length: 33 }, (_, i) => `flutter_app/lib/gen/m${i + 1}.g.dart`);
  const r = evaluate(files, 'phase', '1');
  assert.equal(r.conclusion, 'failure');
  assert.equal(r.title, 'companion-cap');
  assert.deepEqual(r.companionsUsed, files.slice(0, 30));
  assert.deepEqual(
    r.violations,
    files.slice(30).map((file) => ({ file, reason: 'companion-cap' })),
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

test('release checks protected and own-plan only; sync-resolve keeps union', () => {
  const files = ['server/a.js', 'flutter_app/lib/features/care/widgets/x.dart', 'docs/y.md', 'server/test/a.test.js'];
  assert.equal(evaluate(files, 'release', null, { ownPlanFilesVerified: true }).conclusion, 'success');
  assert.equal(evaluate(files, 'sync-resolve').conclusion, 'success');
  assert.equal(verdict('flutter_app/lib/features/care/widgets/x.dart', 'phase', '1'), 'unclassified');
});

test('release skips files unchanged on main; protected files that differ stay protected', () => {
  const side = 'scripts/ci/web-bundle-budget.json';
  const unchanged = new Set([side]);
  const r = evaluate([side], 'release', null, { unchangedOnMain: unchanged, ownPlanFilesVerified: true });
  assert.equal(r.conclusion, 'success');
  assert.deepEqual(r.violations, []);
  const protectedPath = '.github/workflows/ci.yml';
  const r2 = evaluate([protectedPath], 'release', null, { unchangedOnMain: new Set(), ownPlanFilesVerified: true });
  assert.equal(r2.title, 'protected');
  const noopProtected = evaluate([protectedPath], 'release', null, {
    unchangedOnMain: new Set([protectedPath]),
    ownPlanFilesVerified: true,
  });
  assert.equal(noopProtected.conclusion, 'success');
});

test('RUNNING worker gate: classify unchanged protected separately from diff', () => {
  assert.equal(verdict('.github/workflows/ci.yml', 'release'), 'protected');
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

test('stopped plan still evaluates sync-resolve and remedial', () => {
  const snap = snapshot([phase('1', { allowed_paths: ['server/**'] })]);
  for (const category of ['sync-resolve', 'remedial']) {
    const r = evaluate(['server/a.js'], category, null, {
      stopped: { stopped: true, reason: 'revoked' },
      snapshot: snap,
    });
    assert.equal(r.title, 'ok', category);
  }
});

test('unclassified red', () => {
  const snap = snapshot([phase('1', { allowed_paths: ['server/**'] })]);
  const many = Array.from({ length: 11 }, (_, i) => `docs/extra-${i}.md`);
  const r = evaluate(many, 'phase', '1', { snapshot: snap });
  assert.equal(r.conclusion, 'failure');
  assert.equal(r.title, 'unclassified');
  const over = Array.from({ length: 11 }, (_, i) => `docs/x-${i}.md`);
  assert.equal(evaluate(over, 'phase', '9').title, 'unclassified');
});

test('phase PR: ≤10 harmless unclassified files are advisory success', () => {
  const snap = snapshot([phase('1', { allowed_paths: ['server/**'] })]);
  const side = ['docs/extra.md', 'docs/notes.md'];
  const r = evaluate(side, 'phase', '1', { snapshot: snap });
  assert.deepEqual([r.conclusion, r.title], ['success', 'ok']);
  assert.deepEqual(r.advisoryUnclassified, side);
});

test('owner scope-ack review clears forbidden violations but lists them for audit', () => {
  const review = { id: 42, state: 'APPROVED', commit_id: 'a'.repeat(40), user: { login: 'KanopeeKa' } };
  const r = evaluate(['db/migrations/099_x.sql'], 'phase', '1', { scopeAckReview: review });
  assert.deepEqual([r.conclusion, r.title], ['success', 'ok']);
  assert.deepEqual(r.ownerApprovedForbidden, ['db/migrations/099_x.sql']);
  assert.equal(r.scopeAckReviewId, 42);
});

test('approved_sensitive_paths still requires matching phase allowed_paths', () => {
  const snap = snapshot([phase('1', {
    allowed_paths: ['db/migrations/104_*'],
    approved_sensitive_paths: ['db/migrations/**'],
  })]);
  assert.equal(verdict('db/migrations/105_x.sql', 'phase', '1', snap), 'forbidden');
  assert.equal(verdict('db/migrations/104_x.sql', 'phase', '1', snap), 'allowed');
});

test('approved_sensitive_paths respects phase forbidden_paths', () => {
  const snap = snapshot([phase('1', {
    allowed_paths: ['db/migrations/**'],
    approved_sensitive_paths: ['db/migrations/**'],
    forbidden_paths: ['db/migrations/099_*'],
  })]);
  assert.equal(verdict('db/migrations/099_x.sql', 'phase', '1', snap), 'forbidden');
});

test('unsupported integration PR fails closed', () => {
  const r = evaluate(['server/a.js'], 'unsupported');
  assert.deepEqual([r.conclusion, r.title], ['failure', 'unsupported']);
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
    [`cursor/${PLAN}-remedial-1`, I, { category: 'unsupported', phaseId: null }],
    [`cursor/other-plan-p1`, I, { category: 'unsupported', phaseId: null }],
    [`cursor/${PLAN}-p1-extra`, I, { category: 'unsupported', phaseId: null }],
    [`cursor/${PLAN}-sync-x`, I, { category: 'unsupported', phaseId: null }],
    ['feature/x', 'main', { category: null, phaseId: null }],
    [I, 'cursor/other-integration-abcd', { category: null, phaseId: null }],
  ];
  for (const [head_ref, base_ref, expected] of cases) {
    assert.deepEqual(categorizePull({ head_ref, base_ref }, SNAP), expected, `${head_ref} -> ${base_ref}`);
  }
  assert.deepEqual(categorizePull({ head_ref: 'main', base_ref: I }, null), { category: null, phaseId: null });
});

test('title priority', () => {
  const companions = Array.from({ length: 31 }, (_, i) => `a/generated/f${i + 1}.js`);
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
    [companions.slice(0, 30), 'ok'],
  ];
  for (const [files, title] of ladder) {
    const r = evaluate(files, 'phase', '1');
    assert.equal(r.title, title);
    assert.equal(r.conclusion, title === 'ok' ? 'success' : 'failure');
  }
});
