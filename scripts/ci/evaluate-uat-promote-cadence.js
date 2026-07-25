#!/usr/bin/env node
'use strict';

/**
 * Block promote-uat when a UAT deploy started within the cadence window.
 *
 * Environment:
 *   GITHUB_TOKEN — list deploy-uat runs / jobs
 *   GITHUB_REPOSITORY — owner/repo
 *   UAT_DEPLOY_MIN_INTERVAL_MINUTES — default 90
 *   UAT_DEPLOY_CADENCE_ENABLED — default true unless 'false'
 *   UAT_DEPLOY_CADENCE_FORCE — bypass gate when 'true'
 *
 * Outputs to GITHUB_OUTPUT when set:
 *   promotion_status (ok|blocked)
 *   promotion_block_reason
 *   cadence_reason, minutes_since_last_deploy, wait_minutes, min_interval_minutes
 */
const fs = require('fs');
const {
  evaluateDeployCadence,
  findLastUatDeployJob,
  resolveCadenceConfig,
} = require('../lib/uat_deploy_cadence');

function emitOutput(key, value) {
  const line = `${key}=${value}\n`;
  if (process.env.GITHUB_OUTPUT) {
    fs.appendFileSync(process.env.GITHUB_OUTPUT, line);
  }
  process.stdout.write(line);
}

function parseRepository(repository) {
  const [owner, repo] = (repository || '').split('/');
  if (!owner || !repo) {
    throw new Error(`Invalid GITHUB_REPOSITORY: ${repository}`);
  }
  return { owner, repo };
}

async function main() {
  const { enabled, forceRun, minIntervalMinutes } = resolveCadenceConfig();
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  const { owner, repo } = parseRepository(process.env.GITHUB_REPOSITORY);

  emitOutput('min_interval_minutes', String(minIntervalMinutes));

  if (!enabled) {
    emitOutput('promotion_status', 'ok');
    emitOutput('promotion_block_reason', '');
    emitOutput('cadence_reason', 'cadence_disabled');
    console.log('UAT deploy cadence disabled (UAT_DEPLOY_CADENCE_ENABLED=false)');
    return;
  }

  if (forceRun) {
    emitOutput('promotion_status', 'ok');
    emitOutput('promotion_block_reason', '');
    emitOutput('cadence_reason', 'force_run');
    console.log('UAT deploy cadence bypassed (UAT_DEPLOY_CADENCE_FORCE=true)');
    return;
  }

  if (!token) {
    throw new Error('GITHUB_TOKEN is required to evaluate UAT deploy cadence');
  }

  const lastDeploy = await findLastUatDeployJob(owner, repo, token);
  const decision = evaluateDeployCadence({
    lastDeployStartedAt: lastDeploy?.startedAt || null,
    deployInProgress: Boolean(lastDeploy?.inProgress),
    nowMs: Date.now(),
    minIntervalMinutes,
    enabled: true,
    forceRun: false,
  });

  emitOutput('cadence_reason', decision.reason);
  if (decision.minutesSinceLast != null) {
    emitOutput('minutes_since_last_deploy', String(decision.minutesSinceLast));
  }
  if (decision.waitMinutes != null) {
    emitOutput('wait_minutes', String(decision.waitMinutes));
  }
  if (lastDeploy?.runId) {
    emitOutput('last_deploy_run_id', String(lastDeploy.runId));
  }

  if (decision.status === 'blocked') {
    const detail = lastDeploy
      ? `last_deploy_started=${lastDeploy.startedAt} wait_minutes=${decision.waitMinutes ?? 'n/a'}`
      : 'deploy_in_progress';
    console.error(`::warning::UAT deploy cadence active (${decision.blockReason}) — ${detail}`);
    emitOutput('promotion_status', 'blocked');
    emitOutput('promotion_block_reason', decision.blockReason);
    return;
  }

  emitOutput('promotion_status', 'ok');
  emitOutput('promotion_block_reason', '');
  console.log(
    `UAT deploy cadence clear — ${decision.reason}`
    + (decision.minutesSinceLast != null ? ` (${decision.minutesSinceLast}m since last deploy)` : ''),
  );
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = { main };
