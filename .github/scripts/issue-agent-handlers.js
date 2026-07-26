#!/usr/bin/env node
'use strict';

const {
  fetchIssue,
  updateProjectStatus,
  setLabels,
  upsertMarkerComment,
  assignIssue,
  reopenIssue,
  rest,
  parseRepo,
} = require('./github-project-lib');
const { resolveCoordinationIssue } = require('../../scripts/lib/uat_queue_sync');

const ASSIGNEE = process.env.AGENT_ASSIGNEE || 'KanopeeKa';

function parseLinkedIssues(prBody) {
  const matches =
    prBody.match(/\b(?:fixes|closes|resolves|refs)\s+#(\d+)/gi) || [];
  return [...new Set(matches.map((m) => Number(m.replace(/\D/g, ''))))];
}

/** @param {number} prNumber @param {Date} [now] */
function uatTagName(prNumber, now = new Date()) {
  const yy = String(now.getUTCFullYear()).slice(-2);
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  return `uat-${yy}${mm}${dd}-${prNumber}`;
}

/** @param {string} ref Tag or ref name (e.g. uat-260716-193) */
function parseUatTag(ref) {
  const match = String(ref).match(/^uat-(\d{6})-(\d+)$/);
  if (!match) {
    return null;
  }
  return { yymmdd: match[1], prNumber: Number(match[2]) };
}

async function fetchPullRequest(owner, repo, prNumber, token) {
  return rest('GET', `/repos/${owner}/${repo}/pulls/${prNumber}`, token);
}

async function syncEnqueueAfterMergeSafe({
  mergeSha,
  prNumber,
  enqueuedBy,
  token,
}) {
  try {
    const { syncEnqueueAfterMerge } = require('../../scripts/lib/uat_queue_apply');
    return await syncEnqueueAfterMerge({
      mergeSha,
      prNumber: Number(prNumber),
      enqueuedBy,
      token,
    });
  } catch (error) {
    console.warn(`UAT queue enqueue skipped: ${error.message}`);
    return { skipped: true, reason: error.message };
  }
}

async function handleMergedPr({
  owner,
  repo,
  prNumber,
  prBody,
  mergeSha,
  token,
  projectsPat,
  projectId,
  statusFieldId,
}) {
  const issueNumbers = parseLinkedIssues(prBody || '');
  const enqueuedBy =
    issueNumbers.length > 0
      ? `issue-${issueNumbers.join(',')}`
      : `pr-${prNumber}`;
  const queueResult = await syncEnqueueAfterMergeSafe({
    mergeSha,
    prNumber,
    enqueuedBy,
    token,
  });

  if (issueNumbers.length === 0) {
    console.log(
      `PR #${prNumber} has no linked issues — UAT queue enqueue ${queueResult.skipped ? 'skipped' : 'done'}.`,
    );
    return { skipped: true, reason: 'no linked issues', queueSync: queueResult };
  }

  const expectedTag = `uat-YYMMDD-${Number(prNumber)}`;
  const results = [];
  for (const issueNumber of issueNumbers) {
    await fetchIssue(owner, repo, issueNumber, token);
    await setLabels(owner, repo, issueNumber, [], ['busy'], token);
    await reopenIssue(owner, repo, issueNumber, token);

    if (projectsPat && projectId && statusFieldId) {
      const refreshedIssue = await fetchIssue(owner, repo, issueNumber, token);
      await updateProjectStatus({
        issue: refreshedIssue,
        projectId,
        statusFieldId,
        statusName: 'In Main',
        projectsPat,
      });
    }

    await upsertMarkerComment({
      owner,
      repo,
      issueNumber,
      marker: '<!-- agent-uat-branch -->',
      body: `<!-- agent-uat-branch -->
## Merged to main

PR #${prNumber} merged for this issue.

- Merge commit: \`${mergeSha}\`
- Expected UAT tag: \`${expectedTag}\` (created by **Promote UAT** on push to \`main\`)
- Project status: **In Main**
- Issue reopened for UAT tracking (use **Done** after validation; do not rely on auto-close).

UAT deploy runs automatically when the tag is pushed.`,
      token,
    });

    results.push({
      issueNumber,
      expectedTag,
      status: 'In Main',
    });
    console.log(
      `Issue #${issueNumber}: reopened, status In Main, expected UAT tag ${expectedTag}`,
    );
  }

  if (!queueResult.skipped) {
    console.log(
      `UAT queue: enqueued PR #${prNumber} merge ${mergeSha} on issue #${queueResult.issueNumber}`,
    );
  }

  return { results, queueSync: queueResult };
}

async function syncUatQueueDeployResult({
  deployRef,
  conclusion,
  workflowUrl,
  token,
  prNumber,
  gateFailureClass,
  owner,
  repo,
  mergeSha,
}) {
  try {
    const { syncDeployResult } = require('../../scripts/lib/uat_queue_apply');
    const runId = process.env.GITHUB_RUN_ID || '';
    const queueResult = await syncDeployResult({
      deployRef,
      conclusion: conclusion === 'success' ? 'success' : 'failure',
      deployRunId: runId || null,
      gateSummaryRef: workflowUrl,
      gateFailureClass,
      token,
      owner,
      repo,
      mergeSha,
    });
    if (!queueResult.skipped) {
      console.log(
        `UAT queue: updated PR #${prNumber} → ${queueResult.entry.state} on issue #${queueResult.issueNumber}`,
      );
    }
    return queueResult;
  } catch (error) {
    console.warn(`UAT queue deploy sync skipped: ${error.message}`);
    return { skipped: true, reason: error.message };
  }
}

async function postCoordinationIssueUatResult({
  owner,
  repo,
  coordinationIssueNumber,
  deployRef,
  prNumber,
  conclusion,
  workflowUrl,
  gateFailureClass,
  token,
}) {
  if (!coordinationIssueNumber) {
    return { skipped: true, reason: 'coordination_issue_not_configured' };
  }

  const marker = `<!-- agent-uat-result:${deployRef} -->`;

  if (conclusion === 'success') {
    await upsertMarkerComment({
      owner,
      repo,
      issueNumber: coordinationIssueNumber,
      marker,
      body: `${marker}
## UAT deployment succeeded (PR-only merge)

Tag \`${deployRef}\` (PR #${prNumber}) deployed successfully. No product issue was linked on the merge PR.

- Workflow: ${workflowUrl}

Validate on UAT before closing related debt or roadmap items.`,
      token,
    });
    return { posted: true, outcome: 'success' };
  }

  const infraNote =
    gateFailureClass === 'infra_only'
      ? '\n\n**Infra-only failure** (WAF/deploy transport) — queue recorded as `infra_failed`. Workflow retries automatically; CI IP whitelist is not available (see `docs/e2e/uat-waf-queue-lessons.md` §17).'
      : '';

  await upsertMarkerComment({
    owner,
    repo,
    issueNumber: coordinationIssueNumber,
    marker,
    body: `${marker}
## UAT deployment failed (PR-only merge)

Tag \`${deployRef}\` (PR #${prNumber}) did not pass all gates. No product issue was linked on the merge PR — tracking on coordination issue.

- Workflow: ${workflowUrl}
- Conclusion: **${conclusion}**${infraNote}

UAT coordinator may dispatch for code failures; infra WAF blocks require operator action on o2switch Tiger Protect.`,
    token,
  });

  return { posted: true, outcome: 'failure' };
}

async function handleUatWorkflowResult({
  owner,
  repo,
  deployRef,
  conclusion,
  workflowUrl,
  token,
  projectsPat,
  projectId,
  statusFieldId,
  gateFailureClass,
  mergeSha,
}) {
  const parsed = parseUatTag(deployRef);
  if (!parsed) {
    return { skipped: true, reason: 'deploy ref not UAT tag format' };
  }

  const queueSync = await syncUatQueueDeployResult({
    deployRef,
    conclusion,
    workflowUrl,
    token,
    prNumber: parsed.prNumber,
    gateFailureClass,
    owner,
    repo,
    mergeSha,
  });

  const pr = await fetchPullRequest(owner, repo, parsed.prNumber, token);
  const issueNumbers = parseLinkedIssues(pr.body || '');

  if (issueNumbers.length === 0) {
    const coordinationIssueNumber = resolveCoordinationIssue(
      process.env.UAT_COORDINATION_ISSUE,
    );
    const coordinationNote = await postCoordinationIssueUatResult({
      owner,
      repo,
      coordinationIssueNumber,
      deployRef,
      prNumber: parsed.prNumber,
      conclusion,
      workflowUrl,
      gateFailureClass,
      token,
    });
    return {
      skipped: true,
      reason: 'no linked issues',
      prNumber: parsed.prNumber,
      queueSync,
      coordinationNote,
      results: [],
    };
  }

  const results = [];
  for (const issueNumber of issueNumbers) {
    await fetchIssue(owner, repo, issueNumber, token);
    await reopenIssue(owner, repo, issueNumber, token);

    if (conclusion === 'success') {
      if (projectsPat && projectId && statusFieldId) {
        const refreshedIssue = await fetchIssue(owner, repo, issueNumber, token);
        await updateProjectStatus({
          issue: refreshedIssue,
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

Tag \`${deployRef}\` (PR #${parsed.prNumber}) deployed successfully.

- Workflow: ${workflowUrl}
- Project status: **In UAT**

Validate on UAT, then move the issue to **Done** and close when complete.`,
        token,
      });

      results.push({ issueNumber, status: 'In UAT' });
      continue;
    }

    await setLabels(owner, repo, issueNumber, ['question'], ['human-reviewed'], token);
    await assignIssue(owner, repo, issueNumber, ASSIGNEE, token);

    const infraNote =
      gateFailureClass === 'infra_only'
        ? '\n\n**Infra-only failure** (WAF/deploy transport) — queue not frozen; later merges may still promote.'
        : '';

    await upsertMarkerComment({
      owner,
      repo,
      issueNumber,
      marker: '<!-- agent-uat-result -->',
      body: `<!-- agent-uat-result -->
## UAT deployment failed

Tag \`${deployRef}\` (PR #${parsed.prNumber}) deployment did not pass all gates.

- Workflow: ${workflowUrl}
- Conclusion: **${conclusion}**${infraNote}

Assigned @${ASSIGNEE} for investigation. The \`question\` label was added and \`human-reviewed\` was removed to pause the workflow until resolved.`,
      token,
    });

    results.push({ issueNumber, status: 'failed', assigned: ASSIGNEE });
  }

  return { prNumber: parsed.prNumber, results, queueSync };
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
    let mergeSha = process.env.MERGE_SHA || null;
    const runId = process.env.GITHUB_RUN_ID;
    if (!mergeSha && runId) {
      try {
        const run = await rest(
          'GET',
          `/repos/${owner}/${repo}/actions/runs/${runId}`,
          token,
        );
        mergeSha = run.head_sha || null;
      } catch {
        mergeSha = null;
      }
    }

    const result = await handleUatWorkflowResult({
      owner,
      repo,
      deployRef: process.env.BRANCH_NAME || process.env.DEPLOY_REF || '',
      conclusion: process.env.WORKFLOW_CONCLUSION,
      workflowUrl: process.env.WORKFLOW_URL,
      token,
      projectsPat,
      projectId,
      statusFieldId,
      gateFailureClass: process.env.GATE_FAILURE_CLASS || null,
      mergeSha,
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
  uatTagName,
  parseUatTag,
  handleMergedPr,
  handleUatWorkflowResult,
  syncUatQueueDeployResult,
  postCoordinationIssueUatResult,
};
