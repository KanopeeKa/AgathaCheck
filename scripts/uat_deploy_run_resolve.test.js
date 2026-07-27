#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  yymmddFromIso,
  isPreUatBundlingOnlyFailure,
} = require('./lib/uat_deploy_run_resolve');

test('yymmddFromIso extracts UTC date from ISO timestamp', () => {
  assert.equal(yymmddFromIso('2026-07-24T13:50:20Z'), '260724');
  assert.equal(yymmddFromIso(''), null);
});

test('isPreUatBundlingOnlyFailure treats gate-only failure as bundling', () => {
  assert.equal(
    isPreUatBundlingOnlyFailure([
      { gate: 'pre_uat_e2e', job_name: 'Pre-UAT E2E gate', remedial: 'yes' },
    ]),
    true,
  );
});

test('isPreUatBundlingOnlyFailure rejects shard failures', () => {
  assert.equal(
    isPreUatBundlingOnlyFailure([
      {
        gate: 'localhost_e2e',
        job_name: 'Full localhost E2E (5) / Playwright E2E',
        remedial: 'yes',
      },
      { gate: 'pre_uat_e2e', job_name: 'Pre-UAT E2E gate', remedial: 'yes' },
    ]),
    false,
  );
});

test('isPreUatBundlingOnlyFailure rejects flutter build failures', () => {
  assert.equal(
    isPreUatBundlingOnlyFailure([
      { gate: 'flutter_build', job_name: 'Build Flutter web', remedial: 'yes' },
      { gate: 'pre_uat_e2e', job_name: 'Pre-UAT E2E gate', remedial: 'yes' },
    ]),
    false,
  );
});
