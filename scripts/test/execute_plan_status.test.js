'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { STATUS_MARKER, parseStatusComment, formatStatusComment, formatLogLine, formatScopeAckNotifyComment, applyDecisionToStatus, mergeStatusBeforeWrite } = require('../lib/execute_plan_status');
const { MAX_LAUNCH_HISTORY } = require('../lib/execute_plan_constants');

const PLAN = 'proof-build-label-7f3a';
const NOW = '2026-10-16T10:00:00Z';
const status = (over = {}) => ({
  schema: 1, plan_id: PLAN, init_sha: '0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c', state: 'phase:pending', phase: '1',
  lease: { platform: 'cursor', agent_id: 'bc-1', run_id: 'r', launched_at: '2026-10-16T09:10:00Z', last_tick_at: '2026-10-16T09:40:00Z' },
  launches: [], dispatched: { preuat_heads: [], deploy_tags: [] }, release: null, uat: null, stop: null, updated_at: '2026-10-16T09:40:00Z', ...over,
});

test('parse/format status round trip', () => {
  const s = status();
  const body = formatStatusComment(s, [{ phase: '1', branch: 'b', pr: '#5', state: 'open', failed: 0, launches: 1 }]);
  assert.ok(body.startsWith(STATUS_MARKER(PLAN)));
  assert.match(body, /\| Phase \| Branch \| PR \| State \| Failed attempts \| Launches \|/);
  assert.deepEqual(parseStatusComment(body), s);
});

test('parseStatusComment rejects non-status bodies', () => {
  assert.equal(parseStatusComment('hello'), null);
  assert.equal(parseStatusComment(`${STATUS_MARKER(PLAN)}\nno json`), null);
  assert.equal(parseStatusComment(`${STATUS_MARKER(PLAN)}\n\`\`\`json\n{bad\n\`\`\``), null);
  assert.equal(parseStatusComment(`text\n${STATUS_MARKER(PLAN)}\n\`\`\`json\n{}\n\`\`\``), null);
});

test('applyDecisionToStatus records stop, keeping an identical current stop', () => {
  const decision = { state: 'stopped', phase: null, stop: { reason: 'ci-budget', detail: 'd' } };
  const a = applyDecisionToStatus(status(), decision, { now: NOW, actor: 'driver' });
  assert.deepEqual(a.stop, { reason: 'ci-budget', detail: 'd', at: NOW });
  assert.equal(a.state, 'stopped');
  const b = applyDecisionToStatus(a, decision, { now: '2026-10-16T10:05:00Z', actor: 'driver', epoch: '2026-10-16T09:05:00Z' });
  assert.equal(b.stop.at, NOW);
  // a stop from before the epoch is replaced
  const c = applyDecisionToStatus(a, decision, { now: '2026-10-17T10:00:00Z', actor: 'driver', epoch: '2026-10-16T12:00:00Z' });
  assert.equal(c.stop.at, '2026-10-17T10:00:00Z');
});

test('applyDecisionToStatus is pure and only refreshes last_tick_at for workers', () => {
  const s = status();
  const d = { state: 'phase:implementing', phase: '1', stop: null };
  const worker = applyDecisionToStatus(s, d, { now: NOW, actor: 'agent' });
  assert.equal(worker.lease.last_tick_at, NOW);
  assert.equal(s.lease.last_tick_at, '2026-10-16T09:40:00Z');
  assert.equal(applyDecisionToStatus(s, d, { now: NOW, actor: 'driver' }).lease.last_tick_at, '2026-10-16T09:40:00Z');
  assert.equal(applyDecisionToStatus(status({ lease: null }), d, { now: NOW, actor: 'agent' }).lease, null);
});

test('applyDecisionToStatus records the merged release PR once and caps launches', () => {
  const launches = Array.from({ length: MAX_LAUNCH_HISTORY + 10 }, (_, i) => ({ at: NOW, phase: '1', kind: 'implement', agent_id: String(i), run_id: 'r' }));
  const obs = { release: { pr: { number: 7, merged_at: NOW, merge_commit_sha: 'abc' } } };
  const n = applyDecisionToStatus(status({ launches }), { state: 'release:merged', phase: null, stop: null }, { now: NOW, actor: 'driver', observations: obs });
  assert.deepEqual(n.release, { pr: 7, merge_sha: 'abc' });
  assert.equal(n.launches.length, MAX_LAUNCH_HISTORY);
  assert.equal(n.launches.at(-1).agent_id, String(MAX_LAUNCH_HISTORY + 9));
});

test('formatLogLine', () => {
  assert.equal(formatLogLine('a', 'b', 'https://x'), 'execute-plan: a → b — https://x');
});

