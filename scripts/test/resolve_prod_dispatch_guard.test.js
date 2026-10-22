'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  DEPLOY_UAT_WORKFLOW_PATH,
  validateUatRunRecord,
  assertDispatchProof,
  validateProdDispatchFromApi,
} = require('../lib/resolve_prod_dispatch_guard');

const SHA_A = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const SHA_B = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

test('validateUatRunRecord accepts deploy-uat on main with green Prod ready', () => {
  const result = validateUatRunRecord(
    {
      path: DEPLOY_UAT_WORKFLOW_PATH,
      head_branch: 'main',
      jobs: [{ name: 'Prod ready', conclusion: 'success' }],
    },
    'Prod ready',
  );
  assert.equal(result.ok, true);
});

test('validateUatRunRecord rejects wrong workflow path', () => {
  const result = validateUatRunRecord(
    {
      path: '.github/workflows/fake.yml',
      head_branch: 'main',
      jobs: [{ name: 'Prod ready', conclusion: 'success' }],
    },
    'Prod ready',
  );
  assert.equal(result.ok, false);
  assert.match(result.reasons.join(';'), /wrong_workflow/);
});

test('validateUatRunRecord rejects non-main head_branch', () => {
  const result = validateUatRunRecord(
    {
      path: DEPLOY_UAT_WORKFLOW_PATH,
      head_branch: 'cursor/evil',
      jobs: [{ name: 'Prod ready', conclusion: 'success' }],
    },
    'Prod ready',
  );
  assert.equal(result.ok, false);
  assert.match(result.reasons.join(';'), /head_branch_not_main/);
});

test('validateUatRunRecord rejects Prod ready not success', () => {
  const result = validateUatRunRecord(
    {
      path: DEPLOY_UAT_WORKFLOW_PATH,
      head_branch: 'main',
      jobs: [{ name: 'Prod ready', conclusion: 'failure' }],
    },
    'Prod ready',
  );
  assert.equal(result.ok, false);
  assert.match(result.reasons.join(';'), /prod_ready_not_success/);
});

test('assertDispatchProof requires uat_run_id', () => {
  const result = assertDispatchProof({
    uatRunId: '',
    dispatchRef: 'uat-260101-1',
    requestedCommitSha: SHA_A,
    deployedCommitSha: SHA_A,
    commitOnMain: true,
  });
  assert.equal(result.ok, false);
  assert.equal(result.code, 'uat_run_id_required');
});

test('assertDispatchProof rejects deployed commit mismatch', () => {
  const result = assertDispatchProof({
    uatRunId: '99',
    dispatchRef: 'uat-260101-1',
    requestedCommitSha: SHA_A,
    deployedCommitSha: SHA_B,
    commitOnMain: true,
  });
  assert.equal(result.ok, false);
  assert.equal(result.code, 'deployed_commit_mismatch');
});

test('assertDispatchProof rejects commit not on main', () => {
  const result = assertDispatchProof({
    uatRunId: '99',
    dispatchRef: 'uat-260101-1',
    requestedCommitSha: SHA_A,
    deployedCommitSha: SHA_A,
    commitOnMain: false,
  });
  assert.equal(result.ok, false);
  assert.equal(result.code, 'commit_not_on_main');
});

test('assertDispatchProof happy path', () => {
  const result = assertDispatchProof({
    uatRunId: '99',
    dispatchRef: 'uat-260101-1',
    requestedCommitSha: SHA_A,
    deployedCommitSha: SHA_A,
    commitOnMain: true,
  });
  assert.equal(result.ok, true);
  assert.equal(result.commitSha, SHA_A);
});

test('validateProdDispatchFromApi happy path with mocked API', async () => {
  const deps = {
    uatRunId: '42',
    dispatchRef: 'uat-260101-7',
    requestedCommitSha: SHA_A,
    deployProofJob: 'Prod ready',
    repository: 'o/r',
    token: 't',
  };

  const run = {
    path: DEPLOY_UAT_WORKFLOW_PATH,
    head_branch: 'main',
    head_sha: SHA_A,
    created_at: '2026-01-01T00:00:00Z',
    jobs: [{ name: 'Prod ready', conclusion: 'success' }],
  };

  const guard = require('../lib/resolve_prod_dispatch_guard');
  const api = async (method, path) => {
    if (path === '/repos/o/r/actions/runs/42') return run;
    if (path === '/repos/o/r/actions/runs/42/jobs?per_page=100') return { jobs: run.jobs };
    if (path === '/repos/o/r/commits/uat-260101-7') return { sha: SHA_A };
    if (path === `/repos/o/r/commits/${SHA_A}/branches-where-head`) return [{ name: 'main' }];
    if (path === `/repos/o/r/commits/${SHA_A}/pulls`) return [{ number: 7 }];
    if (path === '/repos/o/r/git/ref/tags/uat-260101-7') {
      return { object: { type: 'commit', sha: SHA_A } };
    }
    throw new Error(`unexpected ${method} ${path}`);
  };

  const prev = global.fetch;
  global.fetch = async (url, init) => {
    const method = init?.method || 'GET';
    const path = url.replace('https://api.github.com', '');
    const data = await api(method, path);
    return {
      ok: true,
      status: 200,
      json: async () => data,
      text: async () => JSON.stringify(data),
    };
  };

  try {
    const result = await guard.validateProdDispatchFromApi(deps);
    assert.equal(result.ok, true);
    assert.equal(result.commitSha, SHA_A);
  } finally {
    global.fetch = prev;
  }
});
