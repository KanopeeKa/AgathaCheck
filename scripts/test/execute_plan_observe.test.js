'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');
const { buildSnapshotFromPlan } = require('../lib/execute_plan_snapshot_v2');
const { loadPlanContext, observe, observePr } = require('../lib/execute_plan_observe');
const { formatStatusComment } = require('../lib/execute_plan_status');

const PLAN_ID = 'proof-build-label-7f3a';
const PLAN_MD = `# Proof

## Goal
x

## Phases

### Phase 1 — First
\`\`\`json
{ "allowed_paths": ["a/**"], "exit_checklist": ["ok"] }
\`\`\`

## Proof on UAT
y
`;
const SNAP = buildSnapshotFromPlan({ planId: PLAN_ID, planMarkdown: PLAN_MD, controlIssue: 9, now: '2026-10-16T09:00:30Z' });
const INTEG = SNAP.integration_branch;
const CONFIG = {
  owners: ['KanopeeKa'], bot_login: 'pawpet-bot',
  required_checks: { integration: ['ci-gate / CI passed', 'execute-plan-scope'], main: ['ci-gate / CI passed'] },
  uat: { preuat_workflow: 'pre-uat-e2e.yml' },
};
const NOW = '2026-10-16T10:00:00Z';
const EPOCH = '2026-10-16T09:05:00Z';
const HEX = SNAP.approval_hash.replace('sha256:', '');
const file = (obj) => ({ body: { type: 'file', encoding: 'base64', sha: 's', content: Buffer.from(typeof obj === 'string' ? obj : JSON.stringify(obj)).toString('base64') } });
const STATUS = { schema: 1, plan_id: PLAN_ID, init_sha: 'a'.repeat(40), state: 'phase:pending', phase: '1', lease: null, launches: [], dispatched: { preuat_heads: [], deploy_tags: [] }, release: null, uat: null, stop: null, updated_at: NOW };
const comments = [
  { id: 1, user: { login: 'pawpet-bot' }, created_at: '2026-10-16T09:01:00Z', updated_at: '2026-10-16T09:01:00Z', body: formatStatusComment(STATUS, '') },
  { id: 2, user: { login: 'KanopeeKa' }, author_association: 'OWNER', created_at: EPOCH, updated_at: EPOCH, body: `approve-autonomous ${PLAN_ID} sha256:${HEX} until ${SNAP.approved_until}` },
];
const PULL = {
  number: 50, node_id: 'N50', state: 'open', draft: false, merged_at: null, merge_commit_sha: null, created_at: '2026-10-16T09:20:00Z',
  head: { ref: SNAP.phases[0].branch, sha: 'c1' }, base: { ref: INTEG }, mergeable_state: 'clean', auto_merge: null, labels: [{ name: 'x' }],
};
const run = (id, name, conclusion, completed_at, title) => ({ id, name, status: conclusion ? 'completed' : 'in_progress', conclusion, completed_at, output: { title } });
const gql = { body: { data: { repository: { pullRequest: { reviewThreads: { nodes: [
  { isResolved: false, path: 'a.js', comments: { nodes: [{ url: 'https://t/1', author: { login: 'rev' } }] } },
  { isResolved: true, path: 'b.js', comments: { nodes: [] } },
] } } } } } };

function routes(over = {}) {
  return {
    'GET /repos/o/r/contents/.github/execute-plan.config.json?ref=main': file(CONFIG),
    'GET /repos/o/r/issues/9': { body: { number: 9, labels: [{ name: 'execute-plan' }] } },
    'GET /repos/o/r/issues/9/comments?per_page=100': { body: comments },
    [`GET /repos/o/r/contents/.agents/plans/${PLAN_ID}.snapshot.json?ref=${STATUS.init_sha}`]: file(SNAP),
    [`GET /repos/o/r/contents/.agents/plans/${PLAN_ID}.md?ref=${STATUS.init_sha}`]: file(PLAN_MD),
    'GET /repos/o/r/pulls/50': { body: PULL },
    'GET /repos/o/r/commits/c1/check-runs?per_page=100': { body: { check_runs: [
      run(1, 'ci-gate / CI passed', 'success', '2026-10-16T09:30:00Z'),
      run(2, 'execute-plan-scope', 'failure', '2026-10-16T09:31:00Z', 'unclassified'),
      run(3, 'execute-plan-scope', 'success', '2026-10-16T09:40:00Z', 'ok'),
      run(4, 'other', 'failure', '2026-10-16T09:40:00Z'),
    ] } },
    'GET /repos/o/r/commits/c0/check-runs?per_page=100': { body: { check_runs: [run(5, 'ci-gate / CI passed', 'failure', '2026-10-16T09:25:00Z')] } },
    'GET /repos/o/r/commits/c00/check-runs?per_page=100': { body: { check_runs: [run(6, 'ci-gate / CI passed', 'failure', '2026-10-16T09:00:00Z')] } },
    'GET /repos/o/r/pulls/50/commits?per_page=100': { body: [{ sha: 'c00' }, { sha: 'c0' }, { sha: 'c1' }] },
    'GET /repos/o/r/pulls/50/reviews?per_page=100': { body: [
      { user: { login: 'copilot-pull-request-reviewer[bot]' }, state: 'COMMENTED', submitted_at: '2026-10-16T09:30:00Z' },
      { user: { login: 'KanopeeKa' }, state: 'APPROVED', submitted_at: '2026-10-16T09:31:00Z' },
    ] },
    'GET /repos/o/r/issues/50/timeline?per_page=100': { body: [
      { event: 'ready_for_review', created_at: '2026-10-16T09:10:00Z' }, { event: 'ready_for_review', created_at: '2026-10-16T09:50:00Z' }, { event: 'labeled', created_at: '2026-10-16T09:55:00Z' },
    ] },
    'POST /graphql': gql,
    ...over,
  };
}
function setup(over) {
  const fake = createFakeFetch(routes(over));
  const sleeps = [];
  const client = createGitHubClient({ repo: 'o/r', token: 't', fetchImpl: fake, sleep: async () => {} });
  return { fake, client, sleeps, sleep: async (ms) => { sleeps.push(ms); } };
}
const PR_OPTS = { requiredChecks: CONFIG.required_checks.integration, epoch: EPOCH, owners: CONFIG.owners };

