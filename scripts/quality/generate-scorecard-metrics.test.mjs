import assert from 'node:assert/strict';
import test from 'node:test';

import {
  collectMetrics,
  formatMetricsMarkdown,
  normalizeTitle,
  THRESHOLDS,
} from './scorecard-lib.mjs';

test('normalizeTitle collapses whitespace and case', () => {
  assert.equal(normalizeTitle('  Foo   Bar  '), 'foo bar');
});

test('collectMetrics reports zero Flutter unowned when shards check passes', () => {
  const m = collectMetrics();
  assert.equal(m.flutter.unowned, 0);
  assert.equal(m.flutter.multiOwned, 0);
  assert.ok(m.flutter.active > 0);
  assert.equal(m.thresholds.flutterDomainCoveragePct, 70);
  assert.equal(m.bdd.gatePct, Math.round(THRESHOLDS.bddGateRatio * 100));
});

test('formatMetricsMarkdown includes domain gate threshold', () => {
  const m = collectMetrics();
  const md = formatMetricsMarkdown(m);
  assert.match(md, /70%/);
  assert.match(md, /68%/);
});
