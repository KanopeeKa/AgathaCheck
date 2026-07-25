#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createEmptyState,
  enqueueEntry,
  findActiveEntryByPr,
  applyDeployResult,
} = require('./lib/uat_queue_lib');

test('findActiveEntryByPr ignores superseded entries', () => {
  const state = createEmptyState();
  enqueueEntry(state, { mergeSha: 'abc', prNumber: 361, enqueuedBy: 'pr-361' });
  state.entries[0].state = 'superseded';
  enqueueEntry(state, { mergeSha: 'def', prNumber: 361, enqueuedBy: 'pr-361' });
  const active = findActiveEntryByPr(state, 361);
  assert.equal(active.merge_sha, 'def');
});

test('applyDeployResult matches by PR when entry was backfilled with uat tag', () => {
  const state = createEmptyState();
  enqueueEntry(state, {
    mergeSha: '4a9036584b7f4dc0ccb446b93022c8f4903d2067',
    prNumber: 361,
    enqueuedBy: 'pr-361',
    uatTag: 'uat-260725-361',
  });
  const result = applyDeployResult(state, {
    deployRef: 'uat-260725-361',
    conclusion: 'failure',
    deployRunId: '30162576990',
    gateSummaryRef: 'https://example.com/runs/30162576990',
    gateFailureClass: 'infra_only',
  });
  assert.equal(result.skipped, false);
  assert.equal(result.entry.state, 'infra_failed');
  assert.equal(result.entry.pr_number, 361);
});
