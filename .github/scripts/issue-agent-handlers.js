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

const ASSIGNEE = process.env.AGENT_ASSIGNEE || 'KanopeeKa';

function parseLinkedIssues(prBody) {
  const matches = prBody.match(/\b(?:fixes|closes|resolves)\s+#(\d+)/gi) || [];
  return [...new Set(matches.map((m) => Number(m.replace(/\D/g, ''))))];
}

function uatBranchName(issueNumber) {
  const now = new Date();
  const yy = String(now.getUTCFullYear()).slice(-2);
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  return `release/uat-${yy}${mm}${dd}-issue-${issueNumber}`;
}

async function handleMergedPr({
  owner,
  repo,
  prNumber,
  prTitle,
  prBody,
  mergeSha,
  token,
  projectsPat,
  projectId,
  statusFieldId,
}) {
  const issueNumbers = parseLinkedIssues(prBody || '');
  if (issueNumbers.length === 0) {
    console.log(`PR #${prNumber} has no linked issues — skipping.`);
    return { skipped: true, reason: 'no linked issues' };
  }

  const results = [];
  for (const issueNumber of issueNumbers) {
    const issue = await fetchIssue(owner, repo, issueNumber, token);
    await setLabels(owner, repo, issueNumber, [], ['busy'], token);

    if (projectsPat && projectId && statusFieldId) {
      await updateProjectStatus({
        issue,
        projectId,
        statusFieldId,
        statusName: 'In Main',
        projectsPat,
      });
    }

    const branch = uatBranchName(issueNumber);
    const marker = '<!-- agent-uat-branch -->';
    await upsertMarkerComment({
      owner,
      repo,
      issueNumber,
      marker,
      body: `${marker}
## Merged to main

PR #${prNumber} merged for this issue.

- Merge commit: \`${mergeSha}\`
- UAT branch: \`${branch}\`
- Project status: **In Main**

UAT deployment will start when the release branch is pushed.`,
      token,
    });

    try {
      await rest(
        'POST',
        `/repos/${owner}/${repo}/git/refs`,
        token,
        {
          ref: `refs/heads/${branch}`,
          sha: mergeSha,
        },
      );
    } catch (error) {
      if (String(error.message).includes('422')) {
        await rest(
          'PATCH',
          `/repos/${owner}/${repo}/git/refs/heads/${encodeURIComponent(branch)}`,
          token,
          { sha: mergeSha, force: true },
        );
      } else {
        throw error;
      }
    }

    results.push({ issueNumber, branch, status: 'In Main' });
    console.log(`Issue #${issueNumber}: status In Main, pushed ${branch}`);
  }

  return { results };
}

async function handleUatWorkflowResult({
  owner,
  repo,
  branchName,
  conclusion,
  workflowUrl,
  token,
  projectsPat,
  projectId,
  statusFieldId,
}) {
  const match = branchName.match(/release\/uat-\d{6}-issue-(\d+)/);
  if (!match) {
    return { skipped: true, reason: 'branch not agent UAT format' };
  }

  const issueNumber = Number(match[1]);
  const issue = await fetchIssue(owner, repo, issueNumber, token);

  if (conclusion === 'success') {
    if (projectsPat && projectId && statusFieldId) {
      await updateProjectStatus({
        issue,
        projectId,
        statusFieldId,
        statusName: 'In UAT',
        projectsPat,
      });
    }

    await upsertMarkerComment({
      owner,
      repo,
      issueNumber,
      marker: '<!-- agent-uat-result -->',
      body: `<!-- agent-uat-result -->
## UAT deployment succeeded

Branch \`${branchName}\` deployed successfully.

- Workflow: ${workflowUrl}
- Project status: **In UAT**

Validate on UAT, then move the issue to **Done** when complete.`,
      token,
    });

    return { issueNumber, status: 'In UAT' };
  }

  await setLabels(owner, repo, issueNumber, ['question'], [], token);
  await assignIssue(owner, repo, issueNumber, ASSIGNEE, token);

  await upsertMarkerComment({
    owner,
    repo,
    issueNumber,
    marker: '<!-- agent-uat-result -->',
    body: `<!-- agent-uat-result -->
## UAT deployment failed

Branch \`${branchName}\` deployment did not pass all gates.

- Workflow: ${workflowUrl}
- Conclusion: **${conclusion}**

Assigned @${ASSIGNEE} for investigation. The \`question\` label was added.`,
    token,
  });

  return { issueNumber, status: 'failed', assigned: ASSIGNEE };
}

async function main() {
  const mode = process.env.HANDLER_MODE;
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  if (!mode || !repository || !token) {
    throw new Error('HANDLER_MODE, GITHUB_REPOSITORY, and GITHUB_TOKEN are required');
  }

  const { owner, repo } = parseRepo(repository);
  const projectsPat = process.env.GH_PROJECTS_PAT;
  const projectId = process.env.GH_PROJECT_ID;
  const statusFieldId = process.env.GH_STATUS_FIELD_ID;

  if (mode === 'pr-merged') {
    const result = await handleMergedPr({
      owner,
      repo,
      prNumber: process.env.PR_NUMBER,
      prTitle: process.env.PR_TITLE || '',
      prBody: process.env.PR_BODY || '',
      mergeSha: process.env.MERGE_SHA,
      token,
      projectsPat,
      projectId,
      statusFieldId,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (mode === 'uat-result') {
    const result = await handleUatWorkflowResult({
      owner,
      repo,
      branchName: process.env.BRANCH_NAME,
      conclusion: process.env.WORKFLOW_CONCLUSION,
      workflowUrl: process.env.WORKFLOW_URL,
      token,
      projectsPat,
      projectId,
      statusFieldId,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  throw new Error(`Unknown HANDLER_MODE: ${mode}`);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = {
  parseLinkedIssues,
  uatBranchName,
  handleMergedPr,
  handleUatWorkflowResult,
};
