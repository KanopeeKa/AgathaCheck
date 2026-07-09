#!/usr/bin/env node
/**
 * BDD coverage checker: measures how many Gherkin scenarios from
 * flutter_app/test/bdd/features/*.feature are referenced by
 * @bdd header comments in e2e/playwright/tests/*.spec.ts.
 *
 * Usage:
 *   node e2e/scripts/check_bdd_coverage.js [--report-only]
 *
 * Exit codes:
 *   0  mapped scenarios >= gate (or --report-only)
 *   1  mapped scenarios < gate
 */

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..', '..');
const FEATURES_DIR = path.join(REPO_ROOT, 'flutter_app', 'test', 'bdd', 'features');
const SPECS_DIR = path.join(REPO_ROOT, 'e2e', 'playwright', 'tests');

const GATE = 105; // 65 % of 165 total scenarios (Sprint 7.4 ratchet)

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function normalize(title) {
  return title.toLowerCase().replace(/\s+/g, ' ').trim();
}

function parseArgs(argv) {
  return { reportOnly: argv.includes('--report-only') };
}

// ---------------------------------------------------------------------------
// Feature-file parsing: collect every "Scenario:" title
// ---------------------------------------------------------------------------

function collectFeatureScenarios(dir) {
  const scenarios = [];
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith('.feature'))) {
    const text = fs.readFileSync(path.join(dir, file), 'utf8');
    for (const line of text.split('\n')) {
      const m = line.match(/^\s*Scenario:\s*(.+)/);
      if (m) {
        scenarios.push({ title: m[1].trim(), file });
      }
    }
  }
  return scenarios;
}

// ---------------------------------------------------------------------------
// Spec-file parsing: collect "Scenario:" titles from @bdd header block
//
// The header block is the leading /** … */ comment where every line that
// starts with " * Scenario:" contributes a mapped scenario title.
// ---------------------------------------------------------------------------

function collectSpecScenarios(dir) {
  const scenarios = [];
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith('.spec.ts'))) {
    const text = fs.readFileSync(path.join(dir, file), 'utf8');

    // Only scan the opening block comment (before any import/code line).
    const blockEnd = text.indexOf('*/');
    if (blockEnd === -1) continue;
    const header = text.slice(0, blockEnd);

    for (const line of header.split('\n')) {
      const m = line.match(/\*\s*Scenario:\s*(.+)/);
      if (m) {
        scenarios.push({ title: m[1].trim(), file });
      }
    }
  }
  return scenarios;
}

// ---------------------------------------------------------------------------
// Fuzzy matching: for each spec scenario find the best-matching feature
// scenario (normalised equality).  Returns a Set of normalised feature titles
// that were matched.
// ---------------------------------------------------------------------------

function buildMappedSet(featureScenarios, specScenarios) {
  const featureNorm = new Set(featureScenarios.map((s) => normalize(s.title)));
  const mapped = new Set();

  for (const spec of specScenarios) {
    const key = normalize(spec.title);
    if (featureNorm.has(key)) {
      mapped.add(key);
    }
  }

  return mapped;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  const { reportOnly } = parseArgs(process.argv);

  const featureScenarios = collectFeatureScenarios(FEATURES_DIR);
  const specScenarios = collectSpecScenarios(SPECS_DIR);
  const mappedSet = buildMappedSet(featureScenarios, specScenarios);

  const total = featureScenarios.length;
  const mapped = mappedSet.size;
  const pct = total > 0 ? ((mapped / total) * 100).toFixed(1) : '0.0';

  console.log(`BDD scenario coverage: ${pct}% (${mapped}/${total} scenarios mapped)`);
  console.log(`Gate: ${GATE} mapped scenarios (${((GATE / total) * 100).toFixed(0)}% of ${total})`);

  // List unmapped spec scenarios (titles in specs that don't match any feature)
  const featureNorm = new Set(featureScenarios.map((s) => normalize(s.title)));
  const unmatchedSpec = specScenarios.filter((s) => !featureNorm.has(normalize(s.title)));
  if (unmatchedSpec.length > 0) {
    console.log('\nSpec scenarios with no matching feature scenario (possible title drift):');
    for (const s of unmatchedSpec) {
      console.log(`  [${path.basename(s.file)}] ${s.title}`);
    }
  }

  // List feature scenarios not yet covered
  const uncovered = featureScenarios.filter((s) => !mappedSet.has(normalize(s.title)));
  if (uncovered.length > 0) {
    console.log(`\nFeature scenarios not yet covered by specs (${uncovered.length}):`);
    let currentFile = '';
    for (const s of uncovered) {
      if (s.file !== currentFile) {
        console.log(`  ${s.file}`);
        currentFile = s.file;
      }
      console.log(`    - ${s.title}`);
    }
  }

  if (!reportOnly && mapped < GATE) {
    console.error(
      `\n::error::BDD coverage ${mapped} mapped scenarios is below gate of ${GATE}`,
    );
    process.exit(1);
  }
}

main();
