'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { resolvePromoteCommitSha } = require('./resolve-promote-commit-sha');

const SHA = 'eec1971c46e485e72c772a8e9c009a17a6e8f1e2';
const OTHER = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

test('resolvePromoteCommitSha prefers Pre-UAT log test_sha over trigger head', () => {
  const result = resolvePromoteCommitSha({
    preUatLogTestSha: SHA,
    preUatHeadSha: OTHER,
    runHeadSha: OTHER,
  });
  assert.deepEqual(result, { commitSha: SHA, source: 'pre_uat_run_logs' });
});

test('resolvePromoteCommitSha falls back to Pre-UAT run API head_sha', () => {
  const result = resolvePromoteCommitSha({
    runHeadSha: SHA,
    runConclusion: 'success',
    preUatHeadSha: OTHER,
  });
  assert.deepEqual(result, { commitSha: SHA, source: 'pre_uat_run_api_head_sha' });
});

test('resolvePromoteCommitSha rejects non-success Pre-UAT run', () => {
  assert.throws(
    () =>
      resolvePromoteCommitSha({
        runHeadSha: SHA,
        runConclusion: 'failure',
      }),
    /conclusion is failure/,
  );
});

test('resolvePromoteCommitSha uses workflow_run head_sha when API unavailable', () => {
  const result = resolvePromoteCommitSha({
    preUatHeadSha: SHA,
  });
  assert.deepEqual(result, { commitSha: SHA, source: 'workflow_run_head_sha' });
});

test('resolvePromoteCommitSha uses job output only as last resort', () => {
  const result = resolvePromoteCommitSha({
    jobTestSha: SHA,
  });
  assert.deepEqual(result, {
    commitSha: SHA,
    source: 'resolve_test_commit_job_output',
  });
});

test('resolvePromoteCommitSha returns null when nothing resolvable', () => {
  assert.equal(resolvePromoteCommitSha({}), null);
});
