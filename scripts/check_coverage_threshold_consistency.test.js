'use strict';

/**
 * D23: the Flutter domain coverage threshold is one number everywhere it is
 * stated or enforced. Fails when docs and scripts drift apart (was 65% vs 70%).
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

const ROOT = path.resolve(__dirname, '..');

const SOURCES = [
  ['CONTRIBUTING.md', /Flutter domain line coverage ≥ (\d+)%/],
  ['docs/quality/scorecard.md', /Flutter domain \(`lib\/\*\*\/domain\/\*\*`\) \| \*\*(\d+)% line coverage gate\*\*/],
  ['flutter_app/scripts/check_domain_coverage.js', /let threshold = (\d+);/],
  ['flutter_app/scripts/run_tests_ci.sh', /DOMAIN_COVERAGE_THRESHOLD:-(\d+)\}/],
  ['flutter_app/scripts/merge_flutter_coverage.sh', /DOMAIN_COVERAGE_THRESHOLD:-(\d+)\}/],
];

test('Flutter domain coverage threshold agrees across docs and scripts', () => {
  const found = SOURCES.map(([rel, pattern]) => {
    const match = pattern.exec(fs.readFileSync(path.join(ROOT, rel), 'utf8'));
    assert.ok(match, `${rel}: threshold statement not found (pattern ${pattern})`);
    return [rel, Number(match[1])];
  });
  const values = new Set(found.map(([, value]) => value));
  assert.equal(values.size, 1, `thresholds disagree: ${JSON.stringify(Object.fromEntries(found))}`);
});
