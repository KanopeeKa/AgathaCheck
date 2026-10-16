'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { buildSnapshotFromPlan } = require('../lib/execute_plan_snapshot_v2');
const { tick, watchCi } = require('../lib/execute_plan_tick');
const { formatStatusComment, parseStatusComment } = require('../lib/execute_plan_status');

const PLAN_ID = 'proof-build-label-7f3a';
const PLAN_MD = `# Proof

## Goal
x

## Phases

### Phase 1 — First
\`\`\`json
{ "allowed_paths": ["a/**"], "exit_checklist": ["ok"] }
\`\`\`

## Proof on UAT
y
`;
const SNAP = buildSnapshotFromPlan({ planId: PLAN_ID, planMarkdown: PLAN_MD, controlIssue: 9, now: '2026-10-16T09:00:30Z' });
const CONFIG = {
  owners: ['KanopeeKa'], bot_login: 'pawpet-bot',
  required_checks: { integration: ['ci'], main: ['ci', 'scope'] }, uat: { preuat_workflow: 'pre-uat-e2e.yml' },
};
const NOW = '2026-10-16T10:00:00Z';
const EPOCH = '2026-10-16T09:05:00Z';
const HEX = SNAP.approval_hash.replace('sha256:', '');
const baseStatus = (over = {}) => ({
  schema: 1, plan_id: PLAN_ID, init_sha: 'a'.repeat(40), state: 'phase:pending', phase: '1', lease: null, launches: [],
  dispatched: { preuat_heads: [], deploy_tags: [] }, release: null, uat: null, stop: null, updated_at: '2026-10-16T09:40:00Z', ...over,
});
const file = (content) => ({ content: typeof content === 'string' ? content : JSON.stringify(content), sha: 's' });

function stubClient({ status = baseStatus(), labels = [], authorized = true, snapshotAtRef = SNAP } = {}) {
  const writes = [];
  const refs = [];
  const body = formatStatusComment(status, '');
  const client = {
    repo: 'o/r',
    getFileAtRef: async (path, ref) => {
      refs.push(ref);
      if (path.endsWith('execute-plan.config.json')) return file(CONFIG);
      if (path.endsWith('.snapshot.json')) return file(snapshotAtRef);
      return file(PLAN_MD);
    },
    getIssue: async () => ({ number: 9, labels: labels.map((name) => ({ name })) }),
    listIssueComments: async () => [
      { id: 1, user: { login: 'pawpet-bot' }, created_at: '2026-10-16T09:01:00Z', updated_at: '2026-10-16T09:01:00Z', body },
      ...(authorized ? [{ id: 2, user: { login: 'KanopeeKa' }, author_association: 'OWNER', created_at: EPOCH, updated_at: EPOCH, body: `approve-autonomous ${PLAN_ID} sha256:${HEX} until ${SNAP.approved_until}` }] : []),
    ],
    getBranch: async (b) => (b === 'main' ? { commit: { sha: 'm1' } } : b === SNAP.integration_branch ? { commit: { sha: 'i1' } } : null),
    listWorkflowRuns: async () => [],
    compare: async () => ({ ahead_by: 0 }),
    listPulls: async () => [],
    updateComment: async (id, b) => writes.push({ kind: 'update', id, body: b }),
    createComment: async (n, b) => writes.push({ kind: 'comment', n, body: b }),
    addLabels: async (n, l) => writes.push({ kind: 'label', n, labels: l }),
  };
  return { client, writes, refs };
}

test('tick reads snapshot at init_sha not the checkout', async () => {
  const { client, refs } = stubClient();
  const out = await tick(client, { planId: PLAN_ID, controlIssue: 9, now: NOW, actor: 'agent' });
  assert.ok(refs.includes('a'.repeat(40)));
  assert.equal(refs.filter((r) => r !== 'main' && r !== 'a'.repeat(40)).length, 0);
  assert.equal(out.schema, 1);
  assert.equal(out.action.kind, 'create-phase-branch');
  assert.equal(out.action.args.from_sha, 'i1');
});

