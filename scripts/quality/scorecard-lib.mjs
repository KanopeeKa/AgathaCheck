#!/usr/bin/env node
/**
 * Shared collectors for scripts/quality/generate-scorecard-metrics.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

import {
  buildOwnership,
  listTestFiles,
  loadFrozenTestRoots,
  loadManifest,
} from '../ci/flutter-shards.mjs';
import { FROZEN_E2E_SPECS } from '../../e2e/scripts/frozen-e2e-specs.mjs';
import { activeSpecs } from '../../e2e/scripts/shard-files.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
export const REPO_ROOT = path.resolve(HERE, '..', '..');

export const THRESHOLDS = {
  flutterDomainCoveragePct: 70,
  bddGateRatio: 0.68,
};

const FEATURES_DIR = path.join(REPO_ROOT, 'flutter_app', 'test', 'bdd', 'features');
const SPECS_DIR = path.join(REPO_ROOT, 'e2e', 'playwright', 'tests');
const FROZEN_MANIFEST = path.join(REPO_ROOT, 'docs', 'engineering', 'frozen-domains', 'manifest.json');
const SCORECARD_PATH = path.join(REPO_ROOT, 'docs', 'quality', 'scorecard.md');

const JEST_FROZEN_PREFIXES = [
  'test/organizations/',
  'test/fosterPlacements.test.js',
  'test/fosteringActivitySummary.test.js',
  'test/externalFosterNotice.test.js',
  'test/fosterCapacity.test.js',
  'test/custodyTransfers.test.js',
  'test/orgConnections.test.js',
  'test/organizationsDiscover.test.js',
  'test/orgPermissions.test.js',
  'test/orgPeople.test.js',
  'test/orgPeopleRedaction.test.js',
  'test/orgPetTransfer.test.js',
  'test/orgRoles.test.js',
  'test/adoptionJourneys.test.js',
  'test/adoptionVisits.test.js',
  'test/sessionDetail.test.js',
  'test/sessionLifecycle.test.js',
  'test/pets/orgMembership.test.js',
];

export function normalizeTitle(title) {
  return title.toLowerCase().replace(/\s+/g, ' ').trim();
}

function loadBddFrozenPatterns() {
  const manifest = JSON.parse(fs.readFileSync(FROZEN_MANIFEST, 'utf8'));
  return manifest.bddFeaturePatterns || [];
}

function featureBaseName(filename) {
  return filename.replace(/\.feature$/, '');
}

function matchesFrozenFeaturePattern(filename, patterns) {
  const base = featureBaseName(filename);
  for (const pattern of patterns) {
    if (pattern.endsWith('*')) {
      if (base.startsWith(pattern.slice(0, -1))) return true;
    } else if (base === pattern) return true;
  }
  return false;
}

export function collectFeatureScenarios() {
  const patterns = loadBddFrozenPatterns();
  const scenarios = [];
  for (const file of fs.readdirSync(FEATURES_DIR).filter((f) => f.endsWith('.feature'))) {
    if (matchesFrozenFeaturePattern(file, patterns)) continue;
    const text = fs.readFileSync(path.join(FEATURES_DIR, file), 'utf8');
    let pendingTags = [];
    for (const line of text.split('\n')) {
      const tagMatch = line.match(/^\s*(@[\w-]+(?:\s+@[\w-]+)*)\s*$/);
      if (tagMatch) {
        pendingTags.push(...tagMatch[1].split(/\s+/));
        continue;
      }
      const m = line.match(/^\s*Scenario:\s*(.+)/);
      if (m) {
        const frozen = pendingTags.includes('@frozen') || pendingTags.includes('@legacy');
        scenarios.push({ title: m[1].trim(), file, frozen });
        pendingTags = [];
        continue;
      }
      if (line.trim() !== '' && !line.match(/^\s*#/)) pendingTags = [];
    }
  }
  return scenarios;
}

export function collectBddSpecScenarios() {
  const scenarios = [];
  for (const file of fs.readdirSync(SPECS_DIR).filter((f) => f.endsWith('.spec.ts'))) {
    const text = fs.readFileSync(path.join(SPECS_DIR, file), 'utf8');
    const blockEnd = text.indexOf('*/');
    if (blockEnd === -1) continue;
    const header = text.slice(0, blockEnd);
    for (const line of header.split('\n')) {
      const m = line.match(/\*\s*Scenario:\s*(.+)/);
      if (m) scenarios.push({ title: m[1].trim(), file });
    }
  }
  return scenarios;
}

