#!/usr/bin/env node
'use strict';

const { launchAgent } = require('./launch-cursor-agent');
const { upsertMarkerComment, parseRepo } = require('./github-project-lib');
const { buildUatCoordinatorPrompt } = require('../../scripts/lib/uat_coordinator_payload');

const COORDINATOR_MARKER = '<!-- uat-coordinator-run:';

function buildDispatchComment(marker) {
  return `${COORDINATOR_MARKER}${marker.agentId} -->
## UAT coordinator dispatched

- Agent: ${marker.agentUrl || marker.agentId}
- PR: #${marker.prNumber ?? 'unknown'}
- Workflow run: ${marker.workflowRunId}
- Dispatched: ${marker.dispatchedAt}
`;
}

async function launchUatCoordinator({
  token,
  apiKey,
  owner,
  repo,
  coordinationIssueNumber,
  coordinationIssueUrl,
  payload,
  dryRun = false,
}) {
  const repoUrl = `https://github.com/${owner}/${repo}`;
  const promptText = buildUatCoordinatorPrompt(payload);

  console.log('UAT coordinator payload:');
  console.log(JSON.stringify(payload, null, 2));

  if (dryRun) {
    console.log('DRY_RUN=true — skipping Cursor API call.');
    return { dry_run: true, payload };
  }

  if (!apiKey) {
    throw new Error('cursor_api_key secret is required to launch UAT coordinator');
  }

  const model = process.env.CURSOR_AGENT_MODEL || undefined;
  const launched = await launchAgent({
    apiKey,
    repoUrl,
    promptText,
    model,
  });

  const agentId = launched.agent?.id;
  const runId = launched.run?.id;
  const agentUrl = launched.agent?.url;
  if (!agentId || !runId) {
    throw new Error(`Cursor API response missing agent/run id: ${JSON.stringify(launched)}`);
  }

  const marker = {
    agentId,
    runId,
    issueNumber: coordinationIssueNumber,
    prNumber: payload.failure.pr_number,
    workflowRunId: payload.failure.workflow_run_id,
    status: 'running',
    dispatchedAt: new Date().toISOString(),
    agentUrl,
  };

  await upsertMarkerComment({
    owner,
    repo,
    issueNumber: coordinationIssueNumber,
    marker: COORDINATOR_MARKER,
    body: buildDispatchComment(marker),
    token,
  });

  return { launched: marker, payload };
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  const apiKey = process.env.cursor_api_key || process.env.CURSOR_API_KEY;
  const dryRun = process.env.DRY_RUN === 'true';

  if (!repository || !token) {
    throw new Error('GITHUB_REPOSITORY and GITHUB_TOKEN are required');
  }

  const payload = JSON.parse(process.env.UAT_COORDINATOR_PAYLOAD || 'null');
  if (!payload) {
    throw new Error('UAT_COORDINATOR_PAYLOAD env JSON is required');
  }

  const { owner, repo } = parseRepo(repository);
  const issueNumber = Number(process.env.UAT_COORDINATION_ISSUE);
  const issueUrl = process.env.UAT_COORDINATION_ISSUE_URL
    || `https://github.com/${owner}/${repo}/issues/${issueNumber}`;

  const result = await launchUatCoordinator({
    token,
    apiKey,
    owner,
    repo,
    coordinationIssueNumber: issueNumber,
    coordinationIssueUrl: issueUrl,
    payload,
    dryRun,
  });

  console.log(JSON.stringify(result, null, 2));
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = {
  launchUatCoordinator,
  buildDispatchComment,
  COORDINATOR_MARKER,
};