test('log comment only on state change', async () => {
  const same = stubClient();
  await tick(same.client, { planId: PLAN_ID, controlIssue: 9, now: NOW, actor: 'driver' });
  assert.equal(same.writes.filter((w) => w.kind === 'comment').length, 0);
  const changed = stubClient({ status: baseStatus({ state: 'phase:implementing' }) });
  await tick(changed.client, { planId: PLAN_ID, controlIssue: 9, now: NOW, actor: 'driver' });
  const logs = changed.writes.filter((w) => w.kind === 'comment');
  assert.equal(logs.length, 1);
  assert.match(logs[0].body, /^execute-plan: phase:implementing → phase:pending — /);
});

test('tick dry-run performs no writes', async () => {
  const { client, writes } = stubClient({ status: baseStatus({ state: 'phase:implementing' }) });
  const out = await tick(client, { planId: PLAN_ID, controlIssue: 9, now: NOW, actor: 'driver', dryRun: true });
  assert.equal(writes.length, 0);
  assert.deepEqual(out.writes.map((w) => w.kind), ['update-status', 'log-comment']);
});

test('worker tick refreshes last_tick_at', async () => {
  const lease = { platform: 'cursor', agent_id: 'bc', run_id: 'r', launched_at: '2026-10-16T09:10:00Z', last_tick_at: '2026-10-16T09:40:00Z' };
  const { client, writes } = stubClient({ status: baseStatus({ lease }) });
  await tick(client, { planId: PLAN_ID, controlIssue: 9, now: NOW, actor: 'agent' });
  const upd = writes.find((w) => w.kind === 'update');
  assert.equal(parseStatusComment(upd.body).lease.last_tick_at, NOW);
});

test('stop labels needs-owner and records stop once', async () => {
  const { client, writes } = stubClient({ authorized: false });
  const out = await tick(client, { planId: PLAN_ID, controlIssue: 9, now: NOW, actor: 'driver' });
  assert.equal(out.stop.reason, 'approval-invalid');
  assert.equal(out.action.kind, 'enforce-stop');
  assert.deepEqual(writes.find((w) => w.kind === 'label').labels, ['needs-owner']);
  assert.equal(parseStatusComment(writes.find((w) => w.kind === 'update').body).stop.at, NOW);
  const again = stubClient({ authorized: false, labels: ['needs-owner'] });
  await tick(again.client, { planId: PLAN_ID, controlIssue: 9, now: NOW, actor: 'driver' });
  assert.equal(again.writes.filter((w) => w.kind === 'label').length, 0);
});

function ciClient(runsPerPoll) {
  let i = 0;
  return {
    getFileAtRef: async () => file(CONFIG),
    getPull: async () => ({ base: { ref: 'main' }, head: { sha: 'h' } }),
    listCheckRuns: async () => runsPerPoll[Math.min(i++, runsPerPoll.length - 1)],
  };
}
const ck = (name, status, conclusion = null) => ({ id: 1, name, status, conclusion });

test('watch-ci timeout exits 0 with timedOut', async () => {
  const sleeps = [];
  const out = await watchCi(ciClient([[ck('ci', 'in_progress')]]), { pr: 5, timeoutMin: 2, pollSec: 60, sleep: async (ms) => sleeps.push(ms) });
  assert.deepEqual(out, { timedOut: true, conclusion: null, failing: [] });
  assert.deepEqual(sleeps, [60000]);
});

test('watch-ci returns success on completion and failure early', async () => {
  const sleep = async () => {};
  const ok = await watchCi(ciClient([[ck('ci', 'in_progress')], [ck('ci', 'completed', 'success'), ck('scope', 'completed', 'success')]]), { pr: 5, sleep });
  assert.deepEqual(ok, { timedOut: false, conclusion: 'success', failing: [] });
  const bad = await watchCi(ciClient([[ck('ci', 'completed', 'failure')]]), { pr: 5, sleep });
  assert.deepEqual(bad, { timedOut: false, conclusion: 'failure', failing: ['ci'] });
});
