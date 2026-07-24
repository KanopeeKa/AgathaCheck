#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  classifyFailedJob,
  classifyFailedJobs,
  primaryFailedGate,
  shouldEscalate,
  isInfraOnlyFailure,
  buildUatCoordinatorPayload,
} = require('./lib/uat_coordinator_payload');
const {
  clearPromoteHold,
  createEmptyState,
  markEntryRemedial,
  setBarrier,
  setPromoteHold,
} = require('./lib/uat_queue_lib');

test('classifyFailedJob maps smoke job to http_smoke', () => {
  const row = classifyFailedJob({ name: 'HTTP smoke', id: 1, conclusion: 'failure' });
  assert.equal(row.gate, 'http_smoke');
});

test('classifyFailedJobs ignores success jobs', () => {
  const rows = classifyFailedJobs([
    { name: 'build-web', conclusion: 'success' },
    { name: 'uat-e2e-full', conclusion: 'failure', id: 2 },
  ]);
  assert.equal(rows.length, 1);
  assert.equal(rows[0].gate, 'localhost_e2e');
});

test('shouldEscalate for http_smoke primary gate', () => {
  const primary = { gate: 'http_smoke', remedial: 'maybe_infra' };
  assert.equal(shouldEscalate(primary), true);
});

test('buildUatCoordinatorPayload includes remedial branch', () => {
  const payload = buildUatCoordinatorPayload({
    coordinationIssueNumber: 313,
    coordinationIssueUrl: 'https://github.com/o/r/issues/313',
    entry: {
      seq: 1,
      pr_number: 42,
      merge_sha: 'abc',
      uat_tag: 'uat-260724-42',
      state: 'remedial',
    },
    failedGates: [{ gate: 'localhost_e2e', job_name: 'uat-e2e-full', remedial: 'yes' }],
    workflowRunId: '99',
    workflowUrl: 'https://github.com/o/r/actions/runs/99',
    repository: 'https://github.com/o/r',
  });
  assert.equal(payload.failure.pr_number, 42);
  assert.equal(payload.constraints.suggestedBranch, 'cursor/uat-fix-42-2b0b');
  assert.equal(payload.gates.escalate, false);
  assert.deepEqual(payload.verification.after_remedial_merge, [
    'node scripts/uat_queue_runtime.js set-barrier --sha <merge_sha> --write',
    'node scripts/uat_queue_runtime.js release-watcher --write',
  ]);
});

test('setPromoteHold and clearPromoteHold', () => {
  let state = createEmptyState();
  setPromoteHold(state, { reason: 'uat failure' });
  assert.equal(state.promote_hold, true);
  clearPromoteHold(state);
  assert.equal(state.promote_hold, false);
});

test('setBarrier clears promote hold', () => {
  let state = createEmptyState();
  setPromoteHold(state, { reason: 'hold' });
  setBarrier(state, { sha: 'deadbeef', reason: 'fix merged' });
  assert.equal(state.promote_hold, false);
  assert.equal(state.main_barrier_sha, 'deadbeef');
});

test('markEntryRemedial freezes later pending entries', () => {
  let state = createEmptyState();
  state.entries = [
    { seq: 1, pr_number: 1, merge_sha: 'a', state: 'failed' },
    { seq: 2, pr_number: 2, merge_sha: 'b', state: 'pending' },
  ];
  const result = markEntryRemedial(state, { mergeSha: 'a' });
  assert.equal(result.entry.state, 'remedial');
  assert.equal(result.state.entries[1].state, 'frozen');
});

test('isInfraOnlyFailure true when every failed gate is maybe_infra', () => {
  const gates = classifyFailedJobs([
    { name: 'HTTP smoke', conclusion: 'failure', id: 1 },
    { name: 'Build and deploy to UAT', conclusion: 'failure', id: 2 },
  ]);
  assert.equal(isInfraOnlyFailure(gates), true);
});

test('isInfraOnlyFailure false when a code gate also failed', () => {
  const gates = classifyFailedJobs([
    { name: 'HTTP smoke', conclusion: 'failure', id: 1 },
    { name: 'uat-e2e-full', conclusion: 'failure', id: 2 },
  ]);
  assert.equal(isInfraOnlyFailure(gates), false);
});

test('isInfraOnlyFailure false when there are no failed gates', () => {
  assert.equal(isInfraOnlyFailure([]), false);
});

// Real job names captured from a live deploy-uat run (30125158583) — regexes
// must track actual GitHub Actions job.name text, not aspirational job ids.
test('classifyFailedJobs matches real deploy-uat job names and excludes aggregates', () => {
  const gates = classifyFailedJobs([
    { name: 'Build Flutter web / Build Flutter web', conclusion: 'success', id: 1 },
    { name: 'Build and deploy to UAT', conclusion: 'success', id: 2 },
    { name: 'UAT post-deploy smoke', conclusion: 'failure', id: 3 },
    { name: 'UAT live smoke E2E', conclusion: 'skipped', id: 4 },
    { name: 'Prod ready', conclusion: 'failure', id: 5 },
    { name: 'UAT full E2E (localhost)', conclusion: 'skipped', id: 6 },
    { name: 'UAT release conclusion', conclusion: 'failure', id: 7 },
  ]);
  assert.equal(gates.length, 1);
  assert.equal(gates[0].gate, 'http_smoke');
  assert.equal(isInfraOnlyFailure(gates), true);
});

test('classifyFailedJob matches real job names for deploy, build, and localhost E2E', () => {
  assert.equal(classifyFailedJob({ name: 'Build and deploy to UAT', conclusion: 'failure' }).gate, 'deploy');
  assert.equal(
    classifyFailedJob({ name: 'Build Flutter web / Build Flutter web', conclusion: 'failure' }).gate,
    'flutter_build',
  );
  assert.equal(
    classifyFailedJob({ name: 'UAT full E2E (localhost)', conclusion: 'failure' }).gate,
    'localhost_e2e',
  );
});

test('primaryFailedGate prefers migrations over e2e', () => {
  const primary = primaryFailedGate([
    { gate: 'localhost_e2e' },
    { gate: 'migrations' },
  ]);
  assert.equal(primary.gate, 'migrations');
});
