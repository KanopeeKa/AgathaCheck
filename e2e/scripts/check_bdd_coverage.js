#!/usr/bin/env node
/**
 * BDD coverage checker: measures how many Gherkin scenarios from
 * flutter_app/test/bdd/features/*.feature are referenced by
 * @bdd header comments in e2e/playwright/tests/*.spec.ts.
 *
 * Frozen Shelter/Fostering scenarios are excluded via
 * docs/engineering/frozen-domains/manifest.json (feature patterns + @frozen/@legacy tags).
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
const MANIFEST_PATH = path.join(
  REPO_ROOT,
  'docs',
  'engineering',
  'frozen-domains',
  'manifest.json',
);

const GATE_RATIO = 0.68;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function normalize(title) {
  return title.toLowerCase().replace(/\s+/g, ' ').trim();
}

function parseArgs(argv) {
  return { reportOnly: argv.includes('--report-only') };
}

function loadManifest() {
  const raw = fs.readFileSync(MANIFEST_PATH, 'utf8');
  const manifest = JSON.parse(raw);
  return manifest.bddFeaturePatterns || [];
}

function featureBaseName(filename) {
  return filename.replace(/\.feature$/, '');
}

function matchesFrozenFeaturePattern(filename, patterns) {
  const base = featureBaseName(filename);
  for (const pattern of patterns) {
    if (pattern.endsWith('*')) {
      const prefix = pattern.slice(0, -1);
      if (base.startsWith(prefix)) return true;
    } else if (base === pattern) {
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Feature-file parsing: collect scenarios with frozen flag
// ---------------------------------------------------------------------------

function collectFeatureScenarios(dir, frozenPatterns) {
  const scenarios = [];
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith('.feature'))) {
    if (matchesFrozenFeaturePattern(file, frozenPatterns)) {
      continue;
    }
    const text = fs.readFileSync(path.join(dir, file), 'utf8');
    let pendingTags = [];
    for (const line of text.split('\n')) {
      const tagMatch = line.match(/^\s*(@[\w-]+(?:\s+@[\w-]+)*)\s*$/);
      if (tagMatch) {
        pendingTags.push(...tagMatch[1].split(/\s+/));
        continue;
      }
      const m = line.match(/^\s*Scenario:\s*(.+)/);
      if (m) {
        const frozen =
          pendingTags.includes('@frozen') || pendingTags.includes('@legacy');
        scenarios.push({ title: m[1].trim(), file, frozen });
        pendingTags = [];
        continue;
      }
      if (line.trim() !== '' && !line.match(/^\s*#/)) {
        pendingTags = [];
      }
    }
  }
  return scenarios;
}

function activeFeatureScenarios(scenarios) {
  return scenarios.filter((s) => !s.frozen);
}

// ---------------------------------------------------------------------------
// Spec-file parsing: collect "Scenario:" titles from @bdd header block
// ---------------------------------------------------------------------------

function collectSpecScenarios(dir) {
  const scenarios = [];
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith('.spec.ts'))) {
    const text = fs.readFileSync(path.join(dir, file), 'utf8');

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

function computeGate(activeTotal) {
  return Math.max(1, Math.floor(activeTotal * GATE_RATIO));
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  const { reportOnly } = parseArgs(process.argv);
  const frozenPatterns = loadManifest();

  const allFeatureScenarios = collectFeatureScenarios(FEATURES_DIR, frozenPatterns);
  const featureScenarios = activeFeatureScenarios(allFeatureScenarios);
  const specScenarios = collectSpecScenarios(SPECS_DIR);
  const mappedSet = buildMappedSet(featureScenarios, specScenarios);

  const frozenCount = allFeatureScenarios.length - featureScenarios.length;
  const total = featureScenarios.length;
  const mapped = mappedSet.size;
  const gate = computeGate(total);
  const pct = total > 0 ? ((mapped / total) * 100).toFixed(1) : '0.0';

  console.log(
    `BDD scenario coverage: ${pct}% (${mapped}/${total} active scenarios mapped; ${frozenCount} frozen excluded)`,
  );
  console.log(
    `Gate: ${gate} mapped scenarios (${((gate / total) * 100).toFixed(0)}% of ${total} active)`,
  );

  const featureNorm = new Set(featureScenarios.map((s) => normalize(s.title)));
  const unmatchedSpec = specScenarios.filter((s) => !featureNorm.has(normalize(s.title)));
  if (unmatchedSpec.length > 0) {
    console.log('\nSpec scenarios with no matching active feature scenario (possible title drift):');
    for (const s of unmatchedSpec) {
      console.log(`  [${path.basename(s.file)}] ${s.title}`);
    }
  }

  const uncovered = featureScenarios.filter((s) => !mappedSet.has(normalize(s.title)));
  if (uncovered.length > 0) {
    console.log(`\nActive feature scenarios not yet covered by specs (${uncovered.length}):`);
    let currentFile = '';
    for (const s of uncovered) {
      if (s.file !== currentFile) {
        console.log(`  ${s.file}`);
        currentFile = s.file;
      }
      console.log(`    - ${s.title}`);
    }
  }

  if (!reportOnly && mapped < gate) {
    console.error(
      `\n::error::BDD coverage ${mapped} mapped scenarios is below gate of ${gate}`,
    );
    process.exit(1);
  }
}

main();
