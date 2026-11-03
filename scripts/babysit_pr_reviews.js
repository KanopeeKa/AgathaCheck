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
  readReviewThreadPage,
} = require('./lib/babysit_pr_reviews_lib');
const { resolveRepository } = require('./lib/execute_plan_project');

const EXIT_ERROR = 1;
const EXIT_UNRESOLVED = 2;
const EXIT_COPILOT_UNAVAILABLE = 3;
const THREAD_PAGE_CAP = 20;

const REVIEW_THREADS_QUERY = `
query($owner: String!, $repo: String!, $number: Int!, $after: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $after) {
        pageInfo {
          hasNextPage
          endCursor
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
  wait     poll until no Copilot review is in progress; exit 0, or 3 when Copilot is still pending at the timeout.
  gate     wait, then exit 0 when mergeReady; 2 when unresolved threads remain;
           3 when Copilot is still pending at the timeout and nothing is unresolved.
Fetch or GraphQL failures exit 1 — never read them as "no threads".`);
  process.exit(EXIT_ERROR);
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

/** All pages; fails closed past the cap. */
function fetchReviewThreads({ owner, repo, number }) {
  const nodes = [];
  let after = null;
  for (let page = 0; page < THREAD_PAGE_CAP; page += 1) {
    const args = ['api', 'graphql', '-f', `query=${REVIEW_THREADS_QUERY}`, '-f', `owner=${owner}`, '-f', `repo=${repo}`, '-F', `number=${number}`];
    if (after) args.push('-f', `after=${after}`);
    const { nodes: pageNodes, nextCursor } = readReviewThreadPage(ghJson(args), number);
    nodes.push(...pageNodes);
    if (!nextCursor) return nodes;
    after = nextCursor;
  }
  throw new Error(`PR #${number} has more than ${THREAD_PAGE_CAP * 100} review threads; inspect the GitHub UI`);
}

/** REST + reviewThreads GraphQL only: both work with the `repo`-scoped bot token (no `read:org`). */
function fetchReviewSnapshot(pr, { timedOut = false } = {}) {
  const { owner, repo, number } = pr;
  const repoSlug = `${owner}/${repo}`;
  const pull = ghJson(['api', `repos/${repoSlug}/pulls/${number}`]);
  const reviews = ghPaginated(`repos/${repoSlug}/pulls/${number}/reviews`);
  const reviewComments = ghPaginated(`repos/${repoSlug}/pulls/${number}/comments`);

  return buildCollectReport({
    prNumber: number,
    copilot: assessCopilotStatus({
      reviews,
      reviewComments,
      requestedReviewers: pull.requested_reviewers || [],
      createdAt: pull.created_at,
    }),
    threads: normalizeReviewThreads(fetchReviewThreads(pr)),
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
      return report.copilotUnavailable ? EXIT_COPILOT_UNAVAILABLE : 0;
    }
    case 'gate': {
      const report = await waitForReviews(flags);
      print(report);
      if (report.mergeReady) return 0;
      if (report.summary.unresolvedCount > 0) return EXIT_UNRESOLVED;
      return EXIT_COPILOT_UNAVAILABLE;
    }
    default:
      usage();
      return EXIT_ERROR;
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
    process.exit(EXIT_ERROR);
  }

  run(cmd, flags)
    .then((code) => process.exit(code))
    .catch((error) => {
      console.error(error.message);
      process.exit(EXIT_ERROR);
    });
}

main();