test('observe maps a phase PR into PrObs (fake fetch)', async () => {
  const { client, sleep } = setup();
  const pr = await observePr(client, { number: 50 }, { ...PR_OPTS, sleep });
  assert.equal(pr.state, 'open');
  assert.equal(pr.head_sha, 'c1');
  assert.equal(pr.mergeable_state, 'clean');
  assert.deepEqual(pr.labels, ['x']);
  assert.deepEqual(pr.checks, [
    { name: 'ci-gate / CI passed', status: 'completed', conclusion: 'success', reason: null },
    { name: 'execute-plan-scope', status: 'completed', conclusion: 'success', reason: 'ok' },
  ]);
  assert.deepEqual(pr.unresolved_threads, [{ url: 'https://t/1', path: 'a.js', author: 'rev' }]);
  assert.equal(pr.copilot_review_submitted, true);
  assert.equal(pr.owner_approved, true);
  assert.equal(pr.auto_merge_enabled, false);
});

test('missing required check is reported as missing', async () => {
  const { client, sleep } = setup();
  const pr = await observePr(client, { number: 50 }, { ...PR_OPTS, requiredChecks: ['nope'], sleep });
  assert.deepEqual(pr.checks, [{ name: 'nope', status: 'missing', conclusion: null, reason: null }]);
});

test('failed_attempts counts distinct SHAs after epoch', async () => {
  const { client, sleep } = setup();
  // c00 failed before the epoch, c0 failed after, c1 (head) has only a superseded scope failure: 2 runs for one sha count once
  const pr = await observePr(client, { number: 50 }, { ...PR_OPTS, sleep });
  assert.equal(pr.failed_attempts_since_epoch, 2);
  const none = await observePr(client, { number: 50 }, { ...PR_OPTS, epoch: null, sleep });
  assert.equal(none.failed_attempts_since_epoch, 0);
});

test('ready_at from timeline', async () => {
  const { client, sleep } = setup();
  assert.equal((await observePr(client, { number: 50 }, { ...PR_OPTS, sleep })).ready_at, '2026-10-16T09:50:00Z');
  const t = setup({ 'GET /repos/o/r/issues/50/timeline?per_page=100': { body: [] } });
  assert.equal((await observePr(t.client, { number: 50 }, { ...PR_OPTS, sleep: t.sleep })).ready_at, PULL.created_at);
  const d = setup({ 'GET /repos/o/r/pulls/50': { body: { ...PULL, draft: true } } });
  assert.equal((await observePr(d.client, { number: 50 }, { ...PR_OPTS, sleep: d.sleep })).ready_at, null);
});

test('unknown mergeable_state re-read once', async () => {
  const unknown = { body: { ...PULL, mergeable_state: 'unknown' } };
  const a = setup({ 'GET /repos/o/r/pulls/50': [unknown, { body: { ...PULL, mergeable_state: 'behind' } }] });
  assert.equal((await observePr(a.client, { number: 50 }, { ...PR_OPTS, sleep: a.sleep })).mergeable_state, 'behind');
  assert.deepEqual(a.sleeps, [3000]);
  const b = setup({ 'GET /repos/o/r/pulls/50': unknown });
  assert.equal((await observePr(b.client, { number: 50 }, { ...PR_OPTS, sleep: b.sleep })).mergeable_state, 'unknown');
  assert.equal(b.fake.calls.filter((c) => c.key === 'GET /repos/o/r/pulls/50').length, 2);
});

