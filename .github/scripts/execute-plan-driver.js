#!/usr/bin/env node
'use strict';

/**
 * Wrapper for .github/workflows/execute-plan-driver.yml. Runs from trusted `main` code only.
 * Picks the plans an event concerns and runs one driver pass for each (the workflow's single
 * concurrency group serializes passes). Event fields arrive through EVENT_PATH / env, never a shell.
 */

const fs = require('fs');
const { runDriverPass, normalizeKillSwitch } = require('../../scripts/lib/execute_plan_driver_actions');
const { planIdFromRefs, findControlIssue, listActivePlans, labelNames } = require('../../scripts/lib/execute_plan_plans');
const { makeClients } = require('./execute-plan-approve');

const PLAN_LABEL = 'plan:';

/**
 * @returns {Promise<Array<{ planId: string, issueNumber: number }>>}
 * Pull-request-shaped events resolve to the plan of the PR refs; `workflow_run` of CI to the plans of its
 * pull_requests (all active plans when empty); heartbeats and other workflow runs to every active plan.
 */
async function plansForEvent({ eventName, payload, inputPlanId, repo, client }) {
  const active = () => listActivePlans(client);
  const fromRefs = async (refs) => {
    const ids = new Set(refs.map((r) => planIdFromRefs(r)).filter(Boolean));
    return (await active()).filter((p) => ids.has(p.planId));
  };

  if (eventName === 'pull_request' || eventName === 'pull_request_review') {
    const pr = payload.pull_request;
    if (!pr || !pr.head.repo || pr.head.repo.full_name !== repo) return []; // fork PRs are ignored
    return fromRefs([{ head_ref: pr.head.ref, base_ref: pr.base.ref }]);
  }
  if (eventName === 'workflow_run') {
    const run = payload.workflow_run || {};
    if (run.name !== 'CI') return active();
    const prs = run.pull_requests || [];
    if (prs.length === 0) return active();
    return fromRefs(prs.map((pr) => ({ head_ref: pr.head.ref, base_ref: pr.base.ref })));
  }
  if (eventName === 'workflow_dispatch' && inputPlanId) {
    const issue = await findControlIssue(client, inputPlanId);
    return issue ? [{ planId: inputPlanId, issueNumber: issue.number }] : [];
  }
  if (eventName === 'issues') {
    const label = labelNames(payload.issue).find((l) => l.startsWith(PLAN_LABEL) && l !== 'plan:complete');
    if (!label) return [];
    const id = label.slice(PLAN_LABEL.length);
    return (await active()).filter((p) => p.planId === id);
  }
  return active(); // schedule, workflow_dispatch without plan_id
}

async function main(env = process.env) {
  const killSwitch = normalizeKillSwitch(env.EXECUTE_PLAN_DRIVER);
  const lines = [`### Execute-plan driver (EXECUTE_PLAN_DRIVER=${killSwitch}, event ${env.EVENT_NAME})`];
  const log = (line) => {
    console.log(line);
    lines.push(`- ${line}`);
  };
  const flush = () => env.GITHUB_STEP_SUMMARY && fs.appendFileSync(env.GITHUB_STEP_SUMMARY, `${lines.join('\n')}\n`);
  try {
    if (killSwitch === 'off') return log('Kill switch is off: nothing done.');
    const clients = makeClients(env, killSwitch);
    const payload = env.EVENT_PATH ? JSON.parse(fs.readFileSync(env.EVENT_PATH, 'utf8')) : {};
    const plans = await plansForEvent({
      eventName: env.EVENT_NAME,
      payload,
      inputPlanId: (env.INPUT_PLAN_ID || '').trim(),
      repo: env.GITHUB_REPOSITORY,
      client: clients.read,
    });
    if (plans.length === 0) log('No active plan concerned by this event.');
    let failed = false;
    for (const { planId, issueNumber } of plans) {
      try {
        await runDriverPass(clients, { planId, issueNumber, killSwitch, log });
      } catch (e) {
        failed = true;
        log(`plan ${planId}: FAILED — ${e.message}`);
      }
    }
    if (failed) process.exitCode = 1;
  } finally {
    flush();
  }
}

if (require.main === module) {
  main().catch((e) => {
    console.error(`execute-plan-driver: ${e.message}`);
    process.exit(1);
  });
}

module.exports = { main, plansForEvent };
