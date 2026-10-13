'use strict';

/**
 * D23: the Flutter domain coverage threshold is one number everywhere it is
 * stated or enforced. Canonical value: flutter-domain-coverage-threshold.json.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

const { readThreshold, REL_JSON } = require('./lib/flutter-domain-coverage-threshold.cjs');

const ROOT = path.resolve(__dirname, '..');

const DOC_SOURCES = [
  ['CONTRIBUTING.md', /Flutter domain line coverage ≥ (\d+)%/],
  ['docs/quality/scorecard.md', /Flutter domain coverage gate \| \*\*(\d+)%\*\*/],
  ['docs/quality/scorecard.md', /Flutter domain \(`lib\/\*\*\/domain\/\*\*`\) \| \*\*(\d+)% line coverage gate\*\*/],
  [REL_JSON, /"threshold":\s*(\d+)/],
];

test('Flutter domain coverage threshold agrees across docs and scripts', () => {
  const canonical = readThreshold(ROOT);
  const found = DOC_SOURCES.map(([rel, pattern]) => {
    const match = pattern.exec(fs.readFileSync(path.join(ROOT, rel), 'utf8'));
    assert.ok(match, `${rel}: threshold statement not found (pattern ${pattern})`);
    return [rel, Number(match[1])];
  });

  const mergeScript = fs.readFileSync(
    path.join(ROOT, 'flutter_app/scripts/merge_flutter_coverage.sh'),
    'utf8',
  );
  assert.match(
    mergeScript,
    /flutter-domain-coverage-threshold\.cjs/,
    'merge_flutter_coverage.sh must read the canonical threshold JSON',
  );

  const runTestsCi = fs.readFileSync(
    path.join(ROOT, 'flutter_app/scripts/run_tests_ci.sh'),
    'utf8',
  );
  assert.match(
    runTestsCi,
    /flutter-domain-coverage-threshold\.cjs/,
    'run_tests_ci.sh must read the canonical threshold JSON',
  );

  const workflow = fs.readFileSync(
    path.join(ROOT, '.github/workflows/_reusable-flutter-coverage.yml'),
    'utf8',
  );
  assert.match(
    workflow,
    /flutter-domain-coverage-threshold\.cjs/,
    'flutter-coverage workflow must resolve threshold from JSON',
  );
  assert.doesNotMatch(
    workflow,
    /DOMAIN_COVERAGE_THRESHOLD:\s*\d+/,
    'workflow must not hardcode DOMAIN_COVERAGE_THRESHOLD',
  );

  for (const [rel, value] of found) {
    assert.equal(value, canonical, `${rel}: expected ${canonical}, got ${value}`);
  }
});
