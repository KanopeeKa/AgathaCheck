#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createEmptyState,
  isWatcherLeaseActive,
  pruneExpiredWatcher,
  releaseWatcher,
} = require('../lib/uat_queue_lib');
const { recoverStaleWatcher } = require('./uat-queue-recovery');

test('recoverStaleWatcher clears expired lease', async () => {
  const state = createEmptyState();
  state.active_watcher = {
    holder: 'gha-1',
    lease_until: '2026-07-23T12:00:00Z',
    watching_seq: 1,
  };
  const result = await recoverStaleWatcher(state, 'o', 'r', 'token');
  assert.equal(result.changed, true);
  assert.equal(state.active_watcher, null);
});

test('recoverStaleWatcher clears lease when holder workflow completed', async () => {
  const state = createEmptyState();
  const now = new Date('2026-07-23T12:00:00Z');
  state.active_watcher = {
    holder: 'gha-99',
    lease_until: new Date(now.getTime() + 90 * 60 * 1000).toISOString(),
    watching_seq: 1,
  };
  const originalFetch = global.fetch;
  global.fetch = async (url) => ({
    ok: true,
    async text() {
      return JSON.stringify({ status: 'completed' });
    },
  });
  try {
    const result = await recoverStaleWatcher(state, 'o', 'r', 'token');
    assert.equal(result.changed, true);
    assert.equal(state.active_watcher, null);
  } finally {
    global.fetch = originalFetch;
  }
});

test('pruneExpiredWatcher leaves active lease intact', () => {
  const now = new Date('2026-07-23T12:00:00Z');
  const state = createEmptyState();
  state.active_watcher = {
    holder: 'gha-2',
    lease_until: new Date(now.getTime() + 30 * 60 * 1000).toISOString(),
    watching_seq: 2,
  };
  pruneExpiredWatcher(state, now);
  assert.ok(isWatcherLeaseActive(state, now));
});
