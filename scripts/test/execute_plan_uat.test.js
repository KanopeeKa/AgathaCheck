'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');
const { buildBase } = require('./helpers/execute_plan_scenarios');
const { decide } = require('../lib/execute_plan_state');
const {
  classifyDeployFailure, isAppCaused, observeUat, observeUatChain, parseProofJobLog, verifyComplete, watchPreUat,
} = require('../lib/execute_plan_uat');
const { completePlan } = require('../lib/execute_plan_tick');
const { formatStatusComment } = require('../lib/execute_plan_status');

const CONFIG = buildBase().opts.config;
const MERGE = 'd'.repeat(40);
const HEAD = 'e'.repeat(40);
const OLD = 'c'.repeat(40);
const MERGED_AT = '2026-10-17T08:00:00Z';
const SNAP = { plan_id: 'p-1', integration_branch: 'cursor/p-1-integration-x', settings: { tier3_blocking: false } };

// The real `Prod ready` log format (run 38587026601), with GitHub's timestamp prefix.
const REAL_LOG = [
  '2026-10-14T18:01:02.1234567Z ##[group]Run scripts/ci/assert-uat-gates.sh',
  '2026-10-14T18:01:02.2000000Z DEPLOY_REF: uat-261014-1892',
  '2026-10-14T18:01:02.3000000Z gate_failure_class=none',
].join('\n');

test('parseProofJobLog real format', () => {
  assert.deepEqual(parseProofJobLog(REAL_LOG), { deploy_ref: 'uat-261014-1892', gate_failure_class: 'none' });
  assert.equal(parseProofJobLog('gate_failure_class=infra_only').gate_failure_class, 'infra_only');
});

test('parseProofJobLog missing lines → nulls', () => {
  assert.deepEqual(parseProofJobLog('nothing here'), { deploy_ref: null, gate_failure_class: null });
  assert.deepEqual(parseProofJobLog(null), { deploy_ref: null, gate_failure_class: null });
  assert.equal(parseProofJobLog('DEPLOY_REF: main').deploy_ref, null);
});

test('isAppCaused subset rule', () => {
  const c = { failed_jobs: ['shard-3'] };
  assert.equal(isAppCaused(c, null), true);
  assert.equal(isAppCaused(c, { conclusion: 'success', failed_jobs: [] }), true);
  assert.equal(isAppCaused(c, { conclusion: 'failure', failed_jobs: ['shard-3', 'shard-4'] }), false);
  assert.equal(isAppCaused({ failed_jobs: ['shard-3', 'shard-5'] }, { conclusion: 'failure', failed_jobs: ['shard-3'] }), true);
});

test('classify infra/app-smoke/unknown', () => {
  const base = { deploy_job: 'success', smoke_job: 'failure' };
  assert.equal(classifyDeployFailure({ ...base, gate_failure_class: 'infra_only' }), 'infra');
  assert.equal(classifyDeployFailure({ ...base, gate_failure_class: 'code' }), 'app-smoke');
  assert.equal(classifyDeployFailure({ deploy_job: 'failure', smoke_job: 'skipped', gate_failure_class: 'code' }), 'unknown');
  assert.equal(classifyDeployFailure({ ...base, gate_failure_class: null }), 'unknown');
});

const run = (id, head, o = {}) => ({ id, head_sha: head, event: 'push', status: 'completed', conclusion: 'success', created_at: '2026-10-17T08:01:00Z', updated_at: '2026-10-17T09:00:00Z', ...o });
const job = (id, name, conclusion) => ({ id, name, status: 'completed', conclusion });

