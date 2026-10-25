'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');
const {
  DEPLOY_UAT_WORKFLOW_PATH,
  LOG_RETRY_DELAYS_MS,
  validateUatRunRecord,
  assertDispatchProof,
  validateProdDispatch,
} = require('../lib/resolve_prod_dispatch_guard');
const { deployProofJobName } = require('../ci/resolve-prod-dispatch-guard');

const R = '/repos/o/r';
const SHA_A = 'a'.repeat(40);
const SHA_B = 'b'.repeat(40);
const TAG = 'uat-260101-7';
const PROOF_LOG = `2026-01-01T00:00:00Z env:\n2026-01-01T00:00:00Z   DEPLOY_REF: ${TAG}\ngate_failure_class=none\n`;

function routes(overrides = {}) {
  return {
    [`GET ${R}/actions/runs/42`]: { body: { path: DEPLOY_UAT_WORKFLOW_PATH, head_branch: 'main', head_sha: SHA_B } },
    [`GET ${R}/actions/runs/42/jobs?per_page=100`]: {
      body: { jobs: [{ id: 9, name: 'Prod ready', conclusion: 'success' }] },
    },
    [`GET ${R}/actions/jobs/9/logs`]: { body: PROOF_LOG },
    [`GET ${R}/commits/${TAG}`]: { body: { sha: SHA_A } },
    [`GET ${R}/commits/refs/tags/${TAG}`]: { body: { sha: SHA_A } },
    [`GET ${R}/compare/${SHA_A}...main`]: { body: { status: 'ahead', ahead_by: 3, behind_by: 0 } },
    ...overrides,
  };
}

function client(overrides) {
  const fake = createFakeFetch(routes(overrides));
  return { gh: createGitHubClient({ repo: 'o/r', token: 't', fetchImpl: fake, sleep: async () => {} }), fake };
}

const run = (gh, extra = {}) =>
  validateProdDispatch(gh, { uatRunId: '42', dispatchRef: TAG, deployProofJob: 'Prod ready', sleep: async () => {}, ...extra });

test('validateUatRunRecord accepts deploy-uat on main with green Prod ready', () => {
  const r = validateUatRunRecord(
    { path: DEPLOY_UAT_WORKFLOW_PATH, head_branch: 'main', jobs: [{ name: 'Prod ready', conclusion: 'success' }] },
    'Prod ready',
  );
  assert.equal(r.ok, true);
});

test('validateUatRunRecord rejects wrong workflow, non-main branch and red Prod ready', () => {
  const r = validateUatRunRecord(
    { path: '.github/workflows/fake.yml', head_branch: 'cursor/evil', jobs: [{ name: 'Prod ready', conclusion: 'failure' }] },
    'Prod ready',
  );
  assert.equal(r.ok, false);
  assert.match(r.reasons.join(';'), /wrong_workflow/);
  assert.match(r.reasons.join(';'), /head_branch_not_main/);
  assert.match(r.reasons.join(';'), /prod_ready_not_success:failure/);
  assert.deepEqual(validateUatRunRecord(null, 'Prod ready').reasons, ['uat_run_not_found']);
});

test('assertDispatchProof codes', () => {
  const base = { uatRunId: '99', dispatchRef: TAG, requestedCommitSha: SHA_A, deployedCommitSha: SHA_A, commitOnMain: true };
  assert.equal(assertDispatchProof({ ...base, uatRunId: '' }).code, 'uat_run_id_required');
  assert.equal(assertDispatchProof({ ...base, dispatchRef: ' ' }).code, 'dispatch_ref_required');
  assert.equal(assertDispatchProof({ ...base, requestedCommitSha: null }).code, 'requested_commit_unresolved');
  assert.equal(assertDispatchProof({ ...base, deployedCommitSha: null }).code, 'deployed_commit_unresolved');
  assert.equal(assertDispatchProof({ ...base, deployedCommitSha: SHA_B }).code, 'deployed_commit_mismatch');
  assert.equal(assertDispatchProof({ ...base, commitOnMain: false }).code, 'commit_not_on_main');
  assert.deepEqual(assertDispatchProof({ ...base, requestedCommitSha: SHA_A.toUpperCase() }), { ok: true, commitSha: SHA_A });
});

test('validateProdDispatch passes when main has moved past the deployed commit (compare=ahead)', async () => {
  const { gh, fake } = client();
  const r = await run(gh);
  assert.deepEqual(r, { ok: true, commitSha: SHA_A, deployRef: TAG });
  assert.ok(!fake.calls.some((c) => /branches-where-head/.test(c.url)), 'must not use branches-where-head');
});

