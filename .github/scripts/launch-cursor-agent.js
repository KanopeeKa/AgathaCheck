#!/usr/bin/env node
'use strict';

const {
  fetchIssue,
  updateProjectStatus,
  setLabels,
  upsertMarkerComment,
  parseRepo,
} = require('./github-project-lib');
const { preflightIssue } = require('./agent-safety-lib');
const {
  buildAgentPayload,
  buildAgentPrompt,
  buildDispatchComment,
} = require('./agent-payload-lib');

const CURSOR_API_BASE = 'https://api.cursor.com';

async function cursorApi(method, path, apiKey, body) {
  const response = await fetch(`${CURSOR_API_BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await response.text();
  let payload;
  try {
    payload = text ? JSON.parse(text) : {};
  } catch {
    payload = { raw: text };
  }

  if (!response.ok) {
    throw new Error(
      `Cursor API ${method} ${path} failed (${response.status}): ${JSON.stringify(payload)}`,
    );
  }
  return payload;
}

async function launchAgent({ apiKey, repoUrl, promptText, model }) {
  const body = {
    prompt: { text: promptText },
    repos: [{ url: repoUrl, startingRef: 'main' }],
    autoCreatePR: true,
    workOnCurrentBranch: false,
  };

  if (model) {
    body.model = { id: model };
  }

  return cursorApi('POST', '/v1/agents', apiKey, body);
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  const apiKey = process.env.cursor_api_key || process.env.CURSOR_API_KEY;
  const issueNumber = process.env.ISSUE_NUMBER;
  const dryRun = process.env.DRY_RUN === 'true';

  if (!repository || !token || !issueNumber) {
    throw new Error('GITHUB_REPOSITORY, GITHUB_TOKEN, and ISSUE_NUMBER are required');
  }

  if (!apiKey && !dryRun) {
    throw new Error(
      'cursor_api_key secret is required (Cursor dashboard key name: github-actions-pawpet-automation)',
    );
  }

  const { owner, repo } = parseRepo(repository);
  const issue = await fetchIssue(owner, repo, issueNumber, token);
  const labels = issue.labels.nodes.map((node) => node.name);

  const preflight = preflightIssue({
    title: issue.title,
    body: issue.body,
    labels: labels.map((name) => ({ name })),
  });
  if (!preflight.ok) {
    throw new Error(`Issue #${issueNumber} failed preflight: ${preflight.reason}`);
  }

  const repoUrl = `https://github.com/${owner}/${repo}`;
  const payload = buildAgentPayload(
    {
      number: issue.number,
      url: issue.url,
      title: issue.title,
      body: issue.body || '',
      labels,
    },
    repoUrl,
  );
  const promptText = buildAgentPrompt(payload);

  console.log('Sanitized payload:');
  console.log(JSON.stringify(payload, null, 2));

  if (dryRun) {
    console.log('DRY_RUN=true — skipping Cursor API call and GitHub mutations.');
    return;
  }

  await setLabels(owner, repo, issueNumber, ['busy'], [], token);

  const projectsPat = process.env.GH_PROJECTS_PAT;
  const projectId = process.env.GH_PROJECT_ID;
  const statusFieldId = process.env.GH_STATUS_FIELD_ID;
  if (projectsPat && projectId && statusFieldId) {
    await updateProjectStatus({
      issue,
      projectId,
      statusFieldId,
      statusName: 'In Progress',
      projectsPat,
    });
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
    await setLabels(owner, repo, issueNumber, [], ['busy'], token);
    throw new Error(`Cursor API response missing agent/run id: ${JSON.stringify(launched)}`);
  }

  const marker = {
    agentId,
    runId,
    issueNumber: Number(issueNumber),
    status: 'running',
    dispatchedAt: new Date().toISOString(),
    agentUrl,
  };

  await upsertMarkerComment({
    owner,
    repo,
    issueNumber,
    marker: '<!-- cursor-agent-run:',
    body: buildDispatchComment(marker),
    token,
  });

  console.log(JSON.stringify({ launched: marker }, null, 2));
}

main().catch(async (error) => {
  console.error(error);
  process.exit(1);
});

module.exports = { launchAgent };
