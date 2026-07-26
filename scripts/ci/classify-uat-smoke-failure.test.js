#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('child_process');
const path = require('path');

const script = path.join(__dirname, 'classify-uat-smoke-failure.sh');

function runClassify(env) {
  return execFileSync('bash', [script], {
    env: { ...process.env, ...env },
    encoding: 'utf8',
  }).trim();
}

test('classify-uat-smoke-failure: health+warmup success emits empty kind', () => {
  const out = runClassify({
    HEALTH_OUTCOME: 'success',
    WARMUP_OUTCOME: 'success',
    HEALTH_FAILURE_KIND: '',
  });
  assert.match(out, /smoke_failure_kind=$/);
});

test('classify-uat-smoke-failure: health failure preserves health kind', () => {
  const out = runClassify({
    HEALTH_OUTCOME: 'failure',
    WARMUP_OUTCOME: 'skipped',
    HEALTH_FAILURE_KIND: 'passenger_crash',
  });
  assert.match(out, /smoke_failure_kind=passenger_crash/);
});

test('classify-uat-smoke-failure: warmup failure after healthy health is waf', () => {
  const out = runClassify({
    HEALTH_OUTCOME: 'success',
    WARMUP_OUTCOME: 'failure',
    HEALTH_FAILURE_KIND: '',
  });
  assert.match(out, /smoke_failure_kind=waf/);
});

test('classify-uat-smoke-failure: combined live gate without WAF signals stays unclassified', () => {
  const out = runClassify({
    HEALTH_OUTCOME: 'success',
    WARMUP_OUTCOME: 'failure',
    COMBINED_LIVE_GATE: 'true',
    PLAYWRIGHT_REPORT_DIR: '/nonexistent',
    HEALTH_FAILURE_KIND: '',
  });
  assert.match(out, /smoke_failure_kind=$/);
});

test('classify-uat-smoke-failure: combined live gate detects WAF in test-results', () => {
  const fs = require('fs');
  const os = require('os');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'uat-classify-'));
  const resultsDir = path.join(tmp, 'test-results');
  fs.mkdirSync(resultsDir, { recursive: true });
  fs.writeFileSync(
    path.join(resultsDir, 'error-context.md'),
    'UAT auth signup is still blocked by hosting WAF',
  );
  try {
    const out = runClassify({
      HEALTH_OUTCOME: 'success',
      WARMUP_OUTCOME: 'failure',
      COMBINED_LIVE_GATE: 'true',
      PLAYWRIGHT_REPORT_DIR: '/nonexistent',
      PLAYWRIGHT_RESULTS_DIR: resultsDir,
      HEALTH_FAILURE_KIND: '',
    });
    assert.match(out, /smoke_failure_kind=waf/);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
