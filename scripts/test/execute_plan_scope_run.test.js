'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { buildSnapshotFromPlan } = require('../lib/execute_plan_snapshot_v2');
const { planIdFromRefs, listActivePlans } = require('../lib/execute_plan_plans');
const { cliCheckDiff, runScopeCheck, publishScopeCheck, publishScopeResult } = require('../lib/execute_plan_scope_run');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');
const { ackComment, workflowRunRoute } = require('./helpers/execute_plan_wp12');

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
{ "allowed_paths": ["server/bin/**", "scripts/ci/web-bundle-budget.json"], "forbidden_paths": [], "allowed_exceptions": ["tests"],
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
  return { id: 9002, user: { login: CONFIG.bot_login }, body: `<!-- execute-plan-status:${PLAN} -->\n\`\`\`json\n${JSON.stringify(json)}\n\`\`\`\n` };
}

const ISSUES_KEY = `GET ${R}/issues?labels=execute-plan,plan:${PLAN}&per_page=100&state=open`;

function planComments(extra = []) {
  return [APPROVE, ackComment(APPROVE.id), statusComment(), ...extra];
}

function setup({ issue = CONTROL_ISSUE, comments = planComments(), files = [], extra = {} } = {}) {
  const routes = {
    ...workflowRunRoute(REPO),
    [ISSUES_KEY]: { body: [issue] },
    [`GET ${R}/contents/.github/execute-plan.config.json?ref=main`]: file(JSON.stringify(CONFIG)),
    [`GET ${R}/issues/77/comments?per_page=100`]: { body: comments },
    [`GET ${R}/contents/.agents/plans/${PLAN}.snapshot.json?ref=${INIT_SHA}`]: file(SNAP_JSON),
    [`GET ${R}/contents/.agents/plans/${PLAN}.md?ref=${INIT_SHA}`]: file(PLAN_MD),
    [`GET ${R}/pulls/5/files?per_page=100`]: { body: files.map((filename) => ({ filename })) },
    [`GET ${R}/pulls/5/reviews?per_page=100`]: { body: [] },
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

test('cross-plan head into integration → unsupported with remediation summary', async () => {
  const { client } = setup({ files: ['server/bin/server.js'] });
  const res = await runScopeCheck(client, { ...phasePr, headRef: 'cursor/other-plan-p9' });
  assert.deepEqual([res.conclusion, res.title, res.planId], ['failure', 'unsupported', PLAN]);
  assert.match(res.summary, /main/);
  assert.doesNotMatch(res.summary, /No violations/);
});

test('phase PR unclassified → failure, summary lists the file', async () => {
  const many = Array.from({ length: 11 }, (_, i) => ({ filename: `docs/extra-${i}.md` }));
  const { client } = setup({ files: ['server/bin/server.js', ...many.map((f) => f.filename)] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'unclassified']);
  assert.match(res.summary, /docs\/extra-0\.md.*unclassified/);
});

test('drift on plan file edit in a phase PR', async () => {
  const { client } = setup({ files: [`.agents/plans/${PLAN}.md`] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'drift']);
});

test('snapshot not loadable → failure error with the error', async () => {
  const { client } = setup({
    extra: { [`GET ${R}/contents/.agents/plans/${PLAN}.snapshot.json?ref=${INIT_SHA}`]: { status: 404, body: {} } },
  });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'error']);
  assert.match(res.summary, /snapshot .* not found/);
});

test('missing status comment → failure error', async () => {
  const { client } = setup({ comments: [APPROVE] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'error']);
});

test('status comment written by someone other than the bot is ignored → failure error', async () => {
  const forged = { ...statusComment(), user: { login: 'stranger' } };
  const { client } = setup({ comments: [APPROVE, forged] });
  const res = await runScopeCheck(client, phasePr);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'error']);
  assert.match(res.summary, /status comment/);
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

test('release PR treats files identical to main as no-ops', async () => {
  const sideFile = 'scripts/ci/web-bundle-budget.json';
  const budget = '{"maxMainDartJsBytes":1000000,"maxTotalBytes":2000000,"version":1}';
  const { client } = setup({
    files: [...planFileDiff, sideFile],
    extra: {
      ...planFilesRoutes(SNAP_JSON, PLAN_MD),
      [`GET ${R}/contents/${sideFile}?ref=${release.headSha}`]: file(budget),
      [`GET ${R}/contents/${sideFile}?ref=main`]: file(budget),
    },
  });
  const res = await runScopeCheck(client, release);
  assert.deepEqual([res.conclusion, res.title], ['success', 'ok']);
});

