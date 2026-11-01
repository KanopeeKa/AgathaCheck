'use strict';

const { execSync } = require('child_process');
const {
  fetchIssue,
  updateProjectStatus,
  parseRepo,
} = require('../../.github/scripts/github-project-lib');
const { createGitHubClient } = require('./execute_plan_github');

const STATUS_ALIASES = {
  backlog: 'Backlog',
  'in progress': 'In Progress',
  in_progress: 'In Progress',
  done: 'Done',
};

function normalizeStatusName(status) {
  const normalized = String(status).trim();
  const key = normalized.toLowerCase();
  return STATUS_ALIASES[key] || normalized;
}

function resolveRepository() {
  if (process.env.GITHUB_REPOSITORY) {
    return parseRepo(process.env.GITHUB_REPOSITORY);
  }
  try {
    const remote = execSync('git remote get-url origin', { encoding: 'utf8' }).trim();
    const m = /github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?$/.exec(remote);
    if (m) return parseRepo(m[1]);
  } catch {
    /* fall through */
  }
  throw new Error('Could not resolve repository; set GITHUB_REPOSITORY');
}

function makeClient() {
  const { owner, repo } = resolveRepository();
  return createGitHubClient({ repo: `${owner}/${repo}` });
}

function getProjectConfig() {
  const projectsPat = process.env.GH_PROJECTS_PAT;
  const projectId = process.env.GH_PROJECT_ID;
  const statusFieldId = process.env.GH_STATUS_FIELD_ID;
  if (!projectsPat || !projectId || !statusFieldId) return null;
  return { projectsPat, projectId, statusFieldId };
}

async function updateIssueProjectStatus(issueNumber, statusName) {
  const status = normalizeStatusName(statusName);
  const config = getProjectConfig();

  if (!config) {
    return {
      ok: false,
      skipped: true,
      reason: 'project_secrets_missing',
      issueNumber,
      status,
      message:
        'Set GH_PROJECTS_PAT, GH_PROJECT_ID, and GH_STATUS_FIELD_ID to enable project status updates.',
    };
  }

  const { owner, repo } = resolveRepository();
  const issue = await fetchIssue(owner, repo, issueNumber, config.projectsPat);
  await updateProjectStatus({
    issue,
    projectId: config.projectId,
    statusFieldId: config.statusFieldId,
    statusName: status,
    projectsPat: config.projectsPat,
  });

  return { ok: true, issueNumber, status };
}

async function closeIssueWithComment(issueNumber, comment) {
  const client = makeClient();
  if (comment) {
    await client.createComment(issueNumber, comment);
  }
  await client.closeIssue(issueNumber);
  return { ok: true, issueNumber, closed: true };
}

async function postIssueComment(issueNumber, comment) {
  const client = makeClient();
  await client.createComment(issueNumber, comment);
  return { ok: true, issueNumber };
}

module.exports = {
  closeIssueWithComment,
  getProjectConfig,
  normalizeStatusName,
  postIssueComment,
  resolveRepository,
  updateIssueProjectStatus,
};
