#!/usr/bin/env node
/**
 * Multi-dimensional test quality scorecard (mapping, implementation, execution).
 *
 * Usage:
 *   node e2e/scripts/check_test_quality.js [--report-only]
 *
 * Gates (when not --report-only):
 *   - D2 mapping >= check_bdd_coverage gate (delegates)
 *   - D4 orphans == 0 (validate-shard-manifest, report-only until F3 enforces)
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..', '..');
const SPECS_DIR = path.join(REPO_ROOT, 'e2e', 'playwright', 'tests');

const SKELETON_RE = /expect\s*\(\s*true\s*\)\s*\.\s*toBe\s*\(\s*true\s*\)/;
const TEST_TITLE_RE = /\btest(?:\.(?:only|skip|fixme))?\s*\(\s*(['"`])([\s\S]*?)\1/g;

function countSmokeTags() {
  let smokeCi = 0;
  let smokeUat = 0;
  for (const file of fs.readdirSync(SPECS_DIR).filter((f) => f.endsWith('.spec.ts'))) {
    const text = fs.readFileSync(path.join(SPECS_DIR, file), 'utf8');
    for (const match of text.matchAll(TEST_TITLE_RE)) {
      const title = match[2];
      if (title.includes('@smoke-ci')) smokeCi += 1;
      if (title.includes('@smoke-uat')) smokeUat += 1;
    }
  }
  return { smokeCi, smokeUat };
}

function countSkeletonSpecs() {
  const skeletons = [];
  for (const file of fs.readdirSync(SPECS_DIR).filter((f) => f.endsWith('.spec.ts'))) {
    const text = fs.readFileSync(path.join(SPECS_DIR, file), 'utf8');
    if (SKELETON_RE.test(text)) skeletons.push(file);
  }
  return skeletons;
}

function runBddReport() {
  const out = execFileSync('node', ['e2e/scripts/check_bdd_coverage.js', '--report-only'], {
    cwd: REPO_ROOT,
    encoding: 'utf8',
  });
  const m = out.match(/(\d+\.\d+)% \((\d+)\/(\d+) scenarios mapped\)/);
  if (!m) return { pct: '0', mapped: 0, total: 0 };
  return { pct: m[1], mapped: Number(m[2]), total: Number(m[3]) };
}

function runManifestReport() {
  const stdout = execFileSync('node', ['e2e/scripts/validate-shard-manifest.mjs', '--report-only'], {
    cwd: REPO_ROOT,
    encoding: 'utf8',
  });
  const m = stdout.match(/Orphan specs \(not in shard-files\.mjs\): (\d+)/);
  return { orphans: m ? Number(m[1]) : 0, ok: !m || Number(m[1]) === 0 };
}

function main() {
  const reportOnly = process.argv.includes('--report-only');
  const bdd = runBddReport();
  const manifest = runManifestReport();
  const skeletons = countSkeletonSpecs();
  const smoke = countSmokeTags();

  console.log('## Test quality scorecard');
  console.log('');
  console.log('| Dimension | Metric |');
  console.log('|-----------|--------|');
  console.log(`| D1 Gherkin inventory | ${bdd.total} scenarios |`);
  console.log(`| D2 Mapping coverage | ${bdd.pct}% (${bdd.mapped}/${bdd.total}) |`);
  console.log(`| D3 Skeleton specs (S0) | ${skeletons.length} files |`);
  console.log(`| D4 Pre-UAT orphans | ${manifest.orphans >= 0 ? manifest.orphans : 'error'} |`);
  console.log(`| D5 @smoke-ci tests | ${smoke.smokeCi} |`);
  console.log(`| D6 @smoke-uat tests | ${smoke.smokeUat} |`);

  if (skeletons.length > 0) {
    console.log('\nSkeleton spec files:');
    for (const f of skeletons.sort()) console.log(`  - ${f}`);
  }

  if (!reportOnly) {
    execFileSync('node', ['e2e/scripts/check_bdd_coverage.js'], {
      cwd: REPO_ROOT,
      stdio: 'inherit',
    });
    execFileSync('node', ['e2e/scripts/check-smoke-tags.mjs'], {
      cwd: REPO_ROOT,
      stdio: 'inherit',
    });
  }
}

main();
