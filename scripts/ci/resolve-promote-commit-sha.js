'use strict';

/**
 * Resolve the commit SHA to promote after a green Pre-UAT E2E run.
 *
 * GitHub does not expose job `outputs` on the cross-workflow jobs API
 * (`.outputs` is null). Use workflow_run.head_sha (push commit) instead.
 */
function resolvePromoteCommitSha({
  preUatHeadSha,
  runHeadSha,
  runConclusion,
  jobTestSha,
}) {
  if (preUatHeadSha) {
    return { commitSha: preUatHeadSha, source: 'workflow_run_head_sha' };
  }

  if (runHeadSha) {
    if (runConclusion && runConclusion !== 'success') {
      throw new Error(`Pre-UAT run conclusion is ${runConclusion}, expected success`);
    }
    return { commitSha: runHeadSha, source: 'pre_uat_run_api_head_sha' };
  }

  if (jobTestSha) {
    return { commitSha: jobTestSha, source: 'resolve_test_commit_job_output' };
  }

  return null;
}

module.exports = { resolvePromoteCommitSha };
