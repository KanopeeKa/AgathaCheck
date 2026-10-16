'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { buildSnapshotFromPlan } = require('../lib/execute_plan_snapshot_v2');
const { planIdFromRefs, listActivePlans } = require('../lib/execute_plan_plans');
const { runScopeCheck, publishScopeCheck } = require('../lib/execute_plan_scope_run');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');

const REPO = 'acme/app';
const R = `/repos/${REPO}`;
const PLAN = 'scope-run-demo-7f3a';
const INTEGRATION = `cursor/${PLAN}-integration-7f3a`;
const INIT_SHA = '0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c';
const NOW = '2026-10-16T10:00:00Z';
const CONFIG = { owners: ['KanopeeKa'], bot_login: 'pawpet-bot' };

const PLAN_MD = `# Demo

## Goal
Demo.

## Phases

### Phase 1 — Server
\`\`\`json
{ "allowed_paths": ["server/bin/**"], "forbidden_paths": [], "allowed_exceptions": ["tests"],
  "companions": [], "exit_checklist": ["ok"] }
\`\`\`
Scope: x
Out of scope: y

## Proof on UAT
Look.
`;
const SNAPSHOT = buildSnapshotFromPlan({
  planId: PLAN, planMarkdown: PLAN_MD, controlIssue: 77, now: '2026-10-16T09:00:00Z', integrationSuffix: '7f3a',
});
const SNAP_JSON = JSON.stringify(SNAPSHOT, null, 2);
const b64 = (text) => Buffer.from(text, 'utf8').toString('base64');
const file = (text) => ({ body: { type: 'file', encoding: 'base64', content: b64(text), sha: 'x' } });

const CONTROL_ISSUE = { number: 77, labels: [{ name: 'execute-plan' }, { name: `plan:${PLAN}` }, { name: 'autonomous-approved' }] };
const APPROVE = {
  id: 9001,
  body: `approve-autonomous ${PLAN} ${SNAPSHOT.approval_hash} until ${SNAPSHOT.approved_until}`,
  user: { login: 'KanopeeKa' },
  author_association: 'OWNER',
  created_at: '2026-10-16T09:05:00Z',
  updated_at: '2026-10-16T09:05:00Z',
};
function statusComment(extra = {}) {
  const json = { schema: 1, plan_id: PLAN, init_sha: INIT_SHA, state: 'phase:implementing', stop: null, ...extra };
  return { id: 9002, body: `<!-- execute-plan-status:${PLAN} -->\n\`\`\`json\n${JSON.stringify(json)}\n\`\`\`\n` };
}

const ISSUES_KEY = `GET ${R}/issues?labels=execute-plan,plan:${PLAN}&per_page=100&state=open`;

function setup({ issue = CONTROL_ISSUE, comments = [APPROVE, statusComment()], files = [], extra = {} } = {}) {
  const routes = {
    [ISSUES_KEY]: { body: [issue] },
    [`GET ${R}/contents/.github/execute-plan.config.json?ref=main`]: file(JSON.stringify(CONFIG)),
    [`GET ${R}/issues/77/comments?per_page=100`]: { body: comments },
    [`GET ${R}/contents/.agents/plans/${PLAN}.snapshot.json?ref=${INIT_SHA}`]: file(SNAP_JSON),
    [`GET ${R}/contents/.agents/plans/${PLAN}.md?ref=${INIT_SHA}`]: file(PLAN_MD),
    [`GET ${R}/pulls/5/files?per_page=100`]: { body: files.map((filename) => ({ filename })) },
    ...extra,
  };
  const fake = createFakeFetch(routes);
  const client = createGitHubClient({ repo: REPO, token: 't', fetchImpl: fake, sleep: async () => {} });
  return { client, fake };
}

const phasePr = {
  prNumber: 5, headSha: 'a'.repeat(40), headRef: `cursor/${PLAN}-p1`, baseRef: INTEGRATION, headRepo: REPO, repo: REPO, now: NOW,
};

