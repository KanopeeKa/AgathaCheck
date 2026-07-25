#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  acquireWatcher,
  applyDeployResult,
  applyRemedialFreeze,
  barrierCheck,
  createEmptyState,
  enqueueEntry,
  expectedUatTag,
  parseStateFromCommentBody,
  parseUatTag,
  pruneExpiredWatcher,
  queueHeadHold,
  renderStateCommentBody,
  setBarrier,
} = require('./lib/uat_queue_lib');
const { STATE_MARKER } = require('./lib/uat_queue_constants');

test('expectedUatTag matches uat-YYMMDD-PR format', () => {
  const tag = expectedUatTag(205, new Date('2026-07-23T12:00:00Z'));
  assert.equal(tag, 'uat-260723-205');
});

test('parseUatTag parses tag', () => {
  assert.deepEqual(parseUatTag('uat-260723-205'), { yymmdd: '260723', prNumber: 205 });
  assert.equal(parseUatTag('main'), null);
});

test('enqueueEntry is idempotent on merge sha', () => {
  let state = createEmptyState();
  const first = enqueueEntry(state, { mergeSha: 'abc123', prNumber: 1, enqueuedBy: 'issue-1' });
  state = first.state;
  const second = enqueueEntry(state, { mergeSha: 'abc123', prNumber: 1, enqueuedBy: 'issue-1' });
  assert.equal(second.created, false);
  assert.equal(second.state.entries.length, 1);
});

test('enqueueEntry freezes when remedial entry exists', () => {
  let state = createEmptyState();
  state.entries.push({
    seq: 1,
    pr_number: 1,
    merge_sha: 'sha1',
    uat_tag: 'uat-260723-1',
    enqueued_by: 'a',
    enqueued_at: 't',
    state: 'remedial',
  });
  const result = enqueueEntry(state, { mergeSha: 'sha2', prNumber: 2, enqueuedBy: 'b' });
  assert.equal(result.entry.state, 'frozen');
});

test('applyRemedialFreeze freezes later pending entries', () => {
  const state = createEmptyState();
  state.entries = [
    { seq: 1, pr_number: 1, merge_sha: 'a', state: 'remedial' },
    { seq: 2, pr_number: 2, merge_sha: 'b', state: 'pending' },
    { seq: 3, pr_number: 3, merge_sha: 'c', state: 'deploying' },
  ];
  applyRemedialFreeze(state, 1);
  assert.equal(state.entries[1].state, 'frozen');
  assert.equal(state.entries[2].state, 'frozen');
});

test('setBarrier unfreezes entries and resolves remedial head', () => {
  let state = createEmptyState();
  state.entries = [
    { seq: 1, pr_number: 1, merge_sha: 'a', state: 'remedial' },
    { seq: 2, pr_number: 2, merge_sha: 'b', state: 'frozen' },
  ];
  setBarrier(state, { sha: 'barrier1', reason: 'fix merged' });
  assert.equal(state.main_barrier_sha, 'barrier1');
  assert.equal(state.entries[0].state, 'superseded');
  assert.equal(state.entries[1].state, 'pending');
});

test('setBarrier resolves failed head entries so promotion can resume', () => {
  const state = createEmptyState();
  state.entries = [
    { seq: 1, pr_number: 333, merge_sha: 'a', state: 'failed' },
    { seq: 2, pr_number: 332, merge_sha: 'b', state: 'pending' },
  ];
  setBarrier(state, { sha: 'fix-sha', reason: 'uat remedial merged' });
  assert.equal(state.entries[0].state, 'superseded');
  assert.equal(state.entries[1].state, 'pending');
  const hold = queueHeadHold(state);
  assert.equal(hold.hold, false);
});

test('pruneExpiredWatcher clears an expired lease', () => {
  const state = createEmptyState();
  state.active_watcher = {
    holder: 'gha-1',
    lease_until: '2026-07-23T12:00:00Z',
    watching_seq: 1,
  };
  pruneExpiredWatcher(state, new Date('2026-07-23T13:00:00Z'));
  assert.equal(state.active_watcher, null);
});

test('acquireWatcher succeeds after pruneExpiredWatcher', () => {
  let state = createEmptyState();
  state.active_watcher = {
    holder: 'gha-old',
    lease_until: '2026-07-23T12:30:00Z',
    watching_seq: 1,
  };
  pruneExpiredWatcher(state, new Date('2026-07-23T14:00:00Z'));
  const acquired = acquireWatcher(state, {
    holder: 'gha-new',
    leaseMinutes: 90,
    now: new Date('2026-07-23T14:00:00Z'),
  });
  assert.equal(acquired.acquired, true);
});

test('applyDeployResult marks success and failure', () => {
  let state = createEmptyState();
  enqueueEntry(state, { mergeSha: 'sha1', prNumber: 201, enqueuedBy: 'x' });
  const ok = applyDeployResult(state, {
    deployRef: 'uat-260723-201',
    conclusion: 'success',
    deployRunId: '99',
  });
  assert.equal(ok.entry.state, 'complete');
  assert.equal(ok.entry.result, 'success');

  state = createEmptyState();
  enqueueEntry(state, { mergeSha: 'sha2', prNumber: 202, enqueuedBy: 'y' });
  const bad = applyDeployResult(state, {
    deployRef: 'uat-260723-202',
    conclusion: 'failure',
    deployRunId: '100',
    gateSummaryRef: 'run 100',
  });
  assert.equal(bad.entry.state, 'failed');
  assert.equal(bad.entry.gate_summary_ref, 'run 100');
});

