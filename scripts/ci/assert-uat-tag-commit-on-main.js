#!/usr/bin/env node
'use strict';

/**
 * Refuse a UAT deploy unless the uat-* tag points at a commit on main.
 *
 * Usage: DEPLOY_REF=<uat-tag> node scripts/ci/assert-uat-tag-commit-on-main.js
 * Requires GITHUB_REPOSITORY and GITHUB_TOKEN.
 */
const { createGitHubClient } = require('../lib/execute_plan_github');
const { checkUatTagOnMain } = require('../lib/main_ancestry');

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  if (!repository || !token) {
    console.error('::error::GITHUB_REPOSITORY and GITHUB_TOKEN are required');
    process.exit(1);
  }
  const client = createGitHubClient({ repo: repository, token });
  const result = await checkUatTagOnMain(client, process.env.DEPLOY_REF || '');
  if (!result.ok) {
    const at = result.commitSha ? ` (${result.commitSha})` : '';
    console.error(`::error::UAT tag '${result.tag}'${at} refused: ${result.code}`);
    process.exit(1);
  }
  console.log(`UAT tag ${result.tag} commit ${result.commitSha} is on main`);
}

main().catch((err) => {
  console.error(`::error::${err.message}`);
  process.exit(1);
});
