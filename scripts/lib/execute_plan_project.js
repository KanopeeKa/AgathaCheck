'use strict';

const { execSync, spawnSync } = require('child_process');
const {
  fetchIssue,
  updateProjectStatus,
  parseRepo,
} = require('../../.github/scripts/github-project-lib');

const STATUS_ALIASES = {
  backlog: 'Backlog',
  'in progress': 'In Progress',
  in_progress: 'In Progress',
  done: 'Done',
};

function normalizeStatusName(status) {
  const key = String(status).trim().toLowerCase();
  return STATUS_ALIASES[key] || status;
}

function resolveRepository() {
  if (process.env.GITHUB_REPOSITORY) {
    return parseRepo(process.env.GITHUB_REPOSITORY);
  }
  try {
    const remote = execSync('gh repo view --json nameWithOwner -q .nameWithOwner', {
      encoding: 'utf8',
    }).trim();
    return parseRepo(remote);
  } catch {
    throw new Error(
      'Could not resolve repository; set GITHUB_REPOSITORY or authenticate gh CLI'
    );
  }
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
  const { owner, repo } = resolveRepository();
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

function closeIssueWithComment(issueNumber, comment) {
  const { owner, repo } = resolveRepository();
  const args = ['issue', 'close', String(issueNumber), '--repo', `${owner}/${repo}`];
  if (comment) {
    args.push('--comment', comment);
  }
  const result = spawnSync('gh', args, { stdio: 'inherit' });
  if (result.status !== 0) {
    throw new Error(`gh issue close failed with exit ${result.status}`);
  }
  return { ok: true, issueNumber, closed: true };
}

module.exports = {
  closeIssueWithComment,
  getProjectConfig,
  normalizeStatusName,
  resolveRepository,
  updateIssueProjectStatus,
};