/** Fake GitHub for one chain; `over` replaces routes. */
function fakeClient(over = {}) {
  const wf = (name, runs) => ({ [`GET /repos/o/r/actions/workflows/${name}/runs?${name === 'pre-uat-e2e.yml' ? 'branch=main&' : ''}per_page=100`]: { body: { workflow_runs: runs } } });
  const routes = {
    ...wf('pre-uat-e2e.yml', [run(501, HEAD, { created_at: '2026-10-17T08:30:00Z' }), run(502, HEAD, { conclusion: 'cancelled', created_at: '2026-10-17T08:10:00Z' }), run(400, OLD, { created_at: '2026-10-16T08:00:00Z', conclusion: 'failure' }), run(401, MERGE, { created_at: '2026-10-17T08:01:00Z' })]),
    [`GET /repos/o/r/compare/${MERGE}...${HEAD}`]: { body: { status: 'ahead' } },
    [`GET /repos/o/r/compare/${MERGE}...${MERGE}`]: { body: { status: 'identical' } },
    [`GET /repos/o/r/compare/${MERGE}...${OLD}`]: { body: { status: 'behind' } },
    [`GET /repos/o/r/compare/${OLD}...${MERGE}`]: { body: { status: 'ahead' } },
    [`GET /repos/o/r/compare/${HEAD}...${MERGE}`]: { body: { status: 'behind' } },
    'GET /repos/o/r/actions/runs/400/jobs?per_page=100': { body: { jobs: [job(1, 'shard-1', 'failure'), job(2, 'Pre-UAT E2E gate', 'failure')] } },
    'GET /repos/o/r/tags?per_page=100': { body: [{ name: 'uat-261017-1960', commit: { sha: HEAD } }, { name: 'uat-261010-1900', commit: { sha: OLD } }, { name: 'v1.0.0', commit: { sha: OLD } }] },
    ...wf('deploy-uat.yml', [{ id: 601, created_at: '2026-10-17T09:12:00Z', status: 'completed', conclusion: 'success' }, { id: 602, created_at: '2026-10-17T09:00:00Z', status: 'completed', conclusion: 'success' }]),
    'GET /repos/o/r/actions/runs/601/jobs?per_page=100': { body: { jobs: [job(11, 'Prod ready', 'success'), job(12, 'Build and deploy to UAT', 'success'), job(13, 'UAT post-deploy smoke', 'success')] } },
    'GET /repos/o/r/actions/runs/602/jobs?per_page=100': { body: { jobs: [job(21, 'Prod ready', 'skipped'), job(22, 'Build and deploy to UAT', 'skipped'), job(23, 'UAT post-deploy smoke', 'skipped')] } },
    'GET /repos/o/r/actions/jobs/11/logs': { body: REAL_LOG.replace('uat-261014-1892', 'uat-261017-1960') },
    ...wf('uat-live-e2e.yml', []),
    ...over,
  };
  const fake = createFakeFetch(routes);
  return { client: createGitHubClient({ repo: 'o/r', token: 't', fetchImpl: fake, sleep: async () => {} }), fake };
}

test('observeUat ignores cancelled runs (fake fetch)', async () => {
  const { client } = fakeClient();
  const uat = await observeUatChain(client, { mergeSha: MERGE, mergedAt: MERGED_AT, source: { kind: 'release', pr: 1960 }, config: CONFIG });
  const cancelled = uat.preuat_runs.find((r) => r.id === 502);
  assert.equal(cancelled.conclusion, 'cancelled');
  const { obs, opts, snapshot } = buildBase({ observations_patch: { uat }, opts: { now: '2026-10-17T12:00:00Z' } });
  // the cancelled run is newer than nothing useful: decision uses run 501 (success, contains merge)
  assert.equal(decide(snapshot, obs, opts).action.kind, 'complete-plan');
});

test('observeUat contains via compare', async () => {
  const { client, fake } = fakeClient();
  const uat = await observeUatChain(client, { mergeSha: MERGE, mergedAt: MERGED_AT, config: CONFIG });
  assert.equal(uat.preuat_runs.find((r) => r.id === 501).contains_merge, true);
  assert.equal(uat.uat_tags.length, 1); // v1.0.0 and the 261010 tag are filtered out
  assert.deepEqual(uat.uat_tags[0], { name: 'uat-261017-1960', commit_sha: HEAD, contains_merge: true });
  assert.ok(fake.calls.some((c) => c.key === `GET /repos/o/r/compare/${MERGE}...${HEAD}`));
  const d = uat.deploy_runs[0];
  assert.deepEqual([d.deploy_ref, d.deploy_ref_contains_merge, d.gate_failure_class], ['uat-261017-1960', true, 'none']);
  assert.equal(uat.deploy_runs.find((r) => r.id === 602).proof_job, 'skipped');
  assert.equal(uat.deploy_runs.find((r) => r.id === 602).deploy_ref, null);
});