test('validateProdDispatch reads the deployed ref from the proof log, not head_sha', async () => {
  const { gh } = client({ [`GET ${R}/commits/${SHA_B}`]: { body: { sha: SHA_B } } });
  const r = await run(gh, { dispatchRef: SHA_B });
  assert.equal(r.code, 'deployed_commit_mismatch');
});

test('validateProdDispatch accepts the deployed commit SHA as the dispatch ref', async () => {
  const { gh } = client({ [`GET ${R}/commits/${SHA_A}`]: { body: { sha: SHA_A } } });
  assert.equal((await run(gh, { dispatchRef: SHA_A })).ok, true);
});

test('validateProdDispatch resolves the deployed tag via refs/tags (a same-named branch cannot shadow it)', async () => {
  const { gh } = client({ [`GET ${R}/commits/${TAG}`]: { body: { sha: SHA_B } } });
  assert.equal((await run(gh)).code, 'deployed_commit_mismatch');
});

test('validateProdDispatch refuses a deployed commit that is not on main', async () => {
  for (const cmp of [{ body: { status: 'diverged' } }, { body: { status: 'behind' } }, { status: 404, body: { message: 'x' } }]) {
    const { gh } = client({ [`GET ${R}/compare/${SHA_A}...main`]: cmp });
    assert.equal((await run(gh)).code, 'commit_not_on_main');
  }
});

test('validateProdDispatch refuses bad run id, unknown run and wrong run shape', async () => {
  const { gh } = client({ [`GET ${R}/actions/runs/43`]: { status: 404, body: { message: 'Not Found' } } });
  assert.equal((await run(gh, { uatRunId: '' })).code, 'uat_run_id_required');
  assert.equal((await run(gh, { uatRunId: '42/../1' })).code, 'uat_run_id_required');
  assert.equal((await run(gh, { dispatchRef: '' })).code, 'dispatch_ref_required');
  assert.equal((await run(gh, { dispatchRef: '../../actions/runs/42' })).code, 'dispatch_ref_invalid');
  assert.equal((await run(gh, { dispatchRef: 'uat-1$(id)' })).code, 'dispatch_ref_invalid');
  assert.equal((await run(gh, { uatRunId: '43' })).code, 'uat_run_not_found');
  const other = client({ [`GET ${R}/actions/runs/42`]: { body: { path: '.github/workflows/ci.yml', head_branch: 'main' } } });
  assert.match((await run(other.gh)).code, /wrong_workflow/);
});

test('validateProdDispatch retries a not-yet-available proof log, then fails closed', async () => {
  const later = client({ [`GET ${R}/actions/jobs/9/logs`]: [{ status: 404, body: {} }, { body: PROOF_LOG }] });
  assert.equal((await run(later.gh)).ok, true);
  const never = client({ [`GET ${R}/actions/jobs/9/logs`]: { status: 410, body: {} } });
  assert.equal((await run(never.gh)).code, 'deploy_ref_not_resolved');
  const logCalls = never.fake.calls.filter((c) => /\/logs$/.test(c.url)).length;
  assert.equal(logCalls, LOG_RETRY_DELAYS_MS.length + 1);
  const junk = client({ [`GET ${R}/actions/jobs/9/logs`]: { body: 'DEPLOY_REF: main\n' } });
  assert.equal((await run(junk.gh)).code, 'deploy_ref_not_resolved');
});

test('validateProdDispatch refuses an unresolvable dispatch ref', async () => {
  const { gh } = client({ [`GET ${R}/commits/nope`]: { status: 422, body: { message: 'No commit found' } } });
  assert.equal((await run(gh, { dispatchRef: 'nope' })).code, 'requested_commit_unresolved');
});

test('deployProofJobName reads execute-plan config unless overridden', () => {
  assert.equal(deployProofJobName({}), 'Prod ready');
  assert.equal(deployProofJobName({ DEPLOY_PROOF_JOB: 'Custom' }), 'Custom');
});

test('resolve-prod-trigger.sh refuses missing uat_run_id and unsupported events', () => {
  const script = path.join(__dirname, '..', 'ci', 'resolve-prod-trigger.sh');
  const env = { PATH: process.env.PATH, GITHUB_REPOSITORY: 'o/r', GITHUB_TOKEN: 't' };
  const missing = spawnSync('bash', [script], { env: { ...env, EVENT_NAME: 'workflow_dispatch', DISPATCH_REF: TAG }, encoding: 'utf8' });
  assert.equal(missing.status, 1);
  assert.match(missing.stderr, /uat_run_id is required/);
  const release = spawnSync('bash', [script], { env: { ...env, EVENT_NAME: 'release' }, encoding: 'utf8' });
  assert.equal(release.status, 1);
  assert.match(release.stderr, /Unsupported EVENT_NAME/);
});
