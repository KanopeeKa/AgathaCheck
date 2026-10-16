'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { STATUS_MARKER, parseStatusComment, formatStatusComment, formatLogLine, applyDecisionToStatus } = require('../lib/execute_plan_status');

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
  const launches = Array.from({ length: 60 }, (_, i) => ({ at: NOW, phase: '1', kind: 'implement', agent_id: String(i), run_id: 'r' }));
  const obs = { release: { pr: { number: 7, merged_at: NOW, merge_commit_sha: 'abc' } } };
  const n = applyDecisionToStatus(status({ launches }), { state: 'release:merged', phase: null, stop: null }, { now: NOW, actor: 'driver', observations: obs });
  assert.deepEqual(n.release, { pr: 7, merge_sha: 'abc' });
  assert.equal(n.launches.length, 50);
  assert.equal(n.launches.at(-1).agent_id, '59');
});

test('formatLogLine', () => {
  assert.equal(formatLogLine('a', 'b', 'https://x'), 'execute-plan: a → b — https://x');
});
