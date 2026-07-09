#!/usr/bin/env node
'use strict';

const {
  listProjectIssues,
  searchEligibleIssues,
  parseRepo,
  hasLabel,
} = require('./github-project-lib');
const { preflightIssue } = require('./agent-safety-lib');
const { parseRunMarker } = require('./agent-payload-lib');
const { rest } = require('./github-project-lib');

async function issueHasActiveRun(owner, repo, issueNumber, token) {
  const comments = await rest(
    'GET',
    `/repos/${owner}/${repo}/issues/${issueNumber}/comments?per_page=100`,
    token,
  );
  for (const comment of comments) {
    const marker = parseRunMarker(comment.body);
    if (marker && ['running', 'dispatched', 'creating'].includes(marker.status)) {
      return true;
    }
  }
  return false;
}

function normalizeSearchIssue(item) {
  return {
    id: item.node_id,
    number: item.number,
    title: item.title,
    body: item.body,
    url: item.html_url,
    labels: (item.labels || []).map((label) => ({ name: label.name })),
  };
}

async function findEligibleIssues({
  repository,
  token,
  projectsPat,
  projectId,
  statusFieldId,
  requireReadyStatus = true,
}) {
  const { owner, repo } = parseRepo(repository);
  const candidates = [];

  if (projectsPat && projectId && statusFieldId) {
    const projectIssues = await listProjectIssues({
      projectId,
      statusFieldId,
      projectsPat,
    });

    for (const entry of projectIssues) {
      const issue = entry.issue;
      if (entry.status !== 'Ready') continue;
      if (!hasLabel(issue, 'agent-approved')) continue;
      candidates.push(issue);
    }
  } else {
    console.warn('Project secrets missing — falling back to label-only search.');
    const searchResults = await searchEligibleIssues(owner, repo, token);
    for (const item of searchResults) {
      candidates.push(normalizeSearchIssue(item));
    }
  }

  const eligible = [];
  for (const issue of candidates) {
    const labels = issue.labels.nodes.map((n) => n.name);
    const preflight = preflightIssue({ ...issue, labels: labels.map((name) => ({ name })) });
    if (!preflight.ok) {
      console.log(`Skipping #${issue.number}: ${preflight.reason}`);
      continue;
    }

    if (requireReadyStatus && projectsPat && projectId && statusFieldId) {
      // already filtered by Ready
    }

    if (await issueHasActiveRun(owner, repo, issue.number, token)) {
      console.log(`Skipping #${issue.number}: active agent run marker found`);
      continue;
    }

    eligible.push({
      number: issue.number,
      title: issue.title,
      url: issue.url,
    });
  }

  return eligible;
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  if (!repository || !token) {
    throw new Error('GITHUB_REPOSITORY and GITHUB_TOKEN are required');
  }

  const eligible = await findEligibleIssues({
    repository,
    token,
    projectsPat: process.env.GH_PROJECTS_PAT,
    projectId: process.env.GH_PROJECT_ID,
    statusFieldId: process.env.GH_STATUS_FIELD_ID,
  });

  const output = {
    count: eligible.length,
    issues: eligible,
    first: eligible[0] || null,
  };

  console.log(JSON.stringify(output, null, 2));

  if (process.env.GITHUB_OUTPUT) {
    const fs = require('fs');
    fs.appendFileSync(process.env.GITHUB_OUTPUT, `count=${output.count}\n`);
    fs.appendFileSync(
      process.env.GITHUB_OUTPUT,
      `issue_number=${output.first ? output.first.number : ''}\n`,
    );
    fs.appendFileSync(
      process.env.GITHUB_OUTPUT,
      `has_eligible=${output.count > 0}\n`,
    );
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = { findEligibleIssues, issueHasActiveRun };