const syncResolve = { ...phasePr, headRef: `cursor/${PLAN}-sync-2`, baseRef: INTEGRATION };
const blob = (text, sha) => ({ body: { type: 'file', encoding: 'base64', content: b64(text), sha } });
const atRef = (path, ref) => `GET ${R}/contents/${path.split('/').map(encodeURIComponent).join('/')}?ref=${ref}`;

test('sync-resolve PR treats files merged from main (identical to main) as no-ops', async () => {
  const fromMain = ['.github/workflows/ci.yml', 'scripts/lib/execute_plan_state.js', 'flutter_app/lib/main.dart'];
  const extra = {};
  for (const f of fromMain) {
    extra[atRef(f, syncResolve.headSha)] = blob('same', 'b1');
    extra[atRef(f, 'main')] = blob('same', 'b1');
  }
  extra[atRef('server/bin/server.js', syncResolve.headSha)] = blob('resolved', 'h1');
  extra[atRef('server/bin/server.js', 'main')] = blob('main', 'm1');
  const { client } = setup({ files: [...fromMain, 'server/bin/server.js'], extra });
  const res = await runScopeCheck(client, syncResolve);
  assert.deepEqual([res.conclusion, res.title], ['success', 'ok']);
});

test('sync-resolve PR still fails a protected file that differs from main', async () => {
  const f = 'scripts/lib/execute_plan_state.js';
  const { client } = setup({
    files: [f],
    extra: { [atRef(f, syncResolve.headSha)]: blob('edited', 'h1'), [atRef(f, 'main')]: blob('main', 'm1') },
  });
  const res = await runScopeCheck(client, syncResolve);
  assert.deepEqual([res.conclusion, res.title], ['failure', 'protected']);
  assert.match(res.summary, /execute_plan_state\.js.*protected/);
});