test('fork PR → success ok, no GitHub calls', async () => {
  const { client, fake } = setup();
  const res = await runScopeCheck(client, { ...phasePr, headRepo: 'evil/app' });
  assert.deepEqual([res.conclusion, res.title, res.summary], ['success', 'ok', 'not an execute-plan PR (fork)']);
  assert.equal(fake.calls.length, 0);
});

test('non-plan PR → success ok (no plan id, or no open control issue)', async () => {
  const { client } = setup();
  const none = await runScopeCheck(client, { ...phasePr, headRef: 'feature/x', baseRef: 'main' });
  assert.deepEqual([none.conclusion, none.title, none.planId], ['success', 'ok', null]);
  const { client: c2 } = setup({ extra: { [ISSUES_KEY]: { body: [] } } });
  const noIssue = await runScopeCheck(c2, phasePr);
  assert.deepEqual([noIssue.conclusion, noIssue.title], ['success', 'ok']);
});

test('phase PR in scope → success', async () => {
  const { client } = setup({ files: ['server/bin/server.js', 'server/test/x.test.js'] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title, res.planId], ['success', 'ok', PLAN]);
});

test('phase PR unclassified → failure, summary lists the file', async () => {
  const { client } = setup({ files: ['server/bin/server.js', 'flutter_app/lib/main.dart'] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'unclassified']);
  assert.match(res.summary, /flutter_app\/lib\/main\.dart.*unclassified/);
});

test('drift on plan file edit in a phase PR', async () => {
  const { client } = setup({ files: [`.agents/plans/${PLAN}.md`] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'drift']);
});

test('snapshot not loadable → failure drift with the error', async () => {
  const { client } = setup({
    extra: { [`GET ${R}/contents/.agents/plans/${PLAN}.snapshot.json?ref=${INIT_SHA}`]: { status: 404, body: {} } },
  });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'drift']);
  assert.match(res.summary, /snapshot .* not found/);
});

test('missing status comment → failure drift', async () => {
  const { client } = setup({ comments: [APPROVE] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'drift']);
});

const release = { ...phasePr, headRef: INTEGRATION, baseRef: 'main' };
const planFilesRoutes = (snapJson, md) => ({
  [`GET ${R}/contents/.agents/plans/${PLAN}.snapshot.json?ref=${release.headSha}`]: file(snapJson),
  [`GET ${R}/contents/.agents/plans/${PLAN}.md?ref=${release.headSha}`]: file(md),
});
const planFileDiff = ['server/bin/server.js', `.agents/plans/${PLAN}.md`, `.agents/plans/${PLAN}.snapshot.json`];

test('release PR with verified plan files → success', async () => {
  const { client } = setup({ files: planFileDiff, extra: planFilesRoutes(SNAP_JSON, PLAN_MD) });
  const res = await runScopeCheck(client, release);
  assert.deepEqual([res.conclusion, res.title], ['success', 'ok']);
});

test('release PR with tampered plan file → failure drift', async () => {
  const { client } = setup({ files: planFileDiff, extra: planFilesRoutes(SNAP_JSON, `${PLAN_MD}\nextra`) });
  const res = await runScopeCheck(client, release);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'drift']);
});

test('release PR with tampered snapshot → failure drift', async () => {
  const tampered = JSON.stringify({ ...SNAPSHOT, title: 'Other' });
  const { client } = setup({ files: planFileDiff, extra: planFilesRoutes(tampered, PLAN_MD) });
  const res = await runScopeCheck(client, release);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'drift']);
});

test('overflow → too-many-files', async () => {
  const page = Array.from({ length: 3000 }, (_, i) => ({ filename: `f${i}.txt` }));
  const { client } = setup({
    extra: {
      [`GET ${R}/pulls/5/files?per_page=100`]: { body: page },
      [`GET ${R}/pulls/5`]: { body: { changed_files: 3500 } },
    },
  });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'too-many-files']);
});

