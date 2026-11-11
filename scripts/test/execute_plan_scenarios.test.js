'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { loadScenario, scenarioFiles, buildBase, deepMerge } = require('./helpers/execute_plan_scenarios');
const { deriveControl, leaseAlive, launchCounts } = require('../lib/execute_plan_control');
const { decide, prLadder } = require('../lib/execute_plan_state');

const files = scenarioFiles();

test('scenario files: P/L/S/R/D present', () => {
  assert.equal(files.filter((f) => /[\\/][plsrd]-/.test(f)).length, 53);
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

test('launchCounts daily total is not truncated below configured daily_launches cap', () => {
  const { MAX_LAUNCH_HISTORY } = require('../lib/execute_plan_constants');
  const launches = Array.from({ length: 85 }, (_, i) => ({
    at: `2026-10-16T${String(9 + (i % 10)).padStart(2, '0')}:${String(i % 60).padStart(2, '0')}:00Z`,
    phase: String((i % 8) + 1),
  }));
  const kept = launches.slice(-MAX_LAUNCH_HISTORY);
  const c = launchCounts(kept, { epoch: '2026-10-16T08:00:00Z', now: NOW });
  assert.equal(c.today, 85);
});

function ladder(prPatch, { kind = 'phase', snapPatch, obsPatch, opts } = {}) {
  const b = buildBase({ snapshot_patch: snapPatch, observations_patch: obsPatch, opts });
  const pr = deepMerge(JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures/execute-plan-v2/scenarios/_base.pr.json'), 'utf8')), prPatch);
  if (kind === 'release') { pr.head_ref = b.snapshot.integration_branch; pr.base_ref = 'main'; }
  const draftAction = kind === 'phase' ? { kind: 'implement', args: { phase: '1', branch: pr.head_ref, base: pr.base_ref, pr: pr.number } } : null;
  return prLadder(pr, { kind, phase: '1', draftAction, method: 'squash', snapshot: b.snapshot, obs: b.obs, opts: b.opts });
}
const red = [{ name: 'ci-gate / CI passed', status: 'completed', conclusion: 'failure', reason: null }];

test('worker-blocked label stops the phase without another worker launch', () => {
  const s = ladder({
    labels: ['execute-plan-blocked'],
    body: '<!-- execute-plan-blocked: flutter-build-web needs budget on main -->',
  }).stop;
  assert.equal(s.reason, 'worker-blocked');
  assert.match(s.detail, /budget on main/);
});

test('worker-blocked label alone stops even when body marker is empty', () => {
  const s = ladder({
    labels: ['execute-plan-blocked'],
    body: '<!-- execute-plan-blocked:   -->',
  }).stop;
  assert.equal(s.reason, 'worker-blocked');
  assert.match(s.detail, /worker reported blocked/);
});

test('ci-budget stop on a fixable scope failure names the plan-linked side PR route', () => {
  const scopeRed = [{ name: 'execute-plan-scope', conclusion: 'failure', reason: 'unclassified' }];
  const s = ladder({ checks: scopeRed, failed_attempts_since_epoch: 3 }).stop;
  assert.equal(s.reason, 'ci-budget');
  assert.match(s.detail, /execute-plan-scope is unclassified/);
  assert.match(s.detail, /Unblocks: plan <id> phase <n>/);
  const cap = ladder({ checks: [{ name: 'execute-plan-scope', conclusion: 'failure', reason: 'companion-cap' }], failed_attempts_since_epoch: 3 }).stop;
  assert.match(cap.detail, /companion-file allowance/);
  assert.doesNotMatch(cap.detail, /outside its scope/);
  assert.doesNotMatch(ladder({ checks: red, failed_attempts_since_epoch: 3 }).stop.detail, /side PR/);
});

test('ci-stuck stops after the same failure signature on three heads', () => {
  const sig = 'ci-gate / CI passed:failure';
  const b = buildBase({
    observations_patch: {
      control: {
        status: {
          ci_stuck_track: {
            1: [
              { sha: 'a'.repeat(40), sig, at: '2026-10-16T09:10:00Z' },
              { sha: 'b'.repeat(40), sig, at: '2026-10-16T09:15:00Z' },
            ],
          },
        },
      },
    },
  });
  const pr = deepMerge(JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures/execute-plan-v2/scenarios/_base.pr.json'), 'utf8')), {
    head_sha: 'c'.repeat(40),
    checks: [{ name: 'ci-gate / CI passed', status: 'completed', conclusion: 'failure', reason: null }],
    failed_attempts_since_epoch: 1,
  });
  const r = prLadder(pr, {
    kind: 'phase',
    phase: '1',
    draftAction: { kind: 'implement', args: { phase: '1', branch: pr.head_ref, base: pr.base_ref, pr: pr.number } },
    method: 'squash',
    snapshot: b.snapshot,
    obs: b.obs,
    opts: b.opts,
  });
  assert.equal(r.stop.reason, 'ci-stuck');
});

test('prLadder rules 1–10 each', () => {
  assert.equal(ladder({ labels: ['do-not-merge'] }).stop.reason, 'pr-blocked'); // 1
  assert.equal(ladder({ labels: ['execute-plan-hold'] }).action.args.reason, 'hold'); // 1b
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
  assert.equal(ladder({ auto_merge_enabled: true }).action.args.reason, 'checks'); // 10 young
  assert.equal(
    ladder(
      { auto_merge_enabled: true, checks: [{ name: 'ci-gate / CI passed', status: 'completed', conclusion: 'success', completed_at: '2026-10-16T09:45:00Z' }, { name: 'execute-plan-scope', status: 'completed', conclusion: 'success', reason: 'ok', completed_at: '2026-10-16T09:46:00Z' }] },
      { opts: { actor: 'driver', lease: null, now: '2026-10-16T10:00:00Z' } },
    ).action.kind,
    'merge',
  );
});

test('merge actions carry the head and whether its scope status was republished this epoch', () => {
  const green = { auto_merge_enabled: true, checks: [{ name: 'ci-gate / CI passed', status: 'completed', conclusion: 'success', completed_at: '2026-10-16T09:45:00Z' }, { name: 'execute-plan-scope', status: 'completed', conclusion: 'success', reason: 'ok', completed_at: '2026-10-16T09:46:00Z' }] };
  const head = 'cccc000000000000000000000000000000000001';
  const ledger = (at) => ({ control: { status: { stop: null, dispatched: { scope_republish: [{ sha: head, at }] } } } });
  const merge = ladder(green).action.args;
  assert.deepEqual(merge, { pr: 1950, method: 'squash', head_sha: head, scope_republished: false });
  assert.equal(ladder(green, { obsPatch: ledger('2026-10-16T09:30:00Z') }).action.args.scope_republished, true);
  assert.equal(ladder(green, { obsPatch: ledger('2026-10-16T09:00:00Z') }).action.args.scope_republished, false);
  assert.equal(ladder({}, { obsPatch: ledger('2026-10-16T09:30:00Z') }).action.args.scope_republished, true);
});

test('decide is pure of the clock and does not mutate inputs', () => {
  const s = loadScenario(files.find((f) => f.includes('p-ready-arm')));
  const before = JSON.stringify([s.snapshot, s.obs, s.opts]);
  const realNow = Date.now;
  Date.now = () => { throw new Error('Date.now used'); };
  try { decide(s.snapshot, s.obs, s.opts); } finally { Date.now = realNow; }
  assert.equal(JSON.stringify([s.snapshot, s.obs, s.opts]), before);
});
