#!/usr/bin/env node
'use strict';

/**
 * Wrapper for .github/workflows/execute-plan-scope.yml. Runs from trusted `main` code only.
 * Publishes the `execute-plan-scope` check run on the PR head and exits 0 either way;
 * an unexpected error is published as a failing check (fail closed).
 */

const { createGitHubClient } = require('../../scripts/lib/execute_plan_github');
const { runScopeCheck, publishScopeCheck } = require('../../scripts/lib/execute_plan_scope_run');

async function main(env = process.env) {
  const repo = env.GITHUB_REPOSITORY;
  const headSha = env.HEAD_SHA;
  if (!repo || !headSha || !env.PR_NUMBER) throw new Error('GITHUB_REPOSITORY, HEAD_SHA and PR_NUMBER are required');
  const client = createGitHubClient({ repo, token: env.GITHUB_TOKEN });

  let outcome;
  try {
    outcome = await runScopeCheck(client, {
      prNumber: Number(env.PR_NUMBER),
      headSha,
      headRef: env.HEAD_REF,
      baseRef: env.BASE_REF,
      headRepo: env.HEAD_REPO,
      repo,
      now: new Date(),
    });
  } catch (e) {
    outcome = { conclusion: 'failure', title: 'drift', summary: `scope check could not complete: ${e.message}` };
  }
  await publishScopeCheck(client, { headSha, ...outcome });
  console.log(`execute-plan-scope: ${outcome.conclusion} (${outcome.title}) — ${outcome.summary}`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error(`execute-plan-scope: ${e.message}`);
    process.exit(1);
  });
}

module.exports = { main };
