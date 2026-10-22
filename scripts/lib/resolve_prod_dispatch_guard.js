'use strict';

const { rest } = require('../../.github/scripts/github-project-lib');

const DEPLOY_UAT_WORKFLOW_PATH = '.github/workflows/deploy-uat.yml';

function yymmddFromIso(iso) {
  if (!iso || iso.length < 10) {
    return null;
  }
  return iso.slice(2, 4) + iso.slice(5, 7) + iso.slice(8, 10);
}

async function tagCommitSha(owner, repo, tagName, token) {
  const ref = await rest('GET', `/repos/${owner}/${repo}/git/ref/tags/${tagName}`, token);
  let obj = ref.object;
  if (obj.type === 'tag') {
    const tagObj = await rest('GET', `/repos/${owner}/${repo}/git/tags/${obj.sha}`, token);
    obj = tagObj.object;
  }
  return obj.sha;
}

async function resolvePrForCommit(owner, repo, commitSha, token) {
  const pulls = await rest('GET', `/repos/${owner}/${repo}/commits/${commitSha}/pulls`, token);
  if (!Array.isArray(pulls) || pulls.length !== 1) {
    return null;
  }
  return pulls[0].number;
}

async function resolveUatTagForCommit(owner, repo, commitSha, yymmdd, token) {
  const prNumber = await resolvePrForCommit(owner, repo, commitSha, token);
  if (!prNumber || !yymmdd) {
    return null;
  }
  const tag = `uat-${yymmdd}-${prNumber}`;
  try {
    const tagSha = await tagCommitSha(owner, repo, tag, token);
    if (tagSha === commitSha) {
      return tag;
    }
  } catch {
    return null;
  }
  return null;
}

/** Same resolution path as scripts/lib/uat_deploy_run_resolve.js extractDeployRefFromWorkflowRun. */
async function extractDeployRefFromWorkflowRun(owner, repo, runId, token) {
  const run = await rest('GET', `/repos/${owner}/${repo}/actions/runs/${runId}`, token);
  const commitSha = run.head_sha;
  if (!commitSha) {
    return null;
  }
  if (run.head_branch && /^uat-\d{6}-\d+$/.test(run.head_branch)) {
    return run.head_branch;
  }
  const yymmdd = yymmddFromIso(run.created_at || run.run_started_at);
  const fastTag = await resolveUatTagForCommit(owner, repo, commitSha, yymmdd, token);
  if (fastTag) {
    return fastTag;
  }
  return null;
}

function normalizeSha(sha) {
  return String(sha || '').trim().toLowerCase();
}

/**
 * @param {Array<{ name?: string, conclusion?: string }>} jobs
 */
function prodReadyConclusion(jobs, deployProofJob) {
  const job = (jobs || []).find((j) => j.name === deployProofJob);
  return job ? job.conclusion : null;
}

/**
 * Pure validation of a deploy-uat workflow run record (GitHub API shape).
 */
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
  const prodReady = prodReadyConclusion(run.jobs, deployProofJob);
  if (prodReady !== 'success') {
    reasons.push(`prod_ready_not_success:${prodReady || 'missing'}`);
  }
  return { ok: reasons.length === 0, reasons };
}

function assertDispatchProof({
  uatRunId,
  dispatchRef,
  requestedCommitSha,
  deployedCommitSha,
  commitOnMain,
}) {
  if (!uatRunId || !String(uatRunId).trim()) {
    return { ok: false, code: 'uat_run_id_required' };
  }
  if (!dispatchRef || !String(dispatchRef).trim()) {
    return { ok: false, code: 'dispatch_ref_required' };
  }
  if (!requestedCommitSha) {
    return { ok: false, code: 'requested_commit_unresolved' };
  }
  if (!deployedCommitSha) {
    return { ok: false, code: 'deployed_commit_unresolved' };
  }
  if (normalizeSha(requestedCommitSha) !== normalizeSha(deployedCommitSha)) {
    return {
      ok: false,
      code: 'deployed_commit_mismatch',
      requestedCommitSha,
      deployedCommitSha,
    };
  }
  if (!commitOnMain) {
    return { ok: false, code: 'commit_not_on_main', requestedCommitSha };
  }
  return { ok: true, commitSha: requestedCommitSha };
}

function parseRepo(fullName) {
  const [owner, repo] = String(fullName || '').split('/');
  if (!owner || !repo) {
    throw new Error(`Invalid GITHUB_REPOSITORY: ${fullName}`);
  }
  return { owner, repo };
}

async function resolveRefToCommitSha(owner, repo, ref, token) {
  const cleaned = String(ref).replace(/^refs\/(heads|tags)\//, '');
  const commit = await rest('GET', `/repos/${owner}/${repo}/commits/${cleaned}`, token);
  return commit.sha;
}

async function commitIsOnMainBranch(owner, repo, commitSha, token) {
  const branches = await rest(
    'GET',
    `/repos/${owner}/${repo}/commits/${commitSha}/branches-where-head`,
    token,
  );
  return Array.isArray(branches) && branches.some((b) => b.name === 'main');
}

/**
 * Validate workflow_dispatch promotion inputs against a green deploy-uat run on main.
 */
async function validateProdDispatchFromApi({
  uatRunId,
  dispatchRef,
  requestedCommitSha,
  deployProofJob,
  repository,
  token,
}) {
  const { owner, repo } = parseRepo(repository);
  const run = await rest('GET', `/repos/${owner}/${repo}/actions/runs/${uatRunId}`, token);
  const jobsPayload = await rest(
    'GET',
    `/repos/${owner}/${repo}/actions/runs/${uatRunId}/jobs?per_page=100`,
    token,
  );
  const runWithJobs = { ...run, jobs: jobsPayload.jobs || [] };
  const meta = validateUatRunRecord(runWithJobs, deployProofJob);
  if (!meta.ok) {
    return { ok: false, code: meta.reasons.join(';') };
  }

  const deployRef = await extractDeployRefFromWorkflowRun(owner, repo, uatRunId, token);
  if (!deployRef) {
    return { ok: false, code: 'deploy_ref_not_resolved' };
  }

  const deployedCommitSha = await resolveRefToCommitSha(owner, repo, deployRef, token);
  const commitOnMain = await commitIsOnMainBranch(owner, repo, deployedCommitSha, token);

  return assertDispatchProof({
    uatRunId,
    dispatchRef,
    requestedCommitSha,
    deployedCommitSha,
    commitOnMain,
  });
}

module.exports = {
  DEPLOY_UAT_WORKFLOW_PATH,
  validateUatRunRecord,
  assertDispatchProof,
  validateProdDispatchFromApi,
  resolveRefToCommitSha,
  commitIsOnMainBranch,
  prodReadyConclusion,
};
