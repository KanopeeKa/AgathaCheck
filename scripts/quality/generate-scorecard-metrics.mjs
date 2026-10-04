#!/usr/bin/env node
/**
 * Live test-health KPIs for docs/quality/scorecard.md
 *
 * Usage:
 *   node scripts/quality/generate-scorecard-metrics.mjs [--json]
 *   node scripts/quality/generate-scorecard-metrics.mjs --write-scorecard
 *   node scripts/quality/generate-scorecard-metrics.mjs --check
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  collectMetrics,
  scorecardBlockMatchesMetrics,
  THRESHOLDS,
  writeScorecardBlock,
} from './scorecard-lib.mjs';

function fail(msg) {
  console.error(`generate-scorecard-metrics: ${msg}`);
  process.exit(1);
}

function runCheck(metrics) {
  if (metrics.flutter.unowned > 0) {
    fail(`${metrics.flutter.unowned} Flutter test file(s) not owned by any CI shard`);
  }
  if (metrics.flutter.multiOwned > 0) {
    fail(`${metrics.flutter.multiOwned} Flutter test file(s) owned by multiple shards`);
  }
  if (metrics.bdd.drift.length > 0) {
    fail(`${metrics.bdd.drift.length} active BDD @bdd title drift(s) — fix headers or feature titles`);
  }
  if (metrics.preUat.shardOrphans > 0) {
    fail(`${metrics.preUat.shardOrphans} Playwright spec(s) missing from Pre-UAT shard manifest`);
  }
  if (!scorecardBlockMatchesMetrics(metrics)) {
    fail(
      'docs/quality/scorecard.md metrics block is stale — run with --write-scorecard (or CI will refresh)',
    );
  }
  const scorecardPath = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'docs', 'quality', 'scorecard.md');
  const coverageSection = fs.readFileSync(scorecardPath, 'utf8').split('## Changelog')[0];
  const bad65 = /\b65\s*%\s*line coverage gate\b/i.test(coverageSection);
  if (bad65 && THRESHOLDS.flutterDomainCoveragePct === 70) {
    fail('scorecard still documents 65% Flutter domain gate — must match 70% threshold');
  }
}

function main() {
  const args = new Set(process.argv.slice(2));
  const metrics = collectMetrics();

  if (args.has('--write-scorecard')) {
    writeScorecardBlock(metrics);
    console.log('generate-scorecard-metrics: updated docs/quality/scorecard.md metrics block');
  }

  if (args.has('--check')) {
    runCheck(metrics);
    console.log('generate-scorecard-metrics: OK');
    return;
  }

  console.log(JSON.stringify(metrics, null, 2));
}

main();
