'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { loadScenario, scenarioFiles, buildBase, deepMerge } = require('./helpers/execute_plan_scenarios');
const { deriveControl, leaseAlive, launchCounts } = require('../lib/execute_plan_control');
const { decide, prLadder } = require('../lib/execute_plan_state');

const files = scenarioFiles();

test('scenario files: 32 P/L/S/R/D present', () => {
  assert.equal(files.filter((f) => /[\\/][plsrd]-/.test(f)).length, 32);
});

for (const file of files) {
  const s = loadScenario(file);
  test(`${path.basename(file, '.json')} (${s.rule}): ${s.name}`, () => {
    const d = decide(s.snapshot, s.obs, s.opts);
    const e = s.expected;
    assert.equal(d.state, e.state);
    assert.equal(d.action.actor, e.actor);
    assert.equal(d.action.kind, e.kind);
    assert.equal(d.action.launch, e.launch);
    if (e.reason) assert.equal(d.action.args.reason, e.reason);
    if (e.method) assert.equal(d.action.args.method, e.method);
    if (e.phase) assert.equal(d.phase, e.phase);
    assert.equal(d.stop ? d.stop.reason : null, e.stop);
  });
}

const NOW = '2026-10-16T10:00:00Z';
const auth = (over) => ({ valid: true, created_at: '2026-10-16T09:05:00Z', until: '2026-10-23T09:00:00Z', ...over });

test('deriveControl order of reasons', () => {
  const stopNew = { reason: 'ci-budget', detail: 'd', at: '2026-10-16T09:30:00Z' };
  const all = { labels: ['autonomous-revoked', 'needs-owner'], authorizing: auth({ valid: false }), revoke_comment_at: null, status: { stop: stopNew } };
  assert.equal(deriveControl(all, { now: NOW }).reason, 'approval-invalid');
  assert.equal(deriveControl({ ...all, authorizing: auth() }, { now: NOW }).reason, 'revoked');
  assert.equal(deriveControl({ ...all, authorizing: auth(), labels: ['needs-owner'], status: null }, { now: NOW }).reason, 'escalation');
  assert.equal(deriveControl({ ...all, authorizing: auth(), labels: ['needs-owner'] }, { now: NOW }).reason, 'ci-budget');
  assert.equal(deriveControl({ labels: [], authorizing: auth({ until: '2026-10-16T09:59:00Z' }), status: null }, { now: NOW }).reason, 'expired');
  const ok = deriveControl({ labels: [], authorizing: auth(), status: { stop: { ...stopNew, at: '2026-10-16T09:00:00Z' } } }, { now: NOW });
  assert.deepEqual(ok, { epoch: '2026-10-16T09:05:00Z', deadline: '2026-10-23T09:00:00Z', stopped: false, reason: null });
  const revokeOlder = deriveControl({ labels: [], authorizing: auth(), revoke_comment_at: '2026-10-16T09:00:00Z' }, { now: NOW });
  assert.equal(revokeOlder.stopped, false);
});

test('leaseAlive with UNKNOWN status uses time only', () => {
  const sl = { last_tick_at: '2026-10-16T09:50:00Z' };
  assert.equal(leaseAlive(sl, { status: 'UNKNOWN' }, { now: NOW }).alive, true);
  assert.equal(leaseAlive({ last_tick_at: '2026-10-16T09:30:00Z' }, { status: 'UNKNOWN' }, { now: NOW }).alive, false);
  assert.equal(leaseAlive(sl, { status: 'RUNNING' }, { now: NOW }).alive, true);
  assert.equal(leaseAlive(sl, { status: 'FINISHED' }, { now: NOW }).alive, false);
  assert.equal(leaseAlive(sl, null, { now: NOW }).alive, false);
  assert.equal(leaseAlive(null, { status: 'RUNNING' }, { now: NOW }).alive, false);
});

test('launchCounts ignores launches before epoch', () => {
  const l = (at, phase) => ({ at, phase });
  const c = launchCounts([l('2026-10-15T09:00:00Z', '1'), l('2026-10-16T09:00:00Z', '1'), l('2026-10-16T09:10:00Z', '1'), l('2026-10-16T09:20:00Z', '2')],
    { epoch: '2026-10-16T09:05:00Z', now: NOW });
  assert.deepEqual(c, { phase: { 1: 1, 2: 1 }, today: 3 });
});

function ladder(prPatch, { kind = 'phase', snapPatch, obsPatch, opts } = {}) {
  const b = buildBase({ snapshot_patch: snapPatch, observations_patch: obsPatch, opts });
  const pr = deepMerge(JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures/execute-plan-v2/scenarios/_base.pr.json'), 'utf8')), prPatch);
  if (kind === 'release') { pr.head_ref = b.snapshot.integration_branch; pr.base_ref = 'main'; }
  const draftAction = kind === 'phase' ? { kind: 'implement', args: { phase: '1', branch: pr.head_ref, base: pr.base_ref, pr: pr.number } } : null;
  return prLadder(pr, { kind, phase: '1', draftAction, method: 'squash', snapshot: b.snapshot, obs: b.obs, opts: b.opts });
}
const red = [{ name: 'ci-gate / CI passed', status: 'completed', conclusion: 'failure', reason: null }];

test('prLadder rules 1–10 each', () => {
  assert.equal(ladder({ labels: ['do-not-merge'] }).stop.reason, 'pr-blocked'); // 1
  assert.equal(ladder({ draft: true }).action.kind, 'implement'); // 2
  assert.equal(ladder({ checks: [{ name: 'execute-plan-scope', conclusion: 'failure', reason: 'protected' }] }).stop.reason, 'drift'); // 3
  assert.equal(ladder({ checks: red }).action.kind, 'fix-ci'); // 4
  assert.equal(ladder({ checks: red, failed_attempts_since_epoch: 3 }).stop.reason, 'ci-budget'); // 4 budget
  assert.equal(ladder({ unresolved_threads: [{ url: 'u', path: 'p', author: 'a' }] }).action.kind, 'triage-review'); // 5
  assert.equal(ladder({ mergeable_state: 'dirty' }).action.kind, 'resolve-conflict'); // 6
  assert.equal(ladder({ mergeable_state: 'dirty' }, { kind: 'release' }).action.kind, 'open-sync-pr'); // 6 release
  assert.equal(ladder({ mergeable_state: 'behind' }).action.kind, 'update-branch'); // 7
  assert.equal(ladder({}, { kind: 'release', snapPatch: { settings: { release_owner_review: true } } }).action.args.reason, 'owner-review'); // 8
  assert.equal(ladder({ owner_approved: true, ready_at: '2026-10-16T08:00:00Z' }, { kind: 'release', snapPatch: { settings: { release_owner_review: true } } }).action.kind, 'arm-auto-merge'); // 8 approved
  assert.equal(ladder({}).action.kind, 'arm-auto-merge'); // 9
  assert.equal(ladder({ auto_merge_enabled: true }).action.args.reason, 'checks'); // 10
});

test('decide is pure of the clock and does not mutate inputs', () => {
  const s = loadScenario(files.find((f) => f.includes('p-ready-arm')));
  const before = JSON.stringify([s.snapshot, s.obs, s.opts]);
  const realNow = Date.now;
  Date.now = () => { throw new Error('Date.now used'); };
  try { decide(s.snapshot, s.obs, s.opts); } finally { Date.now = realNow; }
  assert.equal(JSON.stringify([s.snapshot, s.obs, s.opts]), before);
});