test('formatScopeAckNotifyComment names PR and head', () => {
  const body = formatScopeAckNotifyComment({ repo: 'o/r', pr: 12, headSha: 'a'.repeat(40) });
  assert.match(body, /- PR: #12/);
  assert.match(body, /Approve/);
  assert.match(body, /\*\*not\*\* stopped/);
});

test('applyDecisionToStatus records scope_ack_notify once per PR head while waiting scope-ack', () => {
  const waitAck = {
    state: 'phase:ready',
    phase: '1',
    stop: null,
    action: { actor: 'driver', kind: 'wait', args: { reason: 'scope-ack', pr: 12, head_sha: 'abc1234' } },
  };
  const a = applyDecisionToStatus(status(), waitAck, { now: NOW, actor: 'driver' });
  assert.deepEqual(a.scope_ack_notify, { pr: 12, head_sha: 'abc1234', at: NOW });
  const b = applyDecisionToStatus(a, waitAck, { now: '2026-10-16T10:01:00Z', actor: 'driver' });
  assert.deepEqual(b.scope_ack_notify, a.scope_ack_notify);
  const c = applyDecisionToStatus(a, { state: 'phase:ready', phase: '1', stop: null, action: { actor: 'driver', kind: 'wait', args: { reason: 'checks' } } }, { now: '2026-10-16T10:02:00Z', actor: 'driver' });
  assert.equal(c.scope_ack_notify, undefined);
});

test('table cells escape backslashes, pipes and newlines', () => {
  const body = formatStatusComment(status(), [{ phase: '1', branch: 'a\\|b\nc', pr: null, state: 's', failed: 0, launches: 0 }]);
  assert.match(body, /\| a\\\\\\\|b c \|/);
});

test('mergeStatusBeforeWrite keeps a concurrent current stop and stopped state', () => {
  const epoch = '2026-11-03T23:56:53Z';
  const drift = { reason: 'drift', detail: 'scope forbidden', at: '2026-11-04T08:15:44Z' };
  const baseline = status({ stop: null, state: 'release:open' });
  const proposed = status({
    stop: null,
    state: 'release:open',
    lease: { platform: 'cursor', agent_id: 'a', run_id: 'r', launched_at: '2026-11-04T08:07:46Z', last_tick_at: '2026-11-04T08:15:58Z' },
  });
  const fresh = status({ stop: drift, state: 'stopped', phase: null });
  const merged = mergeStatusBeforeWrite(proposed, fresh, { epoch, baseline });
  assert.deepEqual(merged.stop, drift);
  assert.equal(merged.state, 'stopped');
});

test('mergeStatusBeforeWrite keeps driver drift over stale escalation write', () => {
  const epoch = '2026-10-16T09:05:00Z';
  const baseline = status({ stop: null, state: 'release:open' });
  const drift = { reason: 'drift', detail: 'scope', at: '2026-10-16T10:05:00Z' };
  const fresh = status({ stop: drift, state: 'stopped', updated_at: '2026-10-16T10:05:01Z' });
  const proposed = status({
    stop: { reason: 'escalation', detail: 'control derivation: escalation', at: '2026-10-16T10:06:00Z' },
    state: 'stopped',
  });
  const merged = mergeStatusBeforeWrite(proposed, fresh, { epoch, baseline });
  assert.equal(merged.stop.reason, 'drift');
});

test('mergeStatusBeforeWrite keeps a newer decision stop when it wins on timestamp', () => {
  const epoch = '2026-10-16T09:05:00Z';
  const baseline = status({ stop: { reason: 'drift', detail: 'old', at: '2026-10-16T09:50:00Z' } });
  const fresh = status({ stop: { reason: 'drift', detail: 'old', at: '2026-10-16T09:50:00Z' } });
  const proposed = status({ stop: { reason: 'ci-budget', detail: 'new', at: '2026-10-16T10:00:00Z' }, state: 'stopped' });
  const merged = mergeStatusBeforeWrite(proposed, fresh, { epoch, baseline });
  assert.equal(merged.stop.reason, 'ci-budget');
});

test('mergeStatusBeforeWrite prefers fresher launch tail at equal history length', () => {
  const epoch = '2026-10-16T09:05:00Z';
  const launch = (at, id) => ({ at, phase: '1', kind: 'implement', agent_id: id, run_id: 'r' });
  const cap = Array.from({ length: MAX_LAUNCH_HISTORY }, (_, i) => launch(`2026-10-16T09:${String(i).padStart(2, '0')}:00Z`, String(i)));
  const baseline = status({ launches: cap, updated_at: '2026-10-16T09:30:00Z' });
  const freshCap = cap.slice(1).concat([launch('2026-10-16T10:00:00Z', 'new')]);
  const fresh = status({ launches: freshCap, updated_at: '2026-10-16T10:00:01Z' });
  const proposed = status({ launches: cap, updated_at: NOW });
  const merged = mergeStatusBeforeWrite(proposed, fresh, { epoch, baseline });
  assert.equal(merged.launches.at(-1).agent_id, 'new');
});
