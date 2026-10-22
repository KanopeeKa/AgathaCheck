#!/usr/bin/env node
'use strict';

/**
 * CLI for deploy-prod workflow_dispatch guards (called from resolve-prod-trigger.sh).
 *
 * Environment:
 *   GITHUB_REPOSITORY, GITHUB_TOKEN — required
 *   UAT_RUN_ID — deploy-uat run id (required)
 *   DISPATCH_REF — workflow_dispatch ref input
 *   REQUESTED_COMMIT_SHA — resolved SHA for DISPATCH_REF
 *   DEPLOY_PROOF_JOB — job name (default: Prod ready)
 */
const { validateProdDispatchFromApi } = require('../lib/resolve_prod_dispatch_guard');

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  const uatRunId = process.env.UAT_RUN_ID || '';
  const dispatchRef = process.env.DISPATCH_REF || '';
  const requestedCommitSha = process.env.REQUESTED_COMMIT_SHA || '';
  const deployProofJob = process.env.DEPLOY_PROOF_JOB || 'Prod ready';

  if (!repository || !token) {
    console.error('::error::GITHUB_REPOSITORY and GITHUB_TOKEN are required');
    process.exit(1);
  }

  const result = await validateProdDispatchFromApi({
    uatRunId,
    dispatchRef,
    requestedCommitSha,
    deployProofJob,
    repository,
    token,
  });

  if (!result.ok) {
    console.error(`::error::deploy-prod dispatch guard failed (${result.code})`);
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch((err) => {
    console.error(`::error::${err.message}`);
    process.exit(1);
  });
}
