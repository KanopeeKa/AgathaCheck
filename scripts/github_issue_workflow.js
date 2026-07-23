#!/usr/bin/env node
'use strict';

/**
 * GitHub issue hygiene for autonomous agents (execute-plan, babysit-plus).
 *
 *   node scripts/github_issue_workflow.js set-status --issue <n> --status "In Progress"
 *   node scripts/github_issue_workflow.js comment --issue <n> --body "..."
 *   node scripts/github_issue_workflow.js start-work --issue <n> --body "..."
 */

const fs = require('fs');
const {
  postIssueComment,
  updateIssueProjectStatus,
} = require('./lib/execute_plan_project');

function usage() {
  console.error(`Usage:
  node scripts/github_issue_workflow.js set-status --issue <n> --status <name>
  node scripts/github_issue_workflow.js comment --issue <n> [--body text | --body-file path]
  node scripts/github_issue_workflow.js start-work --issue <n> [--body text | --body-file path]

Project status requires GH_PROJECTS_PAT, GH_PROJECT_ID, GH_STATUS_FIELD_ID.
See docs/github-issue-workflow.md`);
  process.exit(1);
}

function parseFlags(argv) {
  const flags = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith('--')) continue;
    const key = arg.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith('--')) {
      flags[key] = next;
      i += 1;
    } else {
      flags[key] = true;
    }
  }
  return flags;
}

function readBody(flags) {
  if (flags.body) return flags.body;
  if (flags['body-file']) return fs.readFileSync(flags['body-file'], 'utf8');
  return null;
}

function printJson(obj) {
  console.log(JSON.stringify(obj, null, 2));
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
      const statusResult = await updateIssueProjectStatus(issueNumber, 'In Progress');
      const body = readBody(flags) || 'Work started.';
      const commentResult = postIssueComment(issueNumber, body);
      printJson({ status: statusResult, comment: commentResult });
      process.exit(statusResult.ok || statusResult.skipped ? 0 : 1);
    }

    default:
      usage();
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
