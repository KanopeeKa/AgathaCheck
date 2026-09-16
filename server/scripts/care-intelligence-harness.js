#!/usr/bin/env node
/**
 * Care Intelligence evaluation harness runner (D5a / D3).
 *
 * Runs `runEvaluationHarness` over the reference vectors and benchmark sample
 * cases, prints the JSON report to stdout, and exits non-zero when any case
 * fails so it can be wired into CI / deploy verification.
 *
 * Usage:
 *   node scripts/care-intelligence-harness.js
 *   node scripts/care-intelligence-harness.js --no-benchmark
 */
import { runEvaluationHarness } from '../routes/careIntelligence/evaluationHarness.js';

const args = process.argv.slice(2);
const includeBenchmark = !args.includes('--no-benchmark');

const report = runEvaluationHarness({ includeBenchmark });
process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);

if (report.failed > 0) {
  process.exit(1);
}
