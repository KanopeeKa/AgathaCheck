#!/usr/bin/env node
'use strict';

/**
 * Collect, wait on and gate automatic PR reviews for /babysit, /babysit-plus and /babysit-uat.
 *
 *   node scripts/babysit_pr_reviews.js collect --pr <url|num>
 *   node scripts/babysit_pr_reviews.js wait --pr <url|num> [--timeout-min 15] [--interval-sec 30]
 *   node scripts/babysit_pr_reviews.js gate --pr <url|num> [--timeout-min 15] [--interval-sec 30]
 *
 * Policy: docs/agent-efficiency/autonomous-pr-policy.md §Automatic reviews
 */

const { execSync, spawnSync } = require('child_process');
const { setTimeout: sleepMs } = require('timers/promises');
const { parseFlags } = require('./lib/github_issue_workflow_lib');
const {
  assessCopilotStatus,
  buildCollectReport,
  normalizeReviewThreads,
  parsePrRef,
} = require('./lib/babysit_pr_reviews_lib');
const { resolveRepository } = require('./lib/execute_plan_project');

const EXIT_TIMEOUT_OR_ERROR = 1;
const EXIT_UNRESOLVED = 2;

const REVIEW_THREADS_QUERY = `
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        pageInfo {
          hasNextPage
        }
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
  node scripts/babysit_pr_reviews.js wait --pr <url|owner/repo#n|n> [--timeout-min 15] [--interval-sec 30]
  node scripts/babysit_pr_reviews.js gate --pr <url|owner/repo#n|n> [--timeout-min 15] [--interval-sec 30]

Outputs JSON with Copilot status and unresolved review threads (Copilot, human).
  collect  one snapshot; exit 0 on success.
  wait     poll until no Copilot review is in progress (readyForTriage); exit 0, or 1 on timeout.
  gate     wait, then exit 0 only when mergeReady (no unresolved threads); 2 when threads remain.
Fetch failures exit 1.`);
  process.exit(EXIT_TIMEOUT_OR_ERROR);
}

function ghJson(args) {
  const result = spawnSync('gh', args, { encoding: 'utf8' });
  if (result.status !== 0) {
    throw new Error(`gh ${args.join(' ')} failed: ${result.stderr || result.stdout}`);
  }
  return JSON.parse(result.stdout || 'null');
}

function ghPaginated(path) {
  return (ghJson(['api', '--paginate', '--slurp', path]) || []).flat();
}

function resolvePr(flags) {
  const { owner, repo } = resolveRepository();
  return parsePrRef(flags.pr, owner, repo);
}

/** REST + reviewThreads GraphQL only: both work with the `repo`-scoped bot token (no `read:org`). */
function fetchReviewSnapshot({ owner, repo, number }, { timedOut = false } = {}) {
  const repoSlug = `${owner}/${repo}`;
  const pull = ghJson(['api', `repos/${repoSlug}/pulls/${number}`]);
  const reviews = ghPaginated(`repos/${repoSlug}/pulls/${number}/reviews`);
  const reviewComments = ghPaginated(`repos/${repoSlug}/pulls/${number}/comments`);

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
  const reviewThreads = graphql?.data?.repository?.pullRequest?.reviewThreads;

  return buildCollectReport({
    prNumber: number,
    copilot: assessCopilotStatus({
      reviews,
      reviewComments,
      requestedReviewers: pull.requested_reviewers || [],
    }),
    threads: normalizeReviewThreads(reviewThreads?.nodes || []),
    truncated: Boolean(reviewThreads?.pageInfo?.hasNextPage),
    timedOut,
  });
}

function parsePositiveInt(value, flagName) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`${flagName} must be a positive number (got ${value})`);
  }
  return parsed;
}

function print(report) {
  console.log(JSON.stringify(report, null, 2));
}

/** Polls until no Copilot review is in progress; returns the last report (timedOut when the deadline passed). */
async function waitForReviews(flags) {
  const timeoutMin = parsePositiveInt(flags['timeout-min'] || 15, '--timeout-min');
  const intervalSec = parsePositiveInt(flags['interval-sec'] || 30, '--interval-sec');
  const deadline = Date.now() + timeoutMin * 60 * 1000;
  const pr = resolvePr(flags);

  while (true) {
    const report = fetchReviewSnapshot(pr);
    if (report.readyForTriage) return report;
    if (Date.now() >= deadline) return fetchReviewSnapshot(pr, { timedOut: true });
    await sleepMs(intervalSec * 1000);
  }
}

async function run(cmd, flags) {
  switch (cmd) {
    case 'collect': {
      print(fetchReviewSnapshot(resolvePr(flags)));
      return 0;
    }
    case 'wait': {
      const report = await waitForReviews(flags);
      print(report);
      return report.readyForTriage ? 0 : EXIT_TIMEOUT_OR_ERROR;
    }
    case 'gate': {
      const report = await waitForReviews(flags);
      print(report);
      if (report.mergeReady) return 0;
      return report.readyForTriage ? EXIT_UNRESOLVED : EXIT_TIMEOUT_OR_ERROR;
    }
    default:
      usage();
      return EXIT_TIMEOUT_OR_ERROR;
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
    process.exit(EXIT_TIMEOUT_OR_ERROR);
  }

  run(cmd, flags)
    .then((code) => process.exit(code))
    .catch((error) => {
      console.error(error.message);
      process.exit(EXIT_TIMEOUT_OR_ERROR);
    });
}

main();