test('baseline excludes merge_sha itself', async () => {
  const { client } = fakeClient();
  const uat = await observeUatChain(client, { mergeSha: MERGE, mergedAt: MERGED_AT, config: CONFIG });
  assert.equal(uat.baseline_run.id, 400);
  assert.equal(uat.baseline_run.head_sha, OLD);
  assert.deepEqual(uat.baseline_run.failed_jobs, ['shard-1']); // gate job excluded
});

test('observeUat adapter uses the tick call shape and returns null before any merge', async () => {
  const { client } = fakeClient({ 'GET /repos/o/r/pulls?base=main&per_page=100&state=all': { body: [] } });
  assert.equal(await observeUat(client, { snapshot: SNAP, config: CONFIG }, { release: { pr: null } }, { now: MERGED_AT }), null);
});

const pull = (n, ref, mergedAt, sha) => ({ number: n, head: { ref }, merged_at: mergedAt, merge_commit_sha: sha });

test('remedial merge restarts the stage with the new merge_sha', async () => {
  const NEW = 'f'.repeat(40);
  const { client } = fakeClient({
    'GET /repos/o/r/pulls?base=main&per_page=100&state=all': { body: [
      pull(1960, SNAP.integration_branch, MERGED_AT, MERGE),
      pull(1970, 'cursor/p-1-remedial-1', '2026-10-17T11:00:00Z', NEW),
      pull(1971, 'cursor/p-1-remedial-2', null, null),
    ] },
    [`GET /repos/o/r/compare/${NEW}...${HEAD}`]: { body: { status: 'behind' } },
    [`GET /repos/o/r/compare/${HEAD}...${NEW}`]: { body: { status: 'ahead' } },
    [`GET /repos/o/r/compare/${MERGE}...${NEW}`]: { body: { status: 'ahead' } },
  });
  const uat = await observeUat(client, { snapshot: SNAP, config: CONFIG }, { release: { pr: null } }, { now: '2026-10-17T12:00:00Z' });
  assert.equal(uat.merge_sha, NEW);
  assert.deepEqual(uat.source, { kind: 'remedial', pr: 1970 });
  assert.equal(uat.merged_at, '2026-10-17T11:00:00Z');
  assert.equal(uat.preuat_runs.length, 0); // runs before the remedial merge no longer count
  assert.equal(uat.deploy_runs.length, 0);
});

function stubClient({ preuat = [run(501, HEAD)], tags = [{ name: 'uat-261017-1960', commit_sha: HEAD, contains_merge: true }], deploys } = {}) {
  const writes = [];
  const jobsFor = (proof) => [job(11, 'Prod ready', proof), job(12, 'Build and deploy to UAT', proof), job(13, 'UAT post-deploy smoke', proof)];
  const runs = deploys || [{ id: 601, created_at: '2026-10-17T09:12:00Z', status: 'completed', conclusion: 'success', proof: 'success' }];
  return {
    writes,
    client: {
      repo: 'o/r',
      listPulls: async () => [pull(1960, SNAP.integration_branch, MERGED_AT, MERGE)],
      listWorkflowRuns: async (wf) => (wf === CONFIG.uat.preuat_workflow ? preuat : wf === CONFIG.uat.deploy_workflow ? runs : []),
      compare: async (base, head) => ({ status: head === OLD ? 'behind' : base === head ? 'identical' : 'ahead' }),
      listRunJobs: async (id) => jobsFor((runs.find((r) => r.id === id) || {}).proof),
      listTags: async () => tags.map((t) => ({ name: t.name, commit: { sha: t.commit_sha } })),
      getJobLog: async () => REAL_LOG.replace('uat-261014-1892', 'uat-261017-1960'),
      getFileAtRef: async (path) => ({ content: path.endsWith('config.json') ? JSON.stringify({ ...CONFIG, bot_login: 'bot' }) : '{}', sha: 's' }),
    },
  };
}