test('stopped plan → plan-stopped (revoked label, expiry, escalation)', async () => {
  const revoked = { ...CONTROL_ISSUE, labels: [...CONTROL_ISSUE.labels, { name: 'autonomous-revoked' }] };
  const { client } = setup({ issue: revoked, files: ['server/bin/server.js'] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'plan-stopped']);
  assert.match(res.summary, /revoked/);

  const { client: c2 } = setup({ files: ['server/bin/server.js'] });
  const expired = await runScopeCheck(c2, { ...phasePr, now: '2026-11-01T00:00:00Z' });
  assert.equal(expired.title, 'plan-stopped');
  assert.match(expired.summary, /expired/);

  const needs = { ...CONTROL_ISSUE, labels: [...CONTROL_ISSUE.labels, { name: 'needs-owner' }] };
  const { client: c3 } = setup({ issue: needs, files: ['server/bin/server.js'] });
  assert.match((await runScopeCheck(c3, phasePr)).summary, /escalation/);
});

test('publish creates then updates the check run', async () => {
  const sha = 'b'.repeat(40);
  const out = { headSha: sha, conclusion: 'success', title: 'ok', summary: 's' };
  const created = createFakeFetch({
    [`GET ${R}/commits/${sha}/check-runs?per_page=100`]: { body: { check_runs: [{ id: 1, name: 'other' }] } },
    [`POST ${R}/check-runs`]: { status: 201, body: { id: 2 } },
  });
  await publishScopeCheck(createGitHubClient({ repo: REPO, token: 't', fetchImpl: created }), out);
  assert.deepEqual(created.calls[1].body, {
    name: 'execute-plan-scope', head_sha: sha, status: 'completed', conclusion: 'success', output: { title: 'ok', summary: 's' },
  });

  const updated = createFakeFetch({
    [`GET ${R}/commits/${sha}/check-runs?per_page=100`]: { body: { check_runs: [{ id: 42, name: 'execute-plan-scope' }] } },
    [`PATCH ${R}/check-runs/42`]: { body: { id: 42 } },
  });
  await publishScopeCheck(createGitHubClient({ repo: REPO, token: 't', fetchImpl: updated }), { ...out, conclusion: 'failure', title: 'drift' });
  assert.equal(updated.calls[1].method, 'PATCH');
  assert.equal(updated.calls[1].body.conclusion, 'failure');
});

test('planIdFromRefs covers every plan branch shape', () => {
  const ref = (head_ref, base_ref = 'main') => planIdFromRefs({ head_ref, base_ref });
  assert.equal(ref(`cursor/${PLAN}-p2`, INTEGRATION), PLAN);
  assert.equal(ref(`cursor/${PLAN}-sync-1`, INTEGRATION), PLAN);
  assert.equal(ref('main', INTEGRATION), PLAN);
  assert.equal(ref(`cursor/${PLAN}-remedial-3`), PLAN);
  assert.equal(ref(INTEGRATION), PLAN);
  assert.equal(ref('feature/x'), null);
  assert.equal(ref('cursor/other-thing'), null);
});

test('listActivePlans skips completed plans and non-plan labels', async () => {
  const issue = (number, ...labels) => ({ number, labels: labels.map((name) => ({ name })) });
  const fake = createFakeFetch({
    [`GET ${R}/issues?labels=execute-plan,autonomous-approved&per_page=100&state=open`]: {
      body: [
        issue(1, 'execute-plan', 'autonomous-approved', 'plan:alpha-plan-1'),
        issue(2, 'execute-plan', 'autonomous-approved', 'plan:beta-plan-2', 'plan:complete'),
        issue(3, 'execute-plan', 'autonomous-approved'),
        { ...issue(4, 'execute-plan', 'autonomous-approved', 'plan:pr-plan'), pull_request: {} },
      ],
    },
  });
  const plans = await listActivePlans(createGitHubClient({ repo: REPO, token: 't', fetchImpl: fake }));
  assert.deepEqual(plans, [{ planId: 'alpha-plan-1', issueNumber: 1 }]);
});

test('config file matches the contract keys', () => {
  const cfg = require('../../.github/execute-plan.config.json');
  assert.deepEqual(cfg.owners, ['KanopeeKa']);
  assert.equal(cfg.bot_login, 'pawpet-bot');
  assert.equal(typeof cfg.cursor_model_implement, 'string');
  assert.equal(cfg.cursor_model_fix, cfg.cursor_model_implement);
  assert.deepEqual(cfg.required_checks.integration, ['ci-gate / CI passed', 'execute-plan-scope']);
});
