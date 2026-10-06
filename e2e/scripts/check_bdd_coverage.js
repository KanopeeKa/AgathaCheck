#!/usr/bin/env node
/**
 * BDD coverage checker: traceability (Gherkin ↔ @bdd headers) vs execution
 * (Pre-UAT shard schedule) vs quality (skeleton / orphan specs).
 *
 * Frozen Shelter/Fostering scenarios are excluded via
 * docs/engineering/frozen-domains/manifest.json (feature patterns + @frozen/@legacy tags).
 * Frozen E2E specs are excluded via e2e/scripts/frozen-e2e-specs.mjs.
 *
 * Usage:
 *   node e2e/scripts/check_bdd_coverage.js [--report-only] [--root <path>]
 *
 * Exit codes:
 *   0  mapped scenarios >= gate (or --report-only)
 *   1  mapped scenarios < gate
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');

const GATE_RATIO = 0.68;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function normalize(title) {
  return title.toLowerCase().replace(/\s+/g, ' ').trim();
}

function parseArgs(argv) {
  let reportOnly = false;
  let root = null;
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--report-only') reportOnly = true;
    else if (argv[i] === '--root') {
      root = argv[i + 1];
      i += 1;
    }
  }
  return { reportOnly, root };
}

function repoPaths(repoRoot) {
  return {
    featuresDir: path.join(repoRoot, 'flutter_app', 'test', 'bdd', 'features'),
    specsDir: path.join(repoRoot, 'e2e', 'playwright', 'tests'),
    manifestPath: path.join(
      repoRoot,
      'docs',
      'engineering',
      'frozen-domains',
      'manifest.json',
    ),
    frozenE2ePath: path.join(repoRoot, 'e2e', 'scripts', 'frozen-e2e-specs.mjs'),
    shardFilesPath: path.join(repoRoot, 'e2e', 'scripts', 'shard-files.mjs'),
  };
}

function loadManifest(manifestPath) {
  const raw = fs.readFileSync(manifestPath, 'utf8');
  const manifest = JSON.parse(raw);
  return manifest.bddFeaturePatterns || [];
}

function loadFrozenE2eSpecs(frozenE2ePath) {
  const text = fs.readFileSync(frozenE2ePath, 'utf8');
  const names = [];
  for (const m of text.matchAll(/'([^']+\.spec\.ts)'/g)) {
    names.push(m[1]);
  }
  return new Set(names);
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
  if (!fs.existsSync(dir)) return scenarios;
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

const TEST_TITLE_RE = /\btest(?:\.(?:only|skip|fixme))?\s*\(\s*(['"`])([\s\S]*?)\1/g;

function splitSpecFile(text) {
  const blockEnd = text.indexOf('*/');
  if (blockEnd === -1) return { header: '', body: text };
  return { header: text.slice(0, blockEnd), body: text.slice(blockEnd + 2) };
}

function collectTestTitles(specBody) {
  const titles = [];
  for (const match of specBody.matchAll(TEST_TITLE_RE)) {
    titles.push(match[2]);
  }
  return titles;
}

/** @bdd Scenario with no Playwright test title that plausibly implements it (F6 orphan cleanup). */
function isHeaderOnlyBddMapping(scenarioTitle, specBody) {
  const keywords = normalize(scenarioTitle)
    .split(' ')
    .filter((w) => w.length > 3);
  if (keywords.length === 0) return false;
  const needed = Math.min(3, keywords.length);
  const tests = collectTestTitles(specBody);
  return !tests.some((testTitle) => {
    const normTest = normalize(testTitle);
    const hits = keywords.filter((w) => normTest.includes(w)).length;
    return hits >= needed;
  });
}

function collectSpecScenarios(dir, frozenSpecs) {
  const scenarios = [];
  const files = [];
  if (!fs.existsSync(dir)) return { scenarios, files };
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith('.spec.ts'))) {
    if (frozenSpecs.has(file)) continue;
    files.push(file);
    const text = fs.readFileSync(path.join(dir, file), 'utf8');
    const { header, body } = splitSpecFile(text);

    for (const line of header.split('\n')) {
      const m = line.match(/\*\s*Scenario:\s*(.+)/);
      if (m) {
        scenarios.push({
          title: m[1].trim(),
          file,
          headerOnly: isHeaderOnlyBddMapping(m[1].trim(), body),
        });
      }
    }
  }
  return { scenarios, files };
}

function buildMappedSet(featureScenarios, specScenarios) {
  const featureNorm = new Set(featureScenarios.map((s) => normalize(s.title)));
  const mapped = new Set();

  for (const spec of specScenarios) {
    if (spec.headerOnly) continue;
    const key = normalize(spec.title);
    if (featureNorm.has(key)) {
      mapped.add(key);
    }
  }

  return mapped;
}

