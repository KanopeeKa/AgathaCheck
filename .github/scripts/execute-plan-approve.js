#!/usr/bin/env node
'use strict';

/**
 * Wrapper for .github/workflows/execute-plan-approve.yml. Runs from trusted `main` code only.
 * The event payload is read from EVENT_PATH and parsed; no third-party field is ever interpolated into a shell.
 */

const fs = require('fs');
const { createGitHubClient } = require('../../scripts/lib/execute_plan_github');
const { handleControlComment } = require('../../scripts/lib/execute_plan_approve');
const { normalizeKillSwitch } = require('../../scripts/lib/execute_plan_driver_actions');

function summaryWriter(env) {
  return (line) => {
    console.log(line);
    if (env.GITHUB_STEP_SUMMARY) fs.appendFileSync(env.GITHUB_STEP_SUMMARY, `${line}\n`);
  };
}

/** Bot client for writes; in dry-run it may fall back to the read token so the secret is not needed yet. */
function makeClients(env, killSwitch) {
  const repo = env.GITHUB_REPOSITORY;
  const read = createGitHubClient({ repo, token: env.GITHUB_TOKEN });
  const botToken = env.EXECUTE_PLAN_BOT_TOKEN || (killSwitch === 'dry-run' ? env.GITHUB_TOKEN : null);
  if (!botToken) throw new Error('EXECUTE_PLAN_BOT_TOKEN is not set');
  return { bot: createGitHubClient({ repo, token: botToken }), read, cursorApiKey: env.CURSOR_API_KEY || null, botToken: env.EXECUTE_PLAN_BOT_TOKEN || null };
}

async function main(env = process.env) {
  const killSwitch = normalizeKillSwitch(env.EXECUTE_PLAN_DRIVER);
  const log = summaryWriter(env);
  log(`### Execute-plan approve (EXECUTE_PLAN_DRIVER=${killSwitch})`);
  if (killSwitch === 'off') return log('Kill switch is off: nothing done.');
  const event = JSON.parse(fs.readFileSync(env.EVENT_PATH, 'utf8'));
  const res = await handleControlComment(makeClients(env, killSwitch), event, { killSwitch, log });
  log(`Result: ${res.detail}`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error(`execute-plan-approve: ${e.message}`);
    process.exit(1);
  });
}

module.exports = { main, makeClients };
