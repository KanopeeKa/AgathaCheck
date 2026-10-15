'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { computeApprovalHash } = require('../lib/execute_plan_approval');
const { V2_CAPS } = require('../lib/execute_plan_constants');
const { runInit } = require('../lib/execute_plan_init');
const {
  buildSnapshotFromPlan, isV2, loadSnapshotAtRef, parsePlanMarkdown, validateSnapshotV2,
} = require('../lib/execute_plan_snapshot_v2');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');

const REPO_ROOT = path.resolve(__dirname, '../..');
const PLAN_ID = 'proof-build-label-7f3a';
const PLAN_MD = `# Proof run

## Goal
Prove it.

## Phases

### Phase 1 — First
\`\`\`json
{ "allowed_paths": ["a/**"], "forbidden_paths": [], "allowed_exceptions": ["tests"], "companions": [], "exit_checklist": ["ok"] }
\`\`\`
Scope: x

### Phase 2 — Second
\`\`\`json
{ "allowed_paths": ["b.md"], "exit_checklist": ["ok"] }
\`\`\`

## Proof on UAT
Look.
`;
const build = (over = {}) => buildSnapshotFromPlan({ planId: PLAN_ID, planMarkdown: PLAN_MD, controlIssue: 12, now: '2026-10-16T09:00:30Z', ...over });
const rehash = (s) => ({ ...s, approval_hash: computeApprovalHash(s) });
const bad = (mutate, pattern) => {
  const s = build();
  mutate(s);
  assert.throws(() => validateSnapshotV2(rehash(s), { planMarkdown: PLAN_MD }), pattern);
};

test('buildSnapshotFromPlan produces a valid snapshot', () => {
  const s = build();
  assert.ok(isV2(s));
  assert.equal(s.integration_branch, `cursor/${PLAN_ID}-integration-7f3a`);
  assert.equal(s.phases[1].branch, `cursor/${PLAN_ID}-p2`);
  assert.equal(s.created_at, '2026-10-16T09:00:30Z');
  assert.equal(s.approved_until, '2026-10-23T09:00:00Z');
  assert.equal(s.settings.budgets.launches_per_phase, 5);
  assert.deepEqual(s.phases[1].allowed_exceptions, []);
  validateSnapshotV2(s, { planMarkdown: PLAN_MD });
});

test('integration suffix falls back to sha256 of plan id', () => {
  const s = buildSnapshotFromPlan({ planId: 'alpha-beta-q', planMarkdown: PLAN_MD, controlIssue: 1, now: '2026-10-16T09:00:00Z' });
  assert.match(s.integration_branch, /^cursor\/alpha-beta-q-integration-[0-9a-f]{4}$/);
});

test('snapshot caps: raising a budget rejected', () => {
  bad((s) => { s.settings.budgets.launches_per_phase = V2_CAPS.launches_per_phase + 1; }, /launches_per_phase exceeds the cap/);
  assert.throws(() => build({ windowDays: 15 }), /window_days/);
});

test('snapshot caps: lowering accepted', () => {
  const s = rehash({ ...build(), settings: { ...build().settings, budgets: { ci_per_phase: 1, launches_per_phase: 1, remedial_rounds: 1, sync_attempts: 1, daily_launches: 1 } } });
  validateSnapshotV2(s, { planMarkdown: PLAN_MD });
});

test('integration branch pattern enforced', () => {
  bad((s) => { s.integration_branch = `cursor/${PLAN_ID}-integration-toolong`; }, /integration_branch/);
});

test('phase branch pattern enforced', () => {
  bad((s) => { s.phases[0].branch = 'cursor/other-p1'; }, /phases\[0\]\.branch/);
});

