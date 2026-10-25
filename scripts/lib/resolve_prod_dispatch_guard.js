'use strict';

/**
 * deploy-prod workflow_dispatch proof: the requested ref must be the commit a green deploy-uat
 * run on main actually deployed, and that commit must be on main.
 *
 * The deployed ref is read from the proof job log (`DEPLOY_REF: uat-…` env echo, the same
 * source execute-plan uses), not inferred from the run's head_sha: workflow_run and
 * workflow_dispatch runs carry main's head at trigger time, not the tag commit.
 */

const { parseProofJobLog } = require('./execute_plan_uat_observe');
const { UAT_TAG, stripRefPrefix, commitIsOnMain } = require('./main_ancestry');

const DEPLOY_UAT_WORKFLOW_PATH = '.github/workflows/deploy-uat.yml';
const LOG_RETRY_DELAYS_MS = [5000, 10000, 20000];

function normalizeSha(sha) {
  return String(sha || '').trim().toLowerCase();
}

function findJob(jobs, name) {
  return (jobs || []).find((j) => j.name === name) || null;
}

/** Pure validation of a deploy-uat workflow run record (GitHub API shape plus `jobs`). */
function validateUatRunRecord(run, deployProofJob) {
  const reasons = [];
  if (!run || typeof run !== 'object') {
    return { ok: false, reasons: ['uat_run_not_found'] };
  }
  const workflowPath = run.path || '';
  if (workflowPath !== DEPLOY_UAT_WORKFLOW_PATH) {
    reasons.push(`wrong_workflow:${workflowPath || '<missing>'}`);
  }
  if ((run.head_branch || '') !== 'main') {
    reasons.push(`head_branch_not_main:${run.head_branch || '<missing>'}`);
  }
  const proof = findJob(run.jobs, deployProofJob);
  const conclusion = proof ? proof.conclusion : null;
  if (conclusion !== 'success') {
    reasons.push(`prod_ready_not_success:${conclusion || 'missing'}`);
  }
  return { ok: reasons.length === 0, reasons };
}

function assertDispatchProof({ uatRunId, dispatchRef, requestedCommitSha, deployedCommitSha, commitOnMain }) {
  if (!uatRunId || !String(uatRunId).trim()) return { ok: false, code: 'uat_run_id_required' };
  if (!dispatchRef || !String(dispatchRef).trim()) return { ok: false, code: 'dispatch_ref_required' };
  if (!requestedCommitSha) return { ok: false, code: 'requested_commit_unresolved' };
  if (!deployedCommitSha) return { ok: false, code: 'deployed_commit_unresolved' };
  if (normalizeSha(requestedCommitSha) !== normalizeSha(deployedCommitSha)) {
    return { ok: false, code: 'deployed_commit_mismatch', requestedCommitSha, deployedCommitSha };
  }
  if (!commitOnMain) return { ok: false, code: 'commit_not_on_main', requestedCommitSha };
  return { ok: true, commitSha: normalizeSha(requestedCommitSha) };
}

/** The proof job log can 404 for a few seconds after the job completes. */
async function readProofLog(client, jobId, sleep) {
  for (let attempt = 0; ; attempt += 1) {
    try {
      return await client.getJobLog(jobId);
    } catch (e) {
      const missing = e && (e.status === 404 || e.status === 410);
      if (!missing) throw e;
      if (attempt >= LOG_RETRY_DELAYS_MS.length) return null;
      await sleep(LOG_RETRY_DELAYS_MS[attempt]);
    }
  }
}

async function resolveCommitOrNull(client, ref) {
  try {
    return await client.getCommitSha(ref);
  } catch (e) {
    if (e && (e.status === 404 || e.status === 422)) return null;
    throw e;
  }
}

/**
 * @param {object} client createGitHubClient() result
 * @returns {Promise<{ ok: boolean, code?: string, commitSha?: string, deployRef?: string }>}
 */
async function validateProdDispatch(client, { uatRunId, dispatchRef, deployProofJob, sleep }) {
  const wait = sleep || ((ms) => new Promise((r) => setTimeout(r, ms)));
  const runId = String(uatRunId || '').trim();
  const ref = stripRefPrefix(dispatchRef);
  if (!/^\d+$/.test(runId)) return { ok: false, code: 'uat_run_id_required' };
  if (!ref) return { ok: false, code: 'dispatch_ref_required' };

  let run;
  try {
    run = await client.getWorkflowRun(runId);
  } catch (e) {
    if (e && e.status === 404) return { ok: false, code: 'uat_run_not_found' };
    throw e;
  }
  const jobs = await client.listRunJobs(runId);
  const meta = validateUatRunRecord({ ...run, jobs }, deployProofJob);
  if (!meta.ok) return { ok: false, code: meta.reasons.join(';') };

  const log = await readProofLog(client, findJob(jobs, deployProofJob).id, wait);
  const { deploy_ref: deployRef } = parseProofJobLog(log);
  if (!deployRef || !UAT_TAG.test(deployRef)) return { ok: false, code: 'deploy_ref_not_resolved' };

  const requestedCommitSha = await resolveCommitOrNull(client, ref);
  const deployedCommitSha = await resolveCommitOrNull(client, `refs/tags/${deployRef}`);
  const commitOnMain = deployedCommitSha ? await commitIsOnMain(client, deployedCommitSha) : false;
  const result = assertDispatchProof({
    uatRunId: runId,
    dispatchRef: ref,
    requestedCommitSha,
    deployedCommitSha,
    commitOnMain,
  });
  return result.ok ? { ...result, deployRef } : result;
}

module.exports = {
  DEPLOY_UAT_WORKFLOW_PATH,
  LOG_RETRY_DELAYS_MS,
  validateUatRunRecord,
  assertDispatchProof,
  validateProdDispatch,
};
