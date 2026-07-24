#!/usr/bin/env node
'use strict';

/**
 * Evaluate UAT queue promote hold before creating a uat-* tag.
 *
 * Environment:
 *   GITHUB_TOKEN — read coordination issue marker
 *   UAT_COORDINATION_ISSUE — repo variable (optional; skip when unset)
 *   UAT_PROMOTE_HOLD_ENABLED — default true unless explicitly 'false'
 *
 * Outputs to GITHUB_OUTPUT when set:
 *   promotion_status (ok|blocked)
 *   promotion_block_reason
 */
const fs = require('fs');
const { loadStateFromIssue, resolveCoordinationIssue } = require('../lib/uat_queue_sync');
const { queueHeadHold } = require('../lib/uat_queue_lib');

function emitOutput(key, value) {
  const line = `${key}=${value}\n`;
  if (process.env.GITHUB_OUTPUT) {
    fs.appendFileSync(process.env.GITHUB_OUTPUT, line);
  }
  process.stdout.write(line);
}

async function main() {
  const holdEnabled = process.env.UAT_PROMOTE_HOLD_ENABLED !== 'false';
  const coordinationIssue = resolveCoordinationIssue(process.env.UAT_COORDINATION_ISSUE);

  if (!holdEnabled) {
    emitOutput('promotion_status', 'ok');
    emitOutput('promotion_block_reason', '');
    console.log('UAT promote hold disabled (UAT_PROMOTE_HOLD_ENABLED=false)');
    return;
  }

  if (!coordinationIssue) {
    emitOutput('promotion_status', 'ok');
    emitOutput('promotion_block_reason', '');
    console.log('UAT_COORDINATION_ISSUE unset — promote hold check skipped');
    return;
  }

  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  if (!token) {
    throw new Error('GITHUB_TOKEN is required to evaluate UAT promote hold');
  }

  const { state } = await loadStateFromIssue(coordinationIssue, token);
  const hold = queueHeadHold(state);

  if (hold.hold) {
    const reason = `uat_queue_${hold.reason}`;
    const detail = hold.entry
      ? `seq=${hold.entry.seq} pr=${hold.entry.pr_number} state=${hold.entry.state}`
      : 'no_head_entry';
    console.error(`::warning::UAT promote hold active (${hold.reason}) — ${detail}`);
    emitOutput('promotion_status', 'blocked');
    emitOutput('promotion_block_reason', reason);
    return;
  }

  emitOutput('promotion_status', 'ok');
  emitOutput('promotion_block_reason', '');
  console.log('UAT queue promote hold clear — promotion may proceed');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = { main };