test('applyDeployResult marks infra-only failure as infra_failed, not failed', () => {
  const state = createEmptyState();
  enqueueEntry(state, { mergeSha: 'sha-infra', prNumber: 210, enqueuedBy: 'z' });
  const result = applyDeployResult(state, {
    deployRef: 'uat-260724-210',
    conclusion: 'failure',
    deployRunId: '101',
    gateFailureClass: 'infra_only',
  });
  assert.equal(result.entry.state, 'infra_failed');
  assert.equal(result.entry.result, 'infra_failure');
});

test('applyDeployResult falls back to failed when gateFailureClass is unknown', () => {
  const state = createEmptyState();
  enqueueEntry(state, { mergeSha: 'sha-unknown', prNumber: 211, enqueuedBy: 'z' });
  const result = applyDeployResult(state, {
    deployRef: 'uat-260724-211',
    conclusion: 'failure',
    deployRunId: '102',
  });
  assert.equal(result.entry.state, 'failed');
});

test('queueHeadHold does not block on an infra_failed head entry', () => {
  const state = createEmptyState();
  state.entries = [
    { seq: 1, pr_number: 1, merge_sha: 'a', state: 'infra_failed' },
    { seq: 2, pr_number: 2, merge_sha: 'b', state: 'pending' },
  ];
  const result = queueHeadHold(state);
  assert.equal(result.hold, false);
  assert.equal(result.reason, 'clear');
});

test('applyDeployResult supersedes earlier pending entries', () => {
  const state = createEmptyState();
  enqueueEntry(state, { mergeSha: 'sha1', prNumber: 301, enqueuedBy: 'a' });
  enqueueEntry(state, { mergeSha: 'sha2', prNumber: 302, enqueuedBy: 'b' });
  enqueueEntry(state, { mergeSha: 'sha3', prNumber: 303, enqueuedBy: 'c' });
  const result = applyDeployResult(state, {
    deployRef: 'uat-260724-303',
    conclusion: 'failure',
    deployRunId: '200',
  });
  assert.equal(state.entries[0].state, 'superseded');
  assert.equal(state.entries[1].state, 'superseded');
  assert.equal(result.entry.state, 'failed');
});

test('acquireWatcher respects active lease', () => {
  let state = createEmptyState();
  const now = new Date('2026-07-23T12:00:00Z');
  const first = acquireWatcher(state, { holder: 'a', leaseMinutes: 90, now });
  state = first.state;
  const second = acquireWatcher(state, { holder: 'b', leaseMinutes: 90, now });
  assert.equal(second.acquired, false);
});

test('barrierCheck detects branch behind barrier', () => {
  const isAncestor = (ancestor, descendant) => {
    if (ancestor === 'barrier' && descendant === 'tip') return false;
    return true;
  };
  const result = barrierCheck({
    barrierSha: 'barrier',
    branchTipSha: 'tip',
    isAncestor,
  });
  assert.equal(result.needs_rebase, true);
});

test('state marker round-trip', () => {
  let state = createEmptyState();
  const enq = enqueueEntry(state, { mergeSha: 'deadbeef', prNumber: 42, enqueuedBy: 'test' });
  const body = renderStateCommentBody(enq.state);
  assert.match(body, new RegExp(STATE_MARKER.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
  assert.ok(enq.state.updated_at);
  const parsed = parseStateFromCommentBody(body);
  assert.equal(parsed.entries.length, 1);
  assert.equal(parsed.entries[0].merge_sha, 'deadbeef');
});

test('parseStateFromCommentBody reads json fence with braces in string values', () => {
  const body = `${STATE_MARKER}
\`\`\`json
{
  "version": 1,
  "updated_at": "2026-07-23T12:00:00Z",
  "main_barrier_sha": "abc",
  "main_barrier_reason": "fix {braces} in reason",
  "main_barrier_at": null,
  "active_watcher": null,
  "entries": []
}
\`\`\``;
  const parsed = parseStateFromCommentBody(body);
  assert.equal(parsed.main_barrier_reason, 'fix {braces} in reason');
});

test('acquireWatcher rejects invalid lease minutes', () => {
  const state = createEmptyState();
  assert.throws(
    () => acquireWatcher(state, { holder: 'a', leaseMinutes: 'bad' }),
    /positive number/
  );
});

test('queueHeadHold blocks on failed or remedial head entry', () => {
  const state = createEmptyState();
  state.entries = [
    { seq: 1, pr_number: 1, merge_sha: 'a', state: 'failed' },
    { seq: 2, pr_number: 2, merge_sha: 'b', state: 'pending' },
  ];
  const failed = queueHeadHold(state);
  assert.equal(failed.hold, true);
  assert.equal(failed.reason, 'head_entry_failed');

  state.entries[0].state = 'remedial';
  const remedial = queueHeadHold(state);
  assert.equal(remedial.hold, true);
  assert.equal(remedial.reason, 'head_entry_remedial');
});

test('queueHeadHold clear when head is pending only', () => {
  const state = createEmptyState();
  state.entries = [{ seq: 1, pr_number: 1, merge_sha: 'a', state: 'pending' }];
  const result = queueHeadHold(state);
  assert.equal(result.hold, false);
  assert.equal(result.reason, 'clear');
});
