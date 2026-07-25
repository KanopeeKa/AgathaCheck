#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  evaluateDeployCadence,
  parseIsoMs,
  resolveCadenceConfig,
} = require('../lib/uat_deploy_cadence');

test('parseIsoMs accepts ISO timestamps', () => {
  assert.ok(parseIsoMs('2026-07-25T12:00:00Z') > 0);
  assert.equal(parseIsoMs(''), null);
});

test('evaluateDeployCadence allows first deploy when no history', () => {
  const decision = evaluateDeployCadence({
    lastDeployStartedAt: null,
    nowMs: Date.parse('2026-07-25T12:00:00Z'),
    minIntervalMinutes: 90,
  });
  assert.equal(decision.status, 'ok');
  assert.equal(decision.reason, 'no_prior_deploy');
});

test('evaluateDeployCadence blocks within 90 minute window', () => {
  const decision = evaluateDeployCadence({
    lastDeployStartedAt: '2026-07-25T12:00:00Z',
    nowMs: Date.parse('2026-07-25T13:00:00Z'),
    minIntervalMinutes: 90,
  });
  assert.equal(decision.status, 'blocked');
  assert.equal(decision.blockReason, 'uat_deploy_cadence');
  assert.equal(decision.minutesSinceLast, 60);
  assert.equal(decision.waitMinutes, 30);
});

test('evaluateDeployCadence allows after 90 minute window', () => {
  const decision = evaluateDeployCadence({
    lastDeployStartedAt: '2026-07-25T12:00:00Z',
    nowMs: Date.parse('2026-07-25T13:30:00Z'),
    minIntervalMinutes: 90,
  });
  assert.equal(decision.status, 'ok');
  assert.equal(decision.reason, 'cadence_elapsed');
  assert.equal(decision.minutesSinceLast, 90);
});

test('evaluateDeployCadence blocks when deploy still running', () => {
  const decision = evaluateDeployCadence({
    lastDeployStartedAt: '2026-07-25T12:00:00Z',
    deployInProgress: true,
    nowMs: Date.parse('2026-07-25T14:00:00Z'),
    minIntervalMinutes: 90,
  });
  assert.equal(decision.status, 'blocked');
  assert.equal(decision.blockReason, 'uat_deploy_in_progress');
});

test('resolveCadenceConfig defaults to 90 minutes', () => {
  const config = resolveCadenceConfig({});
  assert.equal(config.minIntervalMinutes, 90);
  assert.equal(config.enabled, true);
  assert.equal(config.forceRun, false);
});

test('resolveCadenceConfig honors disable and force flags', () => {
  const disabled = resolveCadenceConfig({ UAT_DEPLOY_CADENCE_ENABLED: 'false' });
  assert.equal(disabled.enabled, false);

  const forced = resolveCadenceConfig({ UAT_DEPLOY_CADENCE_FORCE: 'true' });
  assert.equal(forced.forceRun, true);

  const custom = resolveCadenceConfig({ UAT_DEPLOY_MIN_INTERVAL_MINUTES: '120' });
  assert.equal(custom.minIntervalMinutes, 120);
});