test('phase PR bundle ratchet fails when increase exceeds 1.5% vs merge base', async () => {
  const mergeBase = 'b'.repeat(40);
  const baseBudget = '{"maxMainDartJsBytes":1000000,"maxTotalBytes":2000000,"version":1}';
  const headBudget = '{"maxMainDartJsBytes":2000000,"maxTotalBytes":4000000,"version":1}';
  const comparePath = `${R}/compare/cursor%2F${PLAN}-integration-7f3a...${phasePr.headSha}`;
  const { client } = setup({
    files: ['server/bin/server.js', 'scripts/ci/web-bundle-budget.json'],
    extra: {
      [`GET ${comparePath}`]: {
        body: { merge_base_commit: { sha: mergeBase }, files: [] },
      },
      [`GET ${R}/contents/scripts/ci/web-bundle-budget.json?ref=${mergeBase}`]: file(baseBudget),
      [`GET ${R}/contents/scripts/ci/web-bundle-budget.json?ref=${phasePr.headSha}`]: file(headBudget),
    },
  });
  const res = await runScopeCheck(client, phasePr);
  assert.equal(res.title, 'forbidden');
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

test('stopped plan still evaluates sync-resolve PR', async () => {
  const revoked = { ...CONTROL_ISSUE, labels: [...CONTROL_ISSUE.labels, { name: 'autonomous-revoked' }] };
  const { client } = setup({ issue: revoked, files: ['server/bin/server.js'] });
  const res = await runScopeCheck(client, syncResolve);
  assert.deepEqual([res.conclusion, res.title], ['success', 'ok']);
  assert.equal(res.exemptStopPublish, true);
});

test('sync-resolve while plan running is not exempt from STOP re-check on publish', async () => {
  const { client } = setup({ files: ['server/bin/server.js'] });
  const res = await runScopeCheck(client, syncResolve);
  assert.equal(res.exemptStopPublish, false);
});

test('publish posts only the commit status and never touches check runs', async () => {
  const sha = 'b'.repeat(40);
  const out = { headSha: sha, conclusion: 'success', title: 'ok', summary: 'No violations.\n\nCompanions used (1):', targetUrl: 'https://run/1' };
  const ok = createFakeFetch({ [`POST ${R}/statuses/${sha}`]: { status: 201, body: { id: 7 } } });
  await publishScopeCheck(createGitHubClient({ repo: REPO, token: 't', fetchImpl: ok }), out);
  assert.equal(ok.calls.length, 1);
  assert.deepEqual(ok.calls[0].body, {
    state: 'success', context: 'execute-plan-scope', description: 'ok: No violations.', target_url: 'https://run/1',
  });

  const red = createFakeFetch({ [`POST ${R}/statuses/${sha}`]: { status: 201, body: { id: 8 } } });
  await publishScopeCheck(createGitHubClient({ repo: REPO, token: 't', fetchImpl: red }), {
    headSha: sha, conclusion: 'failure', title: 'plan-stopped', summary: 'plan stopped: revoked',
  });
  assert.equal(red.calls.length, 1);
  assert.deepEqual(red.calls[0].body, { state: 'failure', context: 'execute-plan-scope', description: 'plan-stopped: plan stopped: revoked' });
});

const SHA = phasePr.headSha;
const publishRoutes = {
  [`POST ${R}/statuses/${SHA}`]: { status: 201, body: { id: 9 } },
};
const posted = (fake) => fake.calls.find((c) => c.method === 'POST').body;
const ok = { conclusion: 'success', title: 'ok', summary: 'No violations.', planId: PLAN };

test('publishScopeResult re-checks STOP before posting green: a plan stopped meanwhile posts plan-stopped', async () => {
  const revoked = { ...CONTROL_ISSUE, labels: [...CONTROL_ISSUE.labels, { name: 'autonomous-revoked' }] };
  const { client, fake } = setup({ issue: revoked, extra: publishRoutes });
  const final = await publishScopeResult(client, { headSha: SHA, outcome: ok, now: NOW });
  assert.deepEqual([final.conclusion, final.title], ['failure', 'plan-stopped']);
  assert.equal(posted(fake).state, 'failure');
  assert.match(posted(fake).description, /^plan-stopped: plan stopped: .*revoked/);
});

test('publishScopeResult posts green when the plan is still running', async () => {
  const { client, fake } = setup({ extra: publishRoutes });
  const final = await publishScopeResult(client, { headSha: SHA, outcome: ok, now: NOW });
  assert.equal(final, ok);
  assert.equal(posted(fake).state, 'success');
});

test('publishScopeResult skips STOP re-check for sync-resolve/remedial exempt outcomes', async () => {
  const revoked = { ...CONTROL_ISSUE, labels: [...CONTROL_ISSUE.labels, { name: 'autonomous-revoked' }] };
  const { client, fake } = setup({ issue: revoked, extra: publishRoutes });
  const exempt = { ...ok, exemptStopPublish: true };
  const final = await publishScopeResult(client, { headSha: SHA, outcome: exempt, now: NOW });
  assert.equal(final.conclusion, 'success');
  assert.equal(posted(fake).state, 'success');
});

test('publishScopeResult fails closed when the re-check cannot load the plan', async () => {
  const { client, fake } = setup({ comments: [APPROVE], extra: publishRoutes });
  const final = await publishScopeResult(client, { headSha: SHA, outcome: ok, now: NOW });
  assert.deepEqual([final.conclusion, final.title], ['failure', 'recheck-error']);
  assert.match(posted(fake).description, /^recheck-error: scope check could not confirm the plan state/);
});

test('publishScopeResult skips the re-check for failures and non-plan PRs', async () => {
  for (const outcome of [{ ...ok, conclusion: 'failure', title: 'unclassified' }, { ...ok, planId: null }]) {
    const fake = createFakeFetch(publishRoutes);
    const client = createGitHubClient({ repo: REPO, token: 't', fetchImpl: fake });
    assert.equal(await publishScopeResult(client, { headSha: SHA, outcome, now: NOW }), outcome);
    assert.equal(fake.calls.length, 1);
  }
});

test('check-diff --publish refuses to run outside GitHub Actions', async () => {
  const saved = process.env.GITHUB_ACTIONS;
  delete process.env.GITHUB_ACTIONS;
  try {
    const fake = createFakeFetch({});
    const client = createGitHubClient({ repo: REPO, token: 't', fetchImpl: fake });
    await assert.rejects(cliCheckDiff({ pr: '5', repo: REPO, publish: true }, { client }), /only runs inside GitHub Actions/);
    assert.equal(fake.calls.length, 0);
  } finally {
    if (saved !== undefined) process.env.GITHUB_ACTIONS = saved;
  }
});

test('planIdFromRefs covers every plan branch shape', () => {
  const ref = (head_ref, base_ref = 'main') => planIdFromRefs({ head_ref, base_ref });
  assert.equal(ref(`cursor/${PLAN}-p2`, INTEGRATION), PLAN);
  assert.equal(ref(`cursor/${PLAN}-sync-1`, INTEGRATION), PLAN);
  assert.equal(ref('main', INTEGRATION), PLAN);
  assert.equal(ref(`cursor/${PLAN}-remedial-3`), PLAN);
  assert.equal(ref(INTEGRATION), PLAN);
  assert.equal(ref(`cursor/other-plan-p1`, INTEGRATION), PLAN);
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
