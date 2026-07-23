#!/usr/bin/env node
'use strict';

/**
 * GitHub issue hygiene for autonomous agents (execute-plan, babysit-plus).
 *
 *   node scripts/github_issue_workflow.js set-status --issue <n> --status "In Progress"
 *   node scripts/github_issue_workflow.js comment --issue <n> --body "..."
 *   node scripts/github_issue_workflow.js start-work --issue <n> --body "..."
 */

const { spawnSync } = require('child_process');
const {
  postIssueComment,
  resolveRepository,
  updateIssueProjectStatus,
} = require('./lib/execute_plan_project');
const { parseFlags, readBody } = require('./lib/github_issue_workflow_lib');

function usage() {
  console.error(`Usage:
  node scripts/github_issue_workflow.js comment --issue <n> [--body text | --body-file path]
  node scripts/github_issue_workflow.js start-work --issue <n> [--body text | --body-file path]
  node scripts/github_issue_workflow.js set-status --issue <n> --status <name>  # CI/Actions only; agents skip

Agents cannot update GitHub Project board status — use comments + the \`busy\` label.
See docs/agent-efficiency/github-labels.md`);
  process.exit(1);
}

function printJson(obj) {
  console.log(JSON.stringify(obj, null, 2));
}

function editIssueLabels(issueNumber, { add = [], remove = [] } = {}) {
  const { owner, repo } = resolveRepository();
  const args = ['issue', 'edit', String(issueNumber), '--repo', `${owner}/${repo}`];
  for (const label of add) args.push('--add-label', label);
  for (const label of remove) args.push('--remove-label', label);
  if (add.length === 0 && remove.length === 0) {
    return { skipped: true, reason: 'no_label_changes' };
  }
  const result = spawnSync('gh', args, { encoding: 'utf8' });
  if (result.status !== 0) {
    throw new Error(
      `gh issue edit failed with exit ${result.status}: ${result.stderr || result.stdout}`
    );
  }
  return { ok: true, issueNumber, added: add, removed: remove };
}

async function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  const flags = parseFlags(rest);
  const issueNumber = Number(flags.issue);
  if (!Number.isInteger(issueNumber) || issueNumber < 1) usage();

  switch (cmd) {
    case 'set-status': {
      if (!flags.status) usage();
      const result = await updateIssueProjectStatus(issueNumber, flags.status);
      printJson(result);
      process.exit(result.ok || result.skipped ? 0 : 1);
    }

    case 'comment': {
      const body = readBody(flags);
      if (!body) usage();
      printJson(postIssueComment(issueNumber, body));
      break;
    }

    case 'start-work': {
      const body = readBody(flags) || 'Work started.';
      const commentResult = postIssueComment(issueNumber, body);
      const labelResult = editIssueLabels(issueNumber, { add: ['busy'] });
      printJson({ comment: commentResult, labels: labelResult });
      break;
    }

    default:
      usage();
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