test('loadPlanContext: errors exit 3 and status must be the bot\'s', async () => {
  const noCfg = setup({ 'GET /repos/o/r/contents/.github/execute-plan.config.json?ref=main': { status: 404, body: {} } });
  await assert.rejects(loadPlanContext(noCfg.client, { planId: PLAN_ID, controlIssue: 9 }), (e) => e.exitCode === 3 && /config/.test(e.message));
  const spoof = setup({ 'GET /repos/o/r/issues/9/comments?per_page=100': { body: [{ ...comments[0], user: { login: 'mallory' } }] } });
  await assert.rejects(loadPlanContext(spoof.client, { planId: PLAN_ID, controlIssue: 9 }), (e) => e.exitCode === 3 && /status comment/.test(e.message));
  const noSnap = setup({ [`GET /repos/o/r/contents/.agents/plans/${PLAN_ID}.snapshot.json?ref=${STATUS.init_sha}`]: { status: 404, body: {} } });
  await assert.rejects(loadPlanContext(noSnap.client, { planId: PLAN_ID, controlIssue: 9 }), (e) => e.exitCode === 3);
  const noIssue = setup();
  noIssue.client.listIssues = undefined; // simulate a client without label search (the real one has it since WP7a)
  await assert.rejects(loadPlanContext(noIssue.client, { planId: PLAN_ID }), (e) => e.exitCode === 3 && /--issue/.test(e.message));
});

test('loadPlanContext finds the issue by label only when listIssues exists', async () => {
  const { client } = setup();
  client.listIssues = async (q) => { assert.equal(q.labels, `plan:${PLAN_ID}`); return [{ number: 9 }]; };
  const ctx = await loadPlanContext(client, { planId: PLAN_ID });
  assert.equal(ctx.issueNumber, 9);
  assert.equal(ctx.snapshot.plan_id, PLAN_ID);
});

test('observe fills every Observations field (all phases pending, then a phase PR)', async () => {
  const emptyList = { body: [] };
  const base = {
    'GET /repos/o/r/branches/main': { body: { commit: { sha: 'm1' } } },
    'GET /repos/o/r/actions/workflows/pre-uat-e2e.yml/runs?branch=main&per_page=100': { body: { workflow_runs: [{ status: 'queued', head_sha: 'm1' }] } },
    [`GET /repos/o/r/branches/${encodeURIComponent(INTEG)}`]: { body: { commit: { sha: 'i1' } } },
    [`GET /repos/o/r/compare/${encodeURIComponent(INTEG)}...main`]: { body: { status: 'ahead', ahead_by: 2, behind_by: 0, files: [] } },
    [`GET /repos/o/r/branches/${encodeURIComponent(SNAP.phases[0].branch)}`]: { status: 404, body: {} },
    [`GET /repos/o/r/pulls?base=${INTEG}&head=o:${SNAP.phases[0].branch}&per_page=100&state=all`]: emptyList,
    [`GET /repos/o/r/pulls?base=${INTEG}&head=o:main&per_page=100&state=open`]: emptyList,
    [`GET /repos/o/r/pulls?base=${INTEG}&per_page=100&state=all`]: { body: [
      { number: 70, head: { ref: `cursor/${PLAN_ID}-sync-1` }, created_at: '2026-10-16T09:30:00Z' },
      { number: 71, head: { ref: `cursor/${PLAN_ID}-sync-0` }, created_at: '2026-10-16T09:00:00Z' },
    ] },
    [`GET /repos/o/r/pulls?base=main&head=o:${INTEG}&per_page=100&state=all`]: emptyList,
    'GET /repos/o/r/pulls?base=main&per_page=100&state=all': { body: [
      { number: 80, state: 'closed', merged_at: '2026-10-16T09:50:00Z', head: { ref: `cursor/${PLAN_ID}-remedial-1` } },
      { number: 81, state: 'closed', merged_at: null, head: { ref: `cursor/${PLAN_ID}-remedial-2` } },
    ] },
  };
  const { client, sleep } = setup(base);
  const ctx = await loadPlanContext(client, { planId: PLAN_ID, controlIssue: 9 });
  const obs = await observe(client, ctx, { now: NOW, sleep });
  assert.equal(obs.now, NOW);
  assert.deepEqual(obs.control.labels, ['execute-plan']);
  assert.equal(obs.control.authorizing.valid, true);
  assert.equal(obs.control.authorizing.created_at, EPOCH);
  assert.equal(obs.control.revoke_comment_at, null);
  assert.equal(obs.control.status.init_sha, STATUS.init_sha);
  assert.equal(obs.init_sha, STATUS.init_sha);
  assert.deepEqual(obs.main, { head_sha: 'm1', preuat_queued_for_head: true });
  assert.deepEqual(obs.integration, { exists: true, head_sha: 'i1', behind_main_by: 2 });
  assert.deepEqual(obs.phases, [{ id: '1', branch_exists: false, pr: null }]);
  assert.deepEqual(obs.sync, { open_pr: null, resolve_prs_since_epoch: 1 });
  assert.deepEqual(obs.release, { pr: null });
  assert.deepEqual(obs.remedial, { open_pr: null, merged_since_epoch: 1 });
  assert.equal(obs.uat, null);
});