test('snapshot rejects hash, plan file and window violations', () => {
  const s = build();
  assert.throws(() => validateSnapshotV2({ ...s, title: 'changed' }, { planMarkdown: PLAN_MD }), /approval_hash/);
  assert.throws(() => validateSnapshotV2(s, { planMarkdown: `${PLAN_MD}\n` }), /plan_file_sha256/);
  bad((x) => { x.approved_until = '2026-11-16T09:00:30Z'; }, /window cap/);
  bad((x) => { x.phases[0].allowed_exceptions = ['file-split']; }, /allowed_exceptions/);
  bad((x) => { x.phases[0].companions = ['a', 'b', 'c', 'd', 'e', 'f']; }, /companions/);
  bad((x) => { x.release_branch = 'develop'; }, /release_branch/);
  bad((x) => { x.extra = 1; }, /unknown snapshot field/);
});

test('plan markdown json block parsed', () => {
  const parsed = parsePlanMarkdown(PLAN_MD);
  assert.equal(parsed.title, 'Proof run');
  assert.deepEqual(parsed.phases.map((p) => p.id), ['1', '2']);
  assert.deepEqual(parsed.phases[0].scope.allowed_paths, ['a/**']);
});

test('plan markdown with Rules heading rejected', () => {
  for (const name of ['Rules', 'Process', 'Contract']) {
    assert.throws(() => parsePlanMarkdown(`${PLAN_MD}\n#### ${name}\nx\n`), new RegExp(`process rules \\(heading "${name}"\\)`));
  }
});

test('plan markdown rejects bad json and missing phases', () => {
  assert.throws(() => parsePlanMarkdown(PLAN_MD.replace('"a/**"', 'a/**')), /not valid JSON/);
  assert.throws(() => parsePlanMarkdown('# T\n\n## Goal\nx\n'), /no "### Phase/);
});

test('loadSnapshotAtRef reads both files and checks the hash', async () => {
  const snap = build();
  const file = (text) => ({ body: { type: 'file', encoding: 'base64', content: Buffer.from(text).toString('base64'), sha: 'abc' } });
  const routes = {
    [`GET /repos/o/r/contents/.agents/plans/${PLAN_ID}.snapshot.json?ref=main`]: file(JSON.stringify(snap)),
    [`GET /repos/o/r/contents/.agents/plans/${PLAN_ID}.md?ref=main`]: file(PLAN_MD),
  };
  const client = createGitHubClient({ repo: 'o/r', token: 't', fetchImpl: createFakeFetch(routes) });
  const loaded = await loadSnapshotAtRef(client, PLAN_ID, 'main');
  assert.equal(loaded.snapshot.approval_hash, snap.approval_hash);
  routes[`GET /repos/o/r/contents/.agents/plans/${PLAN_ID}.md?ref=main`] = file(`${PLAN_MD}x`);
  await assert.rejects(loadSnapshotAtRef(client, PLAN_ID, 'main'), /plan_file_sha256/);
});

function cli(...args) {
  return spawnSync(process.execPath, [path.join(REPO_ROOT, 'scripts/validate_execute_plan_snapshot.js'), ...args], { encoding: 'utf8' });
}

test('v1 file routed unchanged', () => {
  const res = cli(path.join(REPO_ROOT, '.agents/plans/_example.snapshot.json'));
  assert.equal(res.status, 0, res.stderr);
  assert.match(res.stdout, /OK/);
});

test('v2 example validates through the CLI', () => {
  const res = cli(path.join(REPO_ROOT, '.agents/plans/_example.v2.snapshot.json'));
  assert.equal(res.status, 0, res.stderr);
});

test('--fix-hash refuses v2', () => {
  const res = cli('--fix-hash', path.join(REPO_ROOT, '.agents/plans/_example.v2.snapshot.json'));
  assert.equal(res.status, 1);
  assert.match(res.stderr, /--fix-hash is not allowed for v2 snapshots/);
});

test('example v2 snapshot is regenerated from the example plan', () => {
  const dir = path.join(REPO_ROOT, '.agents/plans');
  const md = fs.readFileSync(path.join(dir, '_example.v2.md'), 'utf8');
  const snap = JSON.parse(fs.readFileSync(path.join(dir, '_example.v2.snapshot.json'), 'utf8'));
  const rebuilt = buildSnapshotFromPlan({ planId: 'proof-build-label-7f3a', planMarkdown: md, controlIssue: 1900, now: '2026-10-16T09:00:00Z' });
  assert.deepEqual(snap, rebuilt);
});

// ---- init ----
function fakeGit({ branch = `cursor/${PLAN_ID}-init`, status = ' M .agents/plans/proof-build-label-7f3a.md\n' } = {}) {
  const calls = [];
  return {
    calls,
    currentBranch: () => branch,
    statusPorcelain: () => status,
    add: (p) => calls.push(['add', p]),
    commit: (m) => calls.push(['commit', m]),
    pushUpstream: () => calls.push(['push']),
    headSha: () => 'c0ffee',
  };
}
function tmpRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ep-init-'));
  fs.mkdirSync(path.join(dir, '.agents/plans'), { recursive: true });
  fs.writeFileSync(path.join(dir, `.agents/plans/${PLAN_ID}.md`), PLAN_MD);
  return dir;
}
const NOW = '2026-10-16T09:00:00Z';

