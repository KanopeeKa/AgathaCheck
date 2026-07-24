#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createEmptyState, setPromoteHold } = require('../lib/uat_queue_lib');
const { queueHeadHold } = require('../lib/uat_queue_lib');

test('queueHeadHold blocks on promote_hold flag', () => {
  const state = createEmptyState();
  setPromoteHold(state, { reason: 'deploy failure' });
  const hold = queueHeadHold(state);
  assert.equal(hold.hold, true);
  assert.equal(hold.reason, 'promote_hold');
});

test('queueHeadHold blocks on failed head entry', () => {
  const state = createEmptyState();
  state.entries = [
    { seq: 1, pr_number: 1, merge_sha: 'abc', state: 'failed' },
    { seq: 2, pr_number: 2, merge_sha: 'def', state: 'pending' },
  ];
  const hold = queueHeadHold(state);
  assert.equal(hold.hold, true);
  assert.equal(hold.reason, 'head_entry_failed');
});

test('queueHeadHold clear when only pending entries and no promote hold', () => {
  const state = createEmptyState();
  state.entries = [{ seq: 1, pr_number: 1, merge_sha: 'abc', state: 'pending' }];
  const hold = queueHeadHold(state);
  assert.equal(hold.hold, false);
});