test('verifyComplete refuses no-op deploy', async () => {
  const { client } = stubClient({ deploys: [{ id: 602, created_at: '2026-10-17T09:12:00Z', status: 'completed', conclusion: 'success', proof: 'skipped' }] });
  const r = await verifyComplete(client, { snapshot: SNAP, config: CONFIG });
  assert.equal(r.complete, false);
  assert.equal(r.missing, 'deploy-proof');
});

test('verifyComplete reports the first missing condition', async () => {
  const none = await verifyComplete({ ...stubClient().client, listPulls: async () => [] }, { snapshot: SNAP, config: CONFIG });
  assert.equal(none.missing, 'release-merged');
  const red = await verifyComplete(stubClient({ preuat: [run(501, HEAD, { conclusion: 'failure' })] }).client, { snapshot: SNAP, config: CONFIG });
  assert.equal(red.missing, 'preuat-success');
  const noTag = await verifyComplete(stubClient({ tags: [] }).client, { snapshot: SNAP, config: CONFIG });
  assert.equal(noTag.missing, 'uat-tag');
  const ok = await verifyComplete(stubClient().client, { snapshot: SNAP, config: CONFIG });
  assert.equal(ok.complete, true);
  assert.equal(ok.evidence.deploy_ref, 'uat-261017-1960');
});

test('watchPreUat returns on a verdict and times out with timedOut', async () => {
  const sleeps = [];
  const done = await watchPreUat(stubClient().client, { mergeSha: MERGE, config: CONFIG, sleep: async (t) => sleeps.push(t) });
  assert.equal(done.timedOut, false);
  assert.equal(done.run.id, 501);
  const none = await watchPreUat(stubClient({ preuat: [] }).client, { mergeSha: MERGE, config: CONFIG, timeoutMin: 6, pollSec: 120, sleep: async (t) => sleeps.push(t) });
  assert.equal(none.timedOut, true);
  assert.equal(none.run, null);
  assert.deepEqual(sleeps, [120000, 120000]);
});

function completeClient(stub) {
  const body = formatStatusComment({ schema: 1, plan_id: 'p-1', init_sha: 'a'.repeat(40), state: 'complete', dispatched: {}, stop: null }, '');
  const writes = [];
  const client = {
    ...stub.client,
    getIssue: async () => ({ number: 9, labels: [] }),
    listIssueComments: async () => [{ id: 1, user: { login: 'bot' }, created_at: '2026-10-16T09:01:00Z', body }],
    updateComment: async (id) => writes.push(['update', id]),
    createComment: async (n, b) => writes.push(['comment', n, b]),
    addLabels: async (n, l) => writes.push(['label', n, l]),
    closeIssue: async (n) => writes.push(['close', n]),
  };
  return { client, writes };
}

test('complete-plan refuses without deploy and writes nothing', async () => {
  const stub = stubClient({ deploys: [{ id: 602, created_at: '2026-10-17T09:12:00Z', status: 'completed', conclusion: 'success', proof: 'skipped' }] });
  const { client, writes } = completeClient(stub);
  const r = await completeWith(client, SNAP);
  assert.equal(r.complete, false);
  assert.equal(r.missing, 'deploy-proof');
  assert.deepEqual(writes, []);
});

test('complete-plan closes the issue with four evidence links when verified', async () => {
  const { client, writes } = completeClient(stubClient());
  const r = await completeWith(client, SNAP);
  assert.equal(r.complete, true);
  assert.deepEqual(writes.map((w) => w[0]), ['update', 'comment', 'label', 'close']);
  assert.deepEqual(writes[2][2], ['plan:complete']);
  assert.equal((writes[1][2].match(/^- /gm) || []).length, 4);
  const dry = completeClient(stubClient());
  const d = await completeWith(dry.client, SNAP, true);
  assert.equal(d.complete, true);
  assert.deepEqual(dry.writes, []);
});

/** The context `loadPlanContext` would return (its own paths are covered by the tick tests). */
function completeWith(client, snapshot, dryRun = false) {
  const ctx = { config: CONFIG, snapshot, issueNumber: 9, statusComment: { id: 1 }, status: { state: 'release:merged', plan_id: 'p-1' } };
  return completePlan(client, { planId: 'p-1', controlIssue: 9, now: '2026-10-17T12:00:00Z', dryRun, ctx });
}