test('init refuses wrong branch', async () => {
  await assert.rejects(
    runInit({ client: {}, planId: PLAN_ID, git: fakeGit({ branch: 'main' }), now: NOW, cwd: tmpRepo() }),
    (e) => e.exitCode === 3 && /cursor\/proof-build-label-7f3a-init/.test(e.message),
  );
});

test('init refuses dirty tree', async () => {
  await assert.rejects(
    runInit({ client: {}, planId: PLAN_ID, git: fakeGit({ status: ' M README.md\n' }), now: NOW, cwd: tmpRepo() }),
    (e) => e.exitCode === 3 && /README\.md/.test(e.message),
  );
});

test('init dry-run output', async () => {
  const git = fakeGit({ branch: 'main' });
  const res = await runInit({ client: null, planId: PLAN_ID, dryRun: true, git, now: NOW, cwd: tmpRepo() });
  assert.equal(res.snapshot.control_issue, 0);
  assert.match(res.approvalLine, new RegExp(`^approve-autonomous ${PLAN_ID} sha256:[0-9a-f]{64} until 2026-10-23T09:00:00Z$`));
  assert.ok(res.output.includes(res.approvalLine));
  assert.deepEqual(git.calls, []);
});

test('init creates issue, commits, pushes, then fills the approval line', async () => {
  const dir = tmpRepo();
  const git = fakeGit();
  const issueCalls = [];
  const client = {
    createIssue: async (arg) => { issueCalls.push(['create', arg]); return { number: 77 }; },
    updateIssue: async (n, arg) => { issueCalls.push(['update', n, arg]); },
  };
  const res = await runInit({ client, planId: PLAN_ID, git, now: NOW, cwd: dir });
  assert.equal(res.snapshot.control_issue, 77);
  const written = JSON.parse(fs.readFileSync(path.join(dir, `.agents/plans/${PLAN_ID}.snapshot.json`), 'utf8'));
  assert.deepEqual(written, res.snapshot);
  validateSnapshotV2(written, { planMarkdown: PLAN_MD });
  assert.deepEqual(git.calls.map((c) => c[0]), ['add', 'commit', 'push']);
  assert.equal(git.calls[1][1], `execute-plan init ${PLAN_ID}`);
  assert.equal(issueCalls[0][1].title, `execute-plan: Proof run (${PLAN_ID})`);
  assert.deepEqual(issueCalls[0][1].labels, ['execute-plan']);
  assert.match(issueCalls[0][1].body, /Approval hash: pending/);
  const finalBody = issueCalls[1][2].body;
  assert.ok(finalBody.includes(`Approval hash: ${res.snapshot.approval_hash}`));
  assert.ok(finalBody.includes(`Init branch: cursor/${PLAN_ID}-init @ c0ffee`));
  assert.ok(finalBody.includes(res.approvalLine));
});
