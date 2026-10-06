'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');

const {
  analyzeBddCoverage,
  collectFeatureScenarios,
  collectQualityIssues,
  normalize,
} = require('./check_bdd_coverage');

const REPO_ROOT = path.resolve(__dirname, '..', '..');

function writeMiniRepo(root, layout) {
  for (const [rel, content] of Object.entries(layout)) {
    const file = path.join(root, rel);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, content);
  }
}

function miniRepoBase() {
  return {
    'docs/engineering/frozen-domains/manifest.json': JSON.stringify({
      bddFeaturePatterns: ['frozen_*'],
    }),
    'e2e/scripts/frozen-e2e-specs.mjs': `export const FROZEN_E2E_SPECS = ['frozen.spec.ts'];\n`,
  };
}

test('analyzeBddCoverage passes blocking gate on real repo', async () => {
  const metrics = await analyzeBddCoverage(REPO_ROOT);
  assert.ok(metrics.mapped >= metrics.gate);
  assert.ok(metrics.gatedTotal > 0);
  assert.equal(metrics.execution.scheduledMappedScenarios, metrics.execution.mappedScenarios);
});

test('traceability: active scenario maps to @bdd spec title', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-trace-'));
  writeMiniRepo(root, {
    ...miniRepoBase(),
    'flutter_app/test/bdd/features/pet.feature': `
Feature: Pet
  Scenario: View pet profile
    Given a pet exists
`,
    'e2e/playwright/tests/pet.spec.ts': `/**
 * @bdd pet
 * Scenario: View pet profile
 */
import { test, expect } from '@playwright/test';
test('View pet profile', async () => {
  expect(true).toBe(true);
});
`,
  });

  const metrics = await analyzeBddCoverage(root, { scheduledSpecs: new Set(['pet.spec.ts']) });
  assert.equal(metrics.traceability.mapped, 1);
  assert.equal(metrics.traceability.gatedTotal, 1);
  assert.equal(metrics.execution.scheduledMappedScenarios, 1);
});

test('execution: mapped spec not in shard schedule is report-only (gate unchanged)', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-exec-'));
  writeMiniRepo(root, {
    ...miniRepoBase(),
    'flutter_app/test/bdd/features/pet.feature': `
Feature: Pet
  Scenario: View pet profile
    Given a pet exists
`,
    'e2e/playwright/tests/pet.spec.ts': `/**
 * @bdd pet
 * Scenario: View pet profile
 */
import { test, expect } from '@playwright/test';
test('View pet profile', async () => {
  expect(true).toBe(true);
});
`,
  });

  const metrics = await analyzeBddCoverage(root, { scheduledSpecs: new Set() });
  assert.equal(metrics.traceability.mapped, 1);
  assert.equal(metrics.execution.scheduledMappedScenarios, 0);
  assert.equal(metrics.execution.unscheduledMapped.length, 1);
});

test('quality: spec with tests but no @bdd scenario is flagged', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-qual-'));
  writeMiniRepo(root, {
    ...miniRepoBase(),
    'flutter_app/test/bdd/features/pet.feature': `
Feature: Pet
  Scenario: View pet profile
    Given a pet exists
`,
    'e2e/playwright/tests/orphan.spec.ts': `/**
 * @bdd pet
 */
import { test, expect } from '@playwright/test';
test('orphan without bdd scenario line', async () => {
  expect(1).toBe(1);
});
`,
  });

  const metrics = await analyzeBddCoverage(root, { scheduledSpecs: new Set(['orphan.spec.ts']) });
  const orphan = metrics.quality.qualityIssues.find((q) => q.file === 'orphan.spec.ts');
  assert.ok(orphan);
  assert.ok(orphan.issues.includes('no-bdd-scenario'));
});

test('quality: test.skip is a skeleton signal', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-skip-'));
  writeMiniRepo(root, {
    ...miniRepoBase(),
    'flutter_app/test/bdd/features/pet.feature': `Feature: Pet\n`,
    'e2e/playwright/tests/skip.spec.ts': `/**
 * @bdd pet
 * Scenario: Placeholder
 */
import { test } from '@playwright/test';
test.skip('Placeholder', async () => {});
`,
  });

  const metrics = await analyzeBddCoverage(root, { scheduledSpecs: new Set(['skip.spec.ts']) });
  const entry = metrics.quality.qualityIssues.find((q) => q.file === 'skip.spec.ts');
  assert.ok(entry);
  assert.ok(entry.issues.includes('skip-or-fixme'));
});

test('frozen feature patterns and frozen e2e specs are excluded', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bdd-frozen-'));
  writeMiniRepo(root, {
    ...miniRepoBase(),
    'flutter_app/test/bdd/features/frozen_shelter.feature': `
Feature: Frozen
  Scenario: Should not count
    Given frozen
`,
    'flutter_app/test/bdd/features/active.feature': `
Feature: Active
  Scenario: Counts
    Given active
`,
    'e2e/playwright/tests/frozen.spec.ts': `/** @bdd frozen */\n`,
    'e2e/playwright/tests/active.spec.ts': `/**
 * @bdd active
 * Scenario: Counts
 */
import { test, expect } from '@playwright/test';
test('Counts', async () => { expect(1).toBe(1); });
`,
  });

  const patterns = JSON.parse(
    fs.readFileSync(path.join(root, 'docs/engineering/frozen-domains/manifest.json')),
  ).bddFeaturePatterns;
  const features = collectFeatureScenarios(
    path.join(root, 'flutter_app/test/bdd/features'),
    patterns,
  );
  assert.equal(features.length, 1);
  assert.equal(features[0].title, 'Counts');

  const frozenSpecs = new Set(['frozen.spec.ts']);
  const { files } = require('./check_bdd_coverage').collectSpecScenarios(
    path.join(root, 'e2e/playwright/tests'),
    frozenSpecs,
  );
  assert.ok(files.includes('active.spec.ts'));
  assert.ok(!files.includes('frozen.spec.ts'));
});

test('normalize collapses whitespace for title matching', () => {
  assert.equal(normalize('  View   Pet  '), 'view pet');
});