function jestPathFrozen(rel) {
  const normalized = rel.split(path.sep).join('/');
  return JEST_FROZEN_PREFIXES.some((p) => {
    if (p.endsWith('/')) return normalized.startsWith(p);
    return normalized === p || normalized.startsWith(`${p}/`);
  });
}

function listJestFiles() {
  const root = path.join(REPO_ROOT, 'server', 'test');
  const out = [];
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(abs);
      else if (entry.name.endsWith('.test.js')) {
        out.push(path.relative(path.join(REPO_ROOT, 'server'), abs).split(path.sep).join('/'));
      }
    }
  };
  walk(root);
  return out.sort();
}

function countSmokeTags() {
  const TEST_TITLE_RE = /\btest(?:\.(?:only|skip|fixme))?\s*\(\s*(['"`])([\s\S]*?)\1/g;
  let smokeCi = 0;
  let smokeUat = 0;
  let smokeA11y = 0;
  for (const file of fs.readdirSync(SPECS_DIR).filter((f) => f.endsWith('.spec.ts'))) {
    const text = fs.readFileSync(path.join(SPECS_DIR, file), 'utf8');
    for (const match of text.matchAll(TEST_TITLE_RE)) {
      const title = match[2];
      if (title.includes('@smoke-ci')) smokeCi += 1;
      if (title.includes('@smoke-uat')) smokeUat += 1;
      if (title.includes('@smoke-a11y')) smokeA11y += 1;
    }
  }
  return { smokeCi, smokeUat, smokeA11y };
}

function countFlutterIntegrationFlows() {
  const integrationDir = path.join(REPO_ROOT, 'flutter_app', 'test', 'features', 'pet_profile', 'presentation', 'integration');
  if (!fs.existsSync(integrationDir)) return 0;
  return fs.readdirSync(integrationDir).filter((f) => f.endsWith('_test.dart')).length;
}

export function collectMetrics() {
  const manifest = loadManifest();
  const frozenRoots = loadFrozenTestRoots();
  const files = listTestFiles();
  const { byShard, unowned, multi, frozen, excluded } = buildOwnership({
    manifest,
    frozenRoots,
    files,
  });

  let flutterActive = 0;
  for (const [, shardFiles] of byShard) flutterActive += shardFiles.length;

  const jestFiles = listJestFiles();
  const jestFrozen = jestFiles.filter(jestPathFrozen).length;
  const jestActive = jestFiles.length - jestFrozen;

  const allPlaywright = fs.readdirSync(SPECS_DIR).filter((f) => f.endsWith('.spec.ts'));
  const playwrightFrozen = allPlaywright.filter((f) => FROZEN_E2E_SPECS.has(f)).length;
  const playwrightActive = activeSpecs().length;

  const allFeatures = collectFeatureScenarios();
  const activeFeatures = allFeatures.filter((s) => !s.frozen);
  const bddFrozen = allFeatures.length - activeFeatures.length;
  const specScenarios = collectBddSpecScenarios().filter(
    (s) => !FROZEN_E2E_SPECS.has(path.basename(s.file)),
  );
  const featureNorm = new Set(activeFeatures.map((s) => normalizeTitle(s.title)));
  const mapped = activeFeatures.filter((s) => {
    return specScenarios.some((sp) => normalizeTitle(sp.title) === normalizeTitle(s.title));
  }).length;
  const bddDrift = specScenarios.filter((s) => !featureNorm.has(normalizeTitle(s.title)));
  const bddUncovered = activeFeatures.length - mapped;
  const bddGate = Math.max(1, Math.floor(activeFeatures.length * THRESHOLDS.bddGateRatio));
  const bddPct =
    activeFeatures.length > 0 ? ((mapped / activeFeatures.length) * 100).toFixed(1) : '0.0';

  const smoke = countSmokeTags();

  let shardOrphans = 0;
  try {
    const out = execFileSync('node', ['e2e/scripts/validate-shard-manifest.mjs', '--report-only'], {
      cwd: REPO_ROOT,
      encoding: 'utf8',
    });
    const m = out.match(/Orphan specs \(not in shard-files\.mjs\): (\d+)/);
    shardOrphans = m ? Number(m[1]) : 0;
  } catch {
    shardOrphans = -1;
  }

  return {
    generatedAt: new Date().toISOString().slice(0, 10),
    thresholds: THRESHOLDS,
    flutter: {
      active: flutterActive,
      frozen,
      excluded,
      unowned: unowned.length,
      multiOwned: multi.length,
      shardCount: manifest.shards.length,
      integrationFlows: countFlutterIntegrationFlows(),
    },
    jest: { active: jestActive, frozen: jestFrozen },
    playwright: { active: playwrightActive, frozen: playwrightFrozen, total: allPlaywright.length },
    bdd: {
      active: activeFeatures.length,
      frozen: bddFrozen,
      mapped,
      uncovered: bddUncovered,
      gate: bddGate,
      gatePct: Math.round(THRESHOLDS.bddGateRatio * 100),
      mappedPct: bddPct,
      drift: bddDrift.map((s) => ({ file: path.basename(s.file), title: s.title })),
    },
    smoke,
    preUat: { shardTotal: 9, shardOrphans },
  };
}

export function formatMetricsMarkdown(metrics) {
  const lines = [
    `**Auto-generated block** — refresh with \`node scripts/quality/generate-scorecard-metrics.mjs --write-scorecard\` (${metrics.generatedAt}).`,
    '',
    '| Metric | Value | Enforced by |',
    '|--------|------:|-------------|',
    `| Flutter unit/widget (active CI) | ${metrics.flutter.active} | ${metrics.flutter.shardCount} shards (\`ci_shards.json\`) |`,
    `| Flutter frozen / excluded tests | ${metrics.flutter.frozen} / ${metrics.flutter.excluded} | frozen-domains manifest |`,
    `| Flutter unowned tests | ${metrics.flutter.unowned} | \`flutter-shards.mjs check\` |`,
    `| Flutter integration flows | ${metrics.flutter.integrationFlows} | \`flutter-integration\` job |`,
    `| Jest (active / frozen) | ${metrics.jest.active} / ${metrics.jest.frozen} | \`jest.config.active.cjs\` |`,
    `| Playwright (active / frozen) | ${metrics.playwright.active} / ${metrics.playwright.frozen} | \`shard-files.mjs\` + frozen list |`,
    `| BDD active scenarios | ${metrics.bdd.active} (${metrics.bdd.frozen} frozen excluded) | \`check_bdd_coverage.js\` |`,
    `| BDD mapped (active) | ${metrics.bdd.mappedPct}% (${metrics.bdd.mapped}/${metrics.bdd.active}) | gate **${metrics.bdd.gate}/${metrics.bdd.active} (${metrics.bdd.gatePct}%)** |`,
    `| BDD title drift (active) | ${metrics.bdd.drift.length} | \`generate-scorecard-metrics.mjs --check\` |`,
    `| BDD uncovered (active) | ${metrics.bdd.uncovered} | informational |`,
    `| Pre-UAT shard orphans | ${metrics.preUat.shardOrphans} | \`validate-shard-manifest.mjs\` |`,
    `| @smoke-ci / @smoke-uat / @smoke-a11y | ${metrics.smoke.smokeCi} / ${metrics.smoke.smokeUat} / ${metrics.smoke.smokeA11y} | \`check-smoke-tags.mjs\` |`,
    `| Flutter domain coverage gate | **${metrics.thresholds.flutterDomainCoveragePct}%** | \`check_domain_coverage.js\` |`,
  ];
  return lines.join('\n');
}

const BLOCK_BEGIN = '<!-- scorecard-metrics:begin -->';
const BLOCK_END = '<!-- scorecard-metrics:end -->';

export function readScorecardBlock() {
  const text = fs.readFileSync(SCORECARD_PATH, 'utf8');
  const start = text.indexOf(BLOCK_BEGIN);
  const end = text.indexOf(BLOCK_END);
  if (start === -1 || end === -1 || end < start) {
    throw new Error(`${SCORECARD_PATH}: missing ${BLOCK_BEGIN} … ${BLOCK_END} markers`);
  }
  return { text, start, end, innerStart: start + BLOCK_BEGIN.length, innerEnd: end };
}

export function writeScorecardBlock(metrics) {
  const { text, innerStart, innerEnd } = readScorecardBlock();
  const body = `\n${formatMetricsMarkdown(metrics)}\n`;
  const next = `${text.slice(0, innerStart)}${body}${text.slice(innerEnd)}`;
  fs.writeFileSync(SCORECARD_PATH, next);
}

export function scorecardBlockMatchesMetrics(metrics) {
  const { text, innerStart, innerEnd } = readScorecardBlock();
  const block = text.slice(innerStart, innerEnd);
  const expected = formatMetricsMarkdown(metrics);
  return block.trim() === expected.trim();
}
