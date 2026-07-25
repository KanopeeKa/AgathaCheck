'use strict';

const { rest } = require('../../.github/scripts/github-project-lib');

const DEPLOY_UAT_WORKFLOW_PATH = '.github/workflows/deploy-uat.yml';
const DEPLOY_JOB_NAME = 'Build and deploy to UAT';

function parseIsoMs(iso) {
  if (!iso) {
    return null;
  }
  const ms = Date.parse(iso);
  return Number.isFinite(ms) ? ms : null;
}

/**
 * Pure cadence decision (unit-testable).
 *
 * @param {object} opts
 * @param {string|null} opts.lastDeployStartedAt ISO timestamp of last deploy job start
 * @param {boolean} opts.deployInProgress
 * @param {number} opts.nowMs
 * @param {number} opts.minIntervalMinutes
 * @param {boolean} opts.enabled
 * @param {boolean} opts.forceRun
 */
function evaluateDeployCadence({
  lastDeployStartedAt,
  deployInProgress = false,
  nowMs,
  minIntervalMinutes,
  enabled = true,
  forceRun = false,
}) {
  const intervalMinutes = Number(minIntervalMinutes);
  const minMs = intervalMinutes * 60 * 1000;

  if (!enabled) {
    return {
      status: 'ok',
      blockReason: '',
      reason: 'cadence_disabled',
      minutesSinceLast: null,
      waitMinutes: 0,
      minIntervalMinutes: intervalMinutes,
    };
  }

  if (forceRun) {
    return {
      status: 'ok',
      blockReason: '',
      reason: 'force_run',
      minutesSinceLast: null,
      waitMinutes: 0,
      minIntervalMinutes: intervalMinutes,
    };
  }

  if (deployInProgress) {
    return {
      status: 'blocked',
      blockReason: 'uat_deploy_in_progress',
      reason: 'deploy_in_progress',
      minutesSinceLast: null,
      waitMinutes: null,
      minIntervalMinutes: intervalMinutes,
    };
  }

  if (!lastDeployStartedAt) {
    return {
      status: 'ok',
      blockReason: '',
      reason: 'no_prior_deploy',
      minutesSinceLast: null,
      waitMinutes: 0,
      minIntervalMinutes: intervalMinutes,
    };
  }

  const startedMs = parseIsoMs(lastDeployStartedAt);
  if (startedMs == null) {
    return {
      status: 'ok',
      blockReason: '',
      reason: 'invalid_last_deploy_timestamp',
      minutesSinceLast: null,
      waitMinutes: 0,
      minIntervalMinutes: intervalMinutes,
    };
  }

  const elapsedMs = Math.max(0, nowMs - startedMs);
  const minutesSinceLast = Math.floor(elapsedMs / 60_000);

  if (elapsedMs >= minMs) {
    return {
      status: 'ok',
      blockReason: '',
      reason: 'cadence_elapsed',
      minutesSinceLast,
      waitMinutes: 0,
      minIntervalMinutes: intervalMinutes,
    };
  }

  const waitMinutes = Math.ceil((minMs - elapsedMs) / 60_000);
  return {
    status: 'blocked',
    blockReason: 'uat_deploy_cadence',
    reason: 'cadence_active',
    minutesSinceLast,
    waitMinutes,
    minIntervalMinutes: intervalMinutes,
  };
}

async function listDeployUatRuns(owner, repo, token, { perPage = 20, maxPages = 3 } = {}) {
  const workflows = await rest('GET', `/repos/${owner}/${repo}/actions/workflows`, token);
  const workflow = (workflows.workflows || []).find((w) => w.path === DEPLOY_UAT_WORKFLOW_PATH);
  if (!workflow) {
    return [];
  }

  const runs = [];
  for (let page = 1; page <= maxPages; page += 1) {
    const data = await rest(
      'GET',
      `/repos/${owner}/${repo}/actions/workflows/${workflow.id}/runs?per_page=${perPage}&page=${page}`,
      token,
    );
    runs.push(...(data.workflow_runs || []));
    if ((data.workflow_runs || []).length < perPage) {
      break;
    }
  }
  return runs;
}

/**
 * Find the most recent deploy-uat run whose deploy job actually started (not skipped).
 */
async function findLastUatDeployJob(owner, repo, token) {
  const runs = await listDeployUatRuns(owner, repo, token);
  for (const run of runs) {
    if (run.status !== 'completed' && run.status !== 'in_progress' && run.status !== 'queued') {
      continue;
    }
    const jobsData = await rest(
      'GET',
      `/repos/${owner}/${repo}/actions/runs/${run.id}/jobs?per_page=50`,
      token,
    );
    const deployJob = (jobsData.jobs || []).find((job) => job.name === DEPLOY_JOB_NAME);
    if (!deployJob || deployJob.conclusion === 'skipped' || !deployJob.started_at) {
      continue;
    }
    return {
      runId: run.id,
      startedAt: deployJob.started_at,
      completedAt: deployJob.completed_at || null,
      inProgress: deployJob.status === 'in_progress' || deployJob.status === 'queued',
      conclusion: deployJob.conclusion,
    };
  }
  return null;
}

function resolveCadenceConfig(env = process.env) {
  const enabled = env.UAT_DEPLOY_CADENCE_ENABLED !== 'false';
  const forceRun = env.UAT_DEPLOY_CADENCE_FORCE === 'true';
  const parsed = Number.parseInt(env.UAT_DEPLOY_MIN_INTERVAL_MINUTES || '90', 10);
  const minIntervalMinutes = Number.isFinite(parsed) && parsed > 0 ? parsed : 90;
  return { enabled, forceRun, minIntervalMinutes };
}

module.exports = {
  DEPLOY_JOB_NAME,
  DEPLOY_UAT_WORKFLOW_PATH,
  evaluateDeployCadence,
  findLastUatDeployJob,
  listDeployUatRuns,
  parseIsoMs,
  resolveCadenceConfig,
};
