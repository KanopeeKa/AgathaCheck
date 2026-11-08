#!/usr/bin/env node
/**
 * Run a single command from scripts/ci/governance-blocking-steps.mjs (canonical source).
 *
 *   node scripts/ci/run-governance-gate.mjs <gate-id>
 */
import { runGateById } from './governance-gate-lib.mjs';

const id = process.argv[2];
if (!id) {
  console.error('usage: node scripts/ci/run-governance-gate.mjs <gate-id>');
  process.exit(1);
}
runGateById(id);
