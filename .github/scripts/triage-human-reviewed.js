#!/usr/bin/env node
'use strict';

const { evaluateIssue, buildComment } = require('./triage-lib');
const {
  fetchIssue,
  updateProjectStatus,
  setLabels,
  upsertMarkerComment,
  parseRepo,
} = require('./github-project-lib');

const REQUIRED_ENVS = ['GITHUB_TOKEN', 'GITHUB_REPOSITORY', 'ISSUE_NUMBER'];

async function main() {
  for (const key of REQUIRED_ENVS) {
    if (!process.env[key]) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }

  const { owner, repo } = parseRepo(process.env.GITHUB_REPOSITORY);
  const issueNumber = process.env.ISSUE_NUMBER;
  const token = process.env.GITHUB_TOKEN;
  const projectsPat = process.env.GH_PROJECTS_PAT;
  const projectId = process.env.GH_PROJECT_ID;
  const statusFieldId = process.env.GH_STATUS_FIELD_ID;

  const issue = await fetchIssue(owner, repo, issueNumber, token);
  const labels = issue.labels.nodes.map((node) => node.name);

  const result = evaluateIssue({
    title: issue.title,
    body: issue.body || '',
    labels,
  });

  console.log(JSON.stringify({ issueNumber, ...result }, null, 2));

  const comment = buildComment(result);
  await upsertMarkerComment({
    owner,
    repo,
    issueNumber,
    marker: '<!-- triage-human-reviewed -->',
    body: comment,
    token,
  });

  const labelsToAdd = [];
  const labelsToRemove = new Set(['agent-approved', 'question', 'manual-only', 'blocked']);

  if (result.decision === 'pass') {
    labelsToAdd.push('agent-approved');
    labelsToRemove.delete('agent-approved');
  } else if (result.decision === 'manual-only') {
    labelsToAdd.push('manual-only');
    labelsToRemove.delete('manual-only');
  } else {
    labelsToAdd.push('question');
    labelsToRemove.delete('question');
    labelsToRemove.add('human-reviewed');
  }

  await setLabels(owner, repo, issueNumber, labelsToAdd, [...labelsToRemove], token);

  if (projectsPat && projectId && statusFieldId) {
    const statusName =
      result.decision === 'pass'
        ? 'Ready'
        : result.decision === 'question'
          ? 'Backlog'
          : 'Human Reviewed';

    await updateProjectStatus({
      issue,
      projectId,
      statusFieldId,
      statusName,
      projectsPat,
    });
    console.log(`Project status updated to "${statusName}"`);
  } else {
    console.warn(
      'Skipping project status update: set GH_PROJECTS_PAT, GH_PROJECT_ID, and GH_STATUS_FIELD_ID to enable.',
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
