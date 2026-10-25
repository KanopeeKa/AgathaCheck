#!/usr/bin/env node
'use strict';

/**
 * CLI for deploy-prod workflow_dispatch guards (called from resolve-prod-trigger.sh).
 * Prints the validated commit SHA on stdout; diagnostics go to stderr.
 *
 * Environment:
 *   GITHUB_REPOSITORY, GITHUB_TOKEN — required
 *   UAT_RUN_ID — deploy-uat run id (required)
 *   DISPATCH_REF — workflow_dispatch ref input
 *   DEPLOY_PROOF_JOB — optional override of uat.deploy_proof_job in .github/execute-plan.config.json
 */
const fs = require('fs');
const path = require('path');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { validateProdDispatch } = require('../lib/resolve_prod_dispatch_guard');

const CONFIG_PATH = path.join(__dirname, '..', '..', '.github', 'execute-plan.config.json');

function deployProofJobName(env = process.env) {
  if (env.DEPLOY_PROOF_JOB) return env.DEPLOY_PROOF_JOB;
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const name = config.uat && config.uat.deploy_proof_job;
  if (!name) throw new Error(`uat.deploy_proof_job missing in ${CONFIG_PATH}`);
  return name;
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  if (!repository || !token) {
    console.error('::error::GITHUB_REPOSITORY and GITHUB_TOKEN are required');
    process.exit(1);
  }
  const client = createGitHubClient({ repo: repository, token });
  const result = await validateProdDispatch(client, {
    uatRunId: process.env.UAT_RUN_ID || '',
    dispatchRef: process.env.DISPATCH_REF || '',
    deployProofJob: deployProofJobName(),
  });
  if (!result.ok) {
    console.error(`::error::deploy-prod dispatch guard failed (${result.code})`);
    process.exit(1);
  }
  console.error(`deploy-prod dispatch guard passed: ${result.deployRef} -> ${result.commitSha} (on main)`);
  process.stdout.write(`${result.commitSha}\n`);
}

if (require.main === module) {
  main().catch((err) => {
    console.error(`::error::${err.message}`);
    process.exit(1);
  });
}

module.exports = { deployProofJobName };
