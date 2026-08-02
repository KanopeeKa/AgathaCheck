#!/usr/bin/env node
'use strict';

/**
 * Collect and wait on automatic PR reviews for /babysit and /babysit-plus.
 *
 *   node scripts/babysit_pr_reviews.js collect --pr <url|num>
 *   node scripts/babysit_pr_reviews.js wait --pr <url|num> [--timeout-min 15] [--interval-sec 45]
 *
 * Policy: docs/agent-efficiency/autonomous-pr-policy.md §Automatic reviews
 */

const { execSync, spawnSync } = require('child_process');
const { parseFlags } = require('./lib/github_issue_workflow_lib');
const {
  assessBugbotStatus,
  assessCopilotStatus,
  buildCollectReport,
  normalizeReviewThreads,
  parsePrRef,
} = require('./lib/babysit_pr_reviews_lib');
const { resolveRepository } = require('./lib/execute_plan_project');

const REVIEW_THREADS_QUERY = `
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 10) {
            nodes {
              author { login }
              body
              path
              line
              url
            }
          }
        }
      }
    }
  }
}`;

function usage() {
  console.error(`Usage:
  node scripts/babysit_pr_reviews.js collect --pr <url|owner/repo#n|n>
  node scripts/babysit_pr_reviews.js wait --pr <url|owner/repo#n|n> [--timeout-min 15] [--interval-sec 45]

Outputs JSON with reviewer status and unresolved review threads (Bugbot, Copilot, human).
Exit 0 when ready for triage; exit 1 on Bugbot timeout or fetch failure.`);
  process.exit(1);
}

function ghJson(args) {
  const result = spawnSync('gh', args, { encoding: 'utf8' });
  if (result.status !== 0) {
    throw new Error(`gh ${args.join(' ')} failed: ${result.stderr || result.stdout}`);
  }
  return JSON.parse(result.stdout || 'null');
}

function resolvePr(flags) {
  const { owner, repo } = resolveRepository();
  return parsePrRef(flags.pr, owner, repo);
}

function fetchReviewSnapshot({ owner, repo, number }) {
  const repoSlug = `${owner}/${repo}`;
  const reviews = ghJson(['api', `repos/${repoSlug}/pulls/${number}/reviews`]);
  const reviewComments = ghJson(['api', `repos/${repoSlug}/pulls/${number}/comments`]);
  const issueComments = ghJson(['api', `repos/${repoSlug}/issues/${number}/comments`]);
  const prView = ghJson([
    'pr',
    'view',
    String(number),
    '--repo',
    repoSlug,
    '--json',
    'reviewRequests,statusCheckRollup',
  ]);

  const graphql = ghJson([
    'api',
    'graphql',
    '-f',
    `query=${REVIEW_THREADS_QUERY}`,
    '-f',
    `owner=${owner}`,
    '-f',
    `repo=${repo}`,
    '-F',
    `number=${number}`,
  ]);
  const threadNodes =
    graphql?.data?.repository?.pullRequest?.reviewThreads?.nodes || [];

  const bugbot = assessBugbotStatus({
    reviews,
    issueComments,
    checkRuns: prView.statusCheckRollup || [],
  });
  const copilot = assessCopilotStatus({
    reviews,
    reviewComments,
    reviewRequests: (prView.reviewRequests || []).map((request) => request.login),
  });
  const threads = normalizeReviewThreads(threadNodes);

  return buildCollectReport({
    prNumber: number,
    bugbot,
    copilot,
    threads,
  });
}

function sleep(seconds) {
  spawnSync('sleep', [String(seconds)], { stdio: 'ignore' });
}

function collect(flags) {
  const pr = resolvePr(flags);
  const report = fetchReviewSnapshot(pr);
  console.log(JSON.stringify(report, null, 2));
  process.exit(0);
}

function wait(flags) {
  const timeoutMin = Number(flags['timeout-min'] || 15);
  const intervalSec = Number(flags['interval-sec'] || 45);
  const deadline = Date.now() + timeoutMin * 60 * 1000;
  const pr = resolvePr(flags);

  let lastReport = null;
  while (true) {
    lastReport = fetchReviewSnapshot(pr);
    if (lastReport.readyForTriage) {
      console.log(JSON.stringify(lastReport, null, 2));
      process.exit(0);
    }
    if (Date.now() >= deadline) {
      const timedOutReport = buildCollectReport({
        prNumber: pr.number,
        bugbot: lastReport.reviewers.bugbot,
        copilot: lastReport.reviewers.copilot,
        threads: lastReport.threads,
        timedOut: true,
      });
      console.log(JSON.stringify(timedOutReport, null, 2));
      process.exit(1);
    }
    sleep(intervalSec);
  }
}

function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  const flags = parseFlags(rest);
  if (!flags.pr) usage();

  try {
    execSync('gh --version', { stdio: 'ignore' });
  } catch {
    console.error('babysit_pr_reviews: gh CLI is required');
    process.exit(1);
  }

  switch (cmd) {
    case 'collect':
      collect(flags);
      break;
    case 'wait':
      wait(flags);
      break;
    default:
      usage();
  }
}

main();