/** Feature scenarios that count toward the gate (excludes header-only phantom coverage). */
function gatedFeatureScenarios(featureScenarios, specScenarios, mappedSet) {
  const headerOnlyKeys = new Set(
    specScenarios
      .filter((s) => s.headerOnly)
      .map((s) => normalize(s.title)),
  );
  return featureScenarios.filter((f) => {
    const key = normalize(f.title);
    if (mappedSet.has(key)) return true;
    return !headerOnlyKeys.has(key);
  });
}

function computeGate(activeTotal) {
  return Math.max(1, Math.floor(activeTotal * GATE_RATIO));
}

/**
 * Active spec files with skeleton / orphan quality issues (figure c).
 * @returns {{ file: string, issues: string[] }[]}
 */
function collectQualityIssues(specsDir, frozenSpecs, specFiles) {
  const issues = [];
  for (const file of specFiles) {
    if (frozenSpecs.has(file)) continue;
    const text = fs.readFileSync(path.join(specsDir, file), 'utf8');
    const { header, body } = splitSpecFile(text);
    const fileIssues = [];
    const hasBddScenario = /\*\s*Scenario:/.test(header);
    const hasTests = /\btest\s*\(/.test(body);
    const hasExpect = /\bexpect\s*\(/.test(body);
    const hasSkipOrFixme = /\btest\.(?:skip|fixme)\s*\(/.test(body);

    if (hasTests && !hasBddScenario) {
      fileIssues.push('no-bdd-scenario');
    }
    if (hasBddScenario && hasTests && !hasExpect && !hasSkipOrFixme) {
      fileIssues.push('no-expect');
    }
    if (hasSkipOrFixme) {
      fileIssues.push('skip-or-fixme');
    }
    if (fileIssues.length > 0) {
      issues.push({ file, issues: fileIssues });
    }
  }
  return issues;
}

/**
 * Mapped scenario rows with spec file for execution scheduling checks.
 */
function mappedScenarioRows(featureScenarios, specScenarios, mappedSet) {
  const featureByNorm = new Map(
    featureScenarios.map((f) => [normalize(f.title), f]),
  );
  const rows = [];
  for (const spec of specScenarios) {
    if (spec.headerOnly) continue;
    const key = normalize(spec.title);
    if (!mappedSet.has(key) || !featureByNorm.has(key)) continue;
    rows.push({ title: spec.title, file: spec.file, featureFile: featureByNorm.get(key).file });
  }
  return rows;
}

async function loadScheduledSpecBasenames(repoRoot, specsDir) {
  const { shardFilesPath } = repoPaths(repoRoot);
  if (!fs.existsSync(shardFilesPath)) {
    return new Set();
  }
  const mod = await import(pathToFileURL(shardFilesPath).href);
  if (typeof mod.activeSpecs === 'function') {
    return new Set(mod.activeSpecs(specsDir));
  }
  const scheduled = new Set();
  for (const shard of mod.SHARDS || []) {
    for (const rel of shard) {
      scheduled.add(path.basename(rel));
    }
  }
  return scheduled;
}

/**
 * @param {string} repoRoot
 * @param {{ scheduledSpecs?: Set<string> }} [options]
 */
async function analyzeBddCoverage(repoRoot, options = {}) {
  const paths = repoPaths(repoRoot);
  const frozenPatterns = loadManifest(paths.manifestPath);
  const frozenSpecs = loadFrozenE2eSpecs(paths.frozenE2ePath);

  const allFeatureScenarios = collectFeatureScenarios(paths.featuresDir, frozenPatterns);
  const featureScenarios = activeFeatureScenarios(allFeatureScenarios);
  const { scenarios: specScenarios, files: specFiles } = collectSpecScenarios(
    paths.specsDir,
    frozenSpecs,
  );
  const mappedSet = buildMappedSet(featureScenarios, specScenarios);
  const gatedFeatures = gatedFeatureScenarios(
    featureScenarios,
    specScenarios,
    mappedSet,
  );

  const scheduledSpecs =
    options.scheduledSpecs ??
    (await loadScheduledSpecBasenames(repoRoot, paths.specsDir));

  const mappedRows = mappedScenarioRows(featureScenarios, specScenarios, mappedSet);
  const scheduledMapped = mappedRows.filter((r) => scheduledSpecs.has(r.file));
  const unscheduledMapped = mappedRows.filter((r) => !scheduledSpecs.has(r.file));

  const qualityIssues = collectQualityIssues(paths.specsDir, frozenSpecs, specFiles);
  const headerOnly = specScenarios.filter((s) => s.headerOnly);

  const frozenCount = allFeatureScenarios.length - featureScenarios.length;
  const total = featureScenarios.length;
  const gatedTotal = gatedFeatures.length;
  const headerOnlyPhantom = total - gatedTotal;
  const mapped = mappedSet.size;
  const gate = computeGate(gatedTotal);
  const pct =
    gatedTotal > 0 ? ((mapped / gatedTotal) * 100).toFixed(1) : '0.0';

  const featureNorm = new Set(featureScenarios.map((s) => normalize(s.title)));
  const unmatchedSpec = specScenarios.filter((s) => !featureNorm.has(normalize(s.title)));
  const uncovered = featureScenarios.filter((s) => !mappedSet.has(normalize(s.title)));

  const mappedSpecFiles = new Set(mappedRows.map((r) => r.file));
  const scheduledMappedSpecFiles = new Set(
    mappedRows.filter((r) => scheduledSpecs.has(r.file)).map((r) => r.file),
  );

  return {
    frozenCount,
    total,
    gatedTotal,
    headerOnlyPhantom,
    mapped,
    gate,
    pct,
    gateRatio: GATE_RATIO,
    traceability: { mapped, gatedTotal, pct },
    execution: {
      mappedScenarios: mappedRows.length,
      scheduledMappedScenarios: scheduledMapped.length,
      unscheduledMappedScenarios: unscheduledMapped.length,
      mappedSpecFiles: mappedSpecFiles.size,
      scheduledMappedSpecFiles: scheduledMappedSpecFiles.size,
      unscheduledMapped,
    },
    quality: {
      headerOnlyCount: headerOnly.length,
      headerOnly,
      qualityIssueFiles: qualityIssues.length,
      qualityIssues,
    },
    headerOnly,
    unmatchedSpec,
    uncovered,
    featureScenarios,
    specScenarios,
    mappedSet,
  };
}

function printReport(metrics) {
  const {
    pct,
    mapped,
    gatedTotal,
    headerOnlyPhantom,
    frozenCount,
    gate,
    execution,
    quality,
    headerOnly,
    unmatchedSpec,
    uncovered,
  } = metrics;

  console.log(
    `BDD traceability: ${pct}% (${mapped}/${gatedTotal} gated active scenarios mapped to @bdd specs; ${headerOnlyPhantom} header-only phantom excluded; ${frozenCount} frozen excluded)`,
  );
  console.log(
    `BDD execution (report-only): ${execution.scheduledMappedScenarios}/${execution.mappedScenarios} mapped scenarios in Pre-UAT shards (${execution.scheduledMappedSpecFiles}/${execution.mappedSpecFiles} spec files scheduled)`,
  );
  console.log(
    `BDD quality (report-only): ${quality.qualityIssueFiles} active spec files with skeleton/orphan signals; ${quality.headerOnlyCount} header-only @bdd mappings`,
  );
  console.log(
    `BDD scenario coverage: ${pct}% (${mapped}/${gatedTotal} gated scenarios mapped; ${headerOnlyPhantom} header-only phantom excluded; ${frozenCount} frozen excluded)`,
  );
  console.log(
    `Gate: ${gate} mapped scenarios (${((gate / gatedTotal) * 100).toFixed(0)}% of ${gatedTotal} gated)`,
  );

  if (execution.unscheduledMapped.length > 0) {
    console.log(
      `\nMapped scenarios in specs not scheduled for Pre-UAT (${execution.unscheduledMapped.length}):`,
    );
    for (const row of execution.unscheduledMapped) {
      console.log(`  [${row.file}] ${row.title}`);
    }
  }

  if (quality.qualityIssues.length > 0) {
    console.log(
      `\nSkeleton/orphan spec signals (${quality.qualityIssues.length} files; report-only):`,
    );
    for (const entry of quality.qualityIssues) {
      console.log(`  [${entry.file}] ${entry.issues.join(', ')}`);
    }
  }

  if (headerOnly.length > 0) {
    console.log(
      `\n@bdd header-only mappings (no matching Playwright test title; add a test or remove the header line) (${headerOnly.length}):`,
    );
    for (const s of headerOnly) {
      console.log(`  [${path.basename(s.file)}] ${s.title}`);
    }
  }

  if (unmatchedSpec.length > 0) {
    console.log('\nSpec scenarios with no matching active feature scenario (possible title drift):');
    for (const s of unmatchedSpec) {
      console.log(`  [${path.basename(s.file)}] ${s.title}`);
    }
  }

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
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const { reportOnly, root } = parseArgs(process.argv);
  const repoRoot = root ? path.resolve(root) : path.resolve(__dirname, '..', '..');
  const metrics = await analyzeBddCoverage(repoRoot);
  printReport(metrics);

  if (!reportOnly && metrics.mapped < metrics.gate) {
    console.error(
      `\n::error::BDD coverage ${metrics.mapped} mapped scenarios is below gate of ${metrics.gate}`,
    );
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = {
  GATE_RATIO,
  analyzeBddCoverage,
  collectFeatureScenarios,
  collectSpecScenarios,
  buildMappedSet,
  gatedFeatureScenarios,
  collectQualityIssues,
  mappedScenarioRows,
  normalize,
};
