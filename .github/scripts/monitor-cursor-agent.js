#!/usr/bin/env node
'use strict';

const {
  fetchIssue,
  updateProjectStatus,
  setLabels,
  upsertMarkerComment,
  assignIssue,
  rest,
  parseRepo,
} = require('./github-project-lib');
const {
  parseRunMarker,
  buildRunMarker,
  buildSuccessComment,
  buildBlockedComment,
} = require('./agent-payload-lib');

const CURSOR_API_BASE = 'https://api.cursor.com';
const ASSIGNEE = process.env.AGENT_ASSIGNEE || 'KanopeeKa';
const RUN_MARKER = '<!-- cursor-agent-run:';

const TERMINAL_STATUSES = new Set(['FINISHED', 'ERROR', 'CANCELLED', 'EXPIRED']);
const RUNNING_STATUSES = new Set(['CREATING', 'RUNNING']);

async function cursorApi(path, apiKey) {
  const response = await fetch(`${CURSOR_API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  const text = await response.text();
  const payload = text ? JSON.parse(text) : {};
  if (!response.ok) {
    throw new Error(`Cursor API GET ${path} failed (${response.status}): ${text}`);
  }
  return payload;
}

async function listOpenIssuesWithBusy(repository, token) {
  const { owner, repo } = parseRepo(repository);
  const q = encodeURIComponent(`repo:${owner}/${repo} is:issue is:open label:busy`);
  const data = await rest('GET', `/search/issues?q=${q}&per_page=30`, token);
  return data.items || [];
}

async function getRunMarkerComment(owner, repo, issueNumber, token) {
  const comments = await rest(
    'GET',
    `/repos/${owner}/${repo}/issues/${issueNumber}/comments?per_page=100`,
    token,
  );
  for (const comment of comments) {
    const marker = parseRunMarker(comment.body);
    if (marker) {
      return { comment, marker };
    }
  }
  return null;
}

function extractPrUrl(run) {
  const branches = run.git?.branches || [];
  for (const branch of branches) {
    if (branch.prUrl) return branch.prUrl;
  }
  return null;
}

function detectBlockedResult(run) {
  const text = (run.result?.text || run.text || '').toLowerCase();
  const blockedPatterns = [
    'cannot proceed',
    'blocked',
    'missing information',
    'underspecified',
    'need more information',
    'unable to reproduce',
    'cannot reproduce',
    'not enough context',
    'please clarify',
  ];
  return blockedPatterns.some((pattern) => text.includes(pattern));
}

async function markBlocked({
  owner,
  repo,
  issueNumber,
  issue,
  marker,
  reason,
  token,
  projectsPat,
  projectId,
  statusFieldId,
}) {
  await setLabels(
    owner,
    repo,
    issueNumber,
    ['blocked', 'question'],
    ['busy', 'human-reviewed'],
    token,
  );
  await assignIssue(owner, repo, issueNumber, ASSIGNEE, token);

  const updatedMarker = {
    ...marker,
    status: 'blocked',
    completedAt: new Date().toISOString(),
    reason,
  };

  await upsertMarkerComment({
    owner,
    repo,
    issueNumber,
    marker: RUN_MARKER,
    body: `${buildRunMarker(updatedMarker)}\n\n${buildBlockedComment({
      reason,
      agentUrl: marker.agentUrl,
    })}`,
    token,
  });

  if (projectsPat && projectId && statusFieldId && issue) {
    await updateProjectStatus({
      issue,
      projectId,
      statusFieldId,
      statusName: 'In Progress',
      projectsPat,
    });
  }
}

async function markSuccess({
  owner,
  repo,
  issueNumber,
  marker,
  prUrl,
  summary,
  token,
}) {
  const updatedMarker = {
    ...marker,
    status: 'completed',
    prUrl,
    completedAt: new Date().toISOString(),
  };

  await upsertMarkerComment({
    owner,
    repo,
    issueNumber,
    marker: RUN_MARKER,
    body: `${buildRunMarker(updatedMarker)}\n\n${buildSuccessComment({
      prUrl,
      summary,
      agentUrl: marker.agentUrl,
    })}`,
    token,
  });
}

async function monitorIssue({
  owner,
  repo,
  issueNumber,
  token,
  apiKey,
  projectsPat,
  projectId,
  statusFieldId,
}) {
  const found = await getRunMarkerComment(owner, repo, issueNumber, token);
  if (!found) return { issueNumber, action: 'skipped', reason: 'no marker' };

  const { marker } = found;
  if (!['running', 'dispatched', 'creating'].includes(marker.status)) {
    return { issueNumber, action: 'skipped', reason: `marker status ${marker.status}` };
  }

  const run = await cursorApi(`/v1/agents/${marker.agentId}/runs/${marker.runId}`, apiKey);
  const status = run.status;

  if (RUNNING_STATUSES.has(status)) {
    return { issueNumber, action: 'running', status };
  }

  if (!TERMINAL_STATUSES.has(status)) {
    return { issueNumber, action: 'unknown', status };
  }

  const issue = await fetchIssue(owner, repo, issueNumber, token);
  const prUrl = extractPrUrl(run);
  const summary = run.result?.text || run.text || '';
  const failed = status === 'ERROR' || status === 'CANCELLED' || status === 'EXPIRED';
  const blocked = failed || (!prUrl && detectBlockedResult(run));

  if (blocked) {
    const reason =
      summary.trim() ||
      (failed ? `Agent run ended with status ${status}` : 'Agent finished without opening a PR');
    await markBlocked({
      owner,
      repo,
      issueNumber,
      issue,
      marker,
      reason,
      token,
      projectsPat,
      projectId,
      statusFieldId,
    });
    return { issueNumber, action: 'blocked', status, reason };
  }

  if (prUrl) {
    await markSuccess({
      owner,
      repo,
      issueNumber,
      marker,
      prUrl,
      summary: summary.slice(0, 500),
      token,
    });
    return { issueNumber, action: 'completed', status, prUrl };
  }

  await markBlocked({
    owner,
    repo,
    issueNumber,
    issue,
    marker,
    reason: 'Agent finished without a PR URL',
    token,
    projectsPat,
    projectId,
    statusFieldId,
  });
  return { issueNumber, action: 'blocked', status, reason: 'no PR URL' };
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  const apiKey = process.env.cursor_api_key || process.env.CURSOR_API_KEY;

  if (!repository || !token) {
    throw new Error('GITHUB_REPOSITORY and GITHUB_TOKEN are required');
  }
  if (!apiKey) {
    throw new Error('cursor_api_key secret is required');
  }

  const { owner, repo } = parseRepo(repository);
  const issueNumber = process.env.ISSUE_NUMBER;

  const projectsPat = process.env.GH_PROJECTS_PAT;
  const projectId = process.env.GH_PROJECT_ID;
  const statusFieldId = process.env.GH_STATUS_FIELD_ID;

  const targets = [];
  if (issueNumber) {
    targets.push(Number(issueNumber));
  } else {
    const busyIssues = await listOpenIssuesWithBusy(repository, token);
    for (const item of busyIssues) {
      targets.push(item.number);
    }
  }

  const results = [];
  for (const number of targets) {
    try {
      const result = await monitorIssue({
        owner,
        repo,
        issueNumber: number,
        token,
        apiKey,
        projectsPat,
        projectId,
        statusFieldId,
      });
      results.push(result);
      console.log(JSON.stringify(result));
    } catch (error) {
      const failure = { issueNumber: number, action: 'error', error: error.message };
      results.push(failure);
      console.error(JSON.stringify(failure));
    }
  }

  console.log(JSON.stringify({ results }, null, 2));
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = { monitorIssue, extractPrUrl, detectBlockedResult };
