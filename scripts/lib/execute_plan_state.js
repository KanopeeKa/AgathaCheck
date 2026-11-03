'use strict';

/**
 * Execute-plan v2 decision logic (pure: reads only its arguments; time is `opts.now`).
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/state-machine.md §4.1–§4.3.
 * Rule ids in comments (D*, P*, S*, PR-ladder *, L*) are the normative ones.
 */

const { deriveControl, leaseAlive, launchCounts } = require('./execute_plan_control');
const { decideUat } = require('./execute_plan_uat');

const DEFAULT_REPO = 'KanopeeKa/AgathaCheck';
const COPILOT_WAIT_MS = 15 * 60 * 1000;
const AUTO_MERGE_FALLBACK_MS = 10 * 60 * 1000;
const MISSING_CHECK_MS = 15 * 60 * 1000;
const MISSING_CHECK_HARD_MS = 2 * 60 * 60 * 1000;
const FAILED = new Set(['failure', 'timed_out', 'action_required']);
const SCOPE_CHECK = 'execute-plan-scope';
const SCOPE_STOP = new Set(['drift', 'protected', 'forbidden']);
const SCOPE_FIXABLE = new Set(['unclassified', 'companion-cap', 'too-many-files']);
const SCOPE_CAUSE = {
  unclassified: 'the phase touches files outside its scope',
  'companion-cap': 'the phase exceeds its companion-file allowance',
  'too-many-files': 'the diff is too large for the scope check to list',
};
const SCOPE_SIDE_FIX_HINT = (reason) => `execute-plan-scope is ${reason}: ${SCOPE_CAUSE[reason] || 'see the check summary'}. `
  + 'If the change is needed to deliver the plan, split it into a plan-linked side PR into the integration branch '
  + '(body: "Unblocks: plan <id> phase <n>" and the blocker; runbooks 7.5), then resume';
const HOLD_LABEL = 'execute-plan-hold';
const BLOCKED_LABEL = 'execute-plan-blocked';
const BLOCKED_BODY_RE = /<!-- execute-plan-blocked:\s*([\s\S]*?)-->/;

/** Detail text when the worker marked the PR blocked (label or HTML comment). */
function workerBlockedDetail(pr) {
  const body = pr && pr.body ? String(pr.body) : '';
  const fromBody = BLOCKED_BODY_RE.exec(body);
  if ((pr.labels || []).includes(BLOCKED_LABEL)) {
    return fromBody ? fromBody[1].trim() : 'worker reported blocked (see PR description)';
  }
  return fromBody ? fromBody[1].trim() : null;
}

const driver = (kind, args = {}) => ({ actor: 'driver', kind, launch: false, args });
const agent = (kind, args = {}) => ({ actor: 'agent', kind, launch: false, args });
const wait = (reason) => driver('wait', { reason });
const prUrl = (opts, n) => `https://github.com/${opts.repo || DEFAULT_REPO}/pull/${n}`;

/** Fill what callers of prLadder / decideUat may omit. */
function normalize(ctx) {
  const { obs, opts } = ctx;
  const control = ctx.control || deriveControl(obs.control, { now: opts.now });
  return { ...ctx, control, status: (obs.control && obs.control.status) || null };
}

function openPlanPrs(obs) {
  const out = [];
  for (const p of obs.phases || []) if (p.pr && p.pr.state === 'open') out.push({ label: `phase ${p.id} PR`, pr: p.pr });
  if (obs.sync && obs.sync.open_pr) out.push({ label: 'sync PR', pr: obs.sync.open_pr });
  if (obs.release && obs.release.pr && obs.release.pr.state === 'open') out.push({ label: 'release PR', pr: obs.release.pr });
  if (obs.remedial && obs.remedial.open_pr) out.push({ label: 'remedial PR', pr: obs.remedial.open_pr });
  return out;
}

function computeBudgets(ctx) {
  const { obs, opts, control, status } = ctx;
  const counts = launchCounts(status && status.launches, { epoch: control.epoch, now: opts.now });
  const failed = {};
  for (const p of obs.phases || []) if (p.pr) failed[p.id] = p.pr.failed_attempts_since_epoch || 0;
  const rel = (obs.release && obs.release.pr) || (obs.remedial && obs.remedial.open_pr);
  if (rel) failed.release = rel.failed_attempts_since_epoch || 0;
  return {
    failed_attempts: failed,
    launches_phase: counts.phase,
    launches_today: counts.today,
    sync_resolves: (obs.sync && obs.sync.resolve_prs_since_epoch) || 0,
    remedial_rounds: (obs.remedial && obs.remedial.merged_since_epoch) || 0,
  };
}

/** Build the decision; a stop always becomes state `stopped` + `enforce-stop` (contracts §3.7). */
function finish(ctx, { state, phase = null, action = null, stop = null, looked = [] }) {
  const open = openPlanPrs(ctx.obs);
  const evidence = (stop && !looked.length ? open : looked).map(({ label, pr }) => ({ label, url: prUrl(ctx.opts, pr.number) }));
  const out = { state, phase, action, stop, evidence, budgets: computeBudgets(ctx) };
  if (stop) {
    out.state = 'stopped';
    out.action = driver('enforce-stop', { prs: open.map((o) => o.pr.number) });
  }
  return out;
}

/**
 * L3/L4: agent actions pass through here; driver actions never do.
 * @returns {{ action?: object, stop?: {reason, detail} }}
 */
function applyLeaseRules(action, ctx) {
  const { opts, status, control, snapshot } = ctx;
  // L3: a worker tick does the action itself.
  if (opts.actor !== 'driver') return { action: { ...action, launch: false } };
  // L4
  if (leaseAlive(status && status.lease, opts.lease, { now: opts.now }).alive) return { action: wait('agent-alive') };
  const counts = launchCounts(status && status.launches, { epoch: control.epoch, now: opts.now });
  const key = ctx.launchKey || 'release';
  const used = counts.phase[key] || 0;
  const { launches_per_phase: perPhase, daily_launches: daily } = snapshot.settings.budgets;
  if (used >= perPhase) return { stop: { reason: 'launch-budget', detail: `${used} launches for ${key} since the epoch (limit ${perPhase})` } };
  if (counts.today >= daily) return { action: wait('daily-cap') };
  return { action: { ...action, launch: true } };
}

function launchOrStop(ctx, base, action, looked) {
  const r = applyLeaseRules(action, ctx);
  return finish(ctx, { ...base, action: r.action || null, stop: r.stop || null, looked });
}

const LADDER_STATE = (ctx, pr) => ({
  phase: pr.draft ? 'phase:implementing' : 'phase:ready',
  sync: 'sync',
  release: 'release:open',
  remedial: 'remedial',
}[ctx.kind]);

/** True when the driver already republished the scope status on `sha` since the epoch (`dispatched.scope_republish`). */
function scopeRepublished(ctx, sha) {
  const list = (ctx.status && ctx.status.dispatched && ctx.status.dispatched.scope_republish) || [];
  const epoch = ctx.control.epoch;
  return list.some((r) => r.sha === sha && (!epoch || Date.parse(r.at) > Date.parse(epoch)));
}

/**
 * PR-ladder 10a: a required check is still absent once every check run on the head has been
 * complete for 15 min, or after 2 h without any activity on the head (a run that never starts).
 */
function missingTimedOut(pr, now) {
  const age = (t) => (t ? Date.parse(now) - Date.parse(t) : -1);
  return age(pr.checks_settled_at) >= MISSING_CHECK_MS || age(pr.head_activity_at) >= MISSING_CHECK_HARD_MS;
}

/** PR-ladder, applied to one open PR. ctx = { kind, draftAction, method, snapshot, obs, opts, control, phase? } */
function prLadder(pr, rawCtx) {
  const ctx = normalize(rawCtx);
  const { kind, snapshot, opts } = ctx;
  ctx.launchKey = ctx.launchKey || (kind === 'phase' ? ctx.phase : 'release');
  const base = { state: LADDER_STATE(ctx, pr), phase: kind === 'phase' ? ctx.phase || null : null };
  const looked = [{ label: kind === 'phase' ? `phase ${ctx.phase} PR` : `${kind} PR`, pr }];
  const stop = (reason, detail) => finish(ctx, { ...base, stop: { reason, detail }, looked });
  const checks = pr.checks || [];
  const budget = snapshot.settings.budgets.ci_per_phase;

  // PR-ladder 1
  if ((pr.labels || []).includes('do-not-merge')) return stop('pr-blocked', `PR #${pr.number} has the do-not-merge label`);
  // PR-ladder 1b — owner drill hold (no STOP; budgets unchanged)
  if ((pr.labels || []).includes(HOLD_LABEL)) return finish(ctx, { ...base, action: wait('hold'), looked });
  const blockedDetail = workerBlockedDetail(pr);
  if (blockedDetail) return stop('worker-blocked', blockedDetail);
  // PR-ladder 2
  if (pr.draft) {
    if (!ctx.draftAction) return finish(ctx, { ...base, action: wait('checks'), looked });
    return launchOrStop(ctx, base, agent(ctx.draftAction.kind, ctx.draftAction.args), looked);
  }
  // PR-ladder 3
  const scope = checks.find((c) => c.name === SCOPE_CHECK);
  if (scope && SCOPE_STOP.has(scope.reason)) return stop('drift', `scope check reports ${scope.reason} on PR #${pr.number}`);
  const republished = scopeRepublished(ctx, pr.head_sha);
  // PR-ladder 3b — the plan is not stopped (D1), so `plan-stopped` is left over from an earlier STOP
  if (scope && scope.conclusion === 'failure' && scope.reason === 'plan-stopped') {
    if (republished) return stop('scope-stale', `execute-plan-scope still reports plan-stopped on PR #${pr.number} after a republish`);
    return finish(ctx, { ...base, action: driver('republish-scope', { pr: pr.number, head_sha: pr.head_sha }), looked });
  }
  if (scope && scope.conclusion === 'failure' && scope.reason === 'recheck-error') {
    if (republished) return stop('check-missing', `execute-plan-scope recheck-error persists on PR #${pr.number} after a republish`);
    return finish(ctx, { ...base, action: driver('republish-scope', { pr: pr.number, head_sha: pr.head_sha }), looked });
  }
  // PR-ladder 4
  const failing = checks.filter((c) => FAILED.has(c.conclusion));
  if (failing.length) {
    const attempts = pr.failed_attempts_since_epoch || 0;
    const only = failing.length === 1 && failing[0].name === SCOPE_CHECK && SCOPE_FIXABLE.has(failing[0].reason);
    if (attempts >= budget) {
      const detail = `${attempts} failed attempts on PR #${pr.number} (limit ${budget})`;
      return stop('ci-budget', only ? `${detail}; ${SCOPE_SIDE_FIX_HINT(failing[0].reason)}` : detail);
    }
    const args = { pr: pr.number, branch: pr.head_ref };
    if (only) return launchOrStop(ctx, base, agent('fix-scope', { ...args, violations: [], scope_reason: failing[0].reason }), looked);
    return launchOrStop(ctx, base, agent('fix-ci', { ...args, failing: failing.map((c) => c.name) }), looked);
  }
  // PR-ladder 5
  if ((pr.unresolved_threads || []).length) {
    const args = { pr: pr.number, branch: pr.head_ref, threads: pr.unresolved_threads.map((t) => t.url) };
    return launchOrStop(ctx, base, agent('triage-review', args), looked);
  }
  // PR-ladder 6
  if (pr.mergeable_state === 'dirty') {
    if (kind === 'release') return finish(ctx, { ...base, action: driver('open-sync-pr', { head: 'main', base: snapshot.integration_branch }), looked });
    return launchOrStop(ctx, base, agent('resolve-conflict', { pr: pr.number, branch: pr.head_ref, base: pr.base_ref }), looked);
  }
  // PR-ladder 7
  if (pr.mergeable_state === 'behind') return finish(ctx, { ...base, action: driver('update-branch', { pr: pr.number }), looked });
  // PR-ladder 8
  if (kind === 'release' && snapshot.settings.release_owner_review && !pr.owner_approved) {
    return finish(ctx, { ...base, action: wait('owner-review'), looked });
  }
  // PR-ladder 9
  if (!pr.auto_merge_enabled) {
    const young = pr.ready_at && Date.parse(opts.now) - Date.parse(pr.ready_at) < COPILOT_WAIT_MS;
    if (pr.base_ref === 'main' && !pr.copilot_review_submitted && young) return finish(ctx, { ...base, action: wait('copilot'), looked });
    const args = { pr: pr.number, method: ctx.method, head_sha: pr.head_sha, scope_republished: republished };
    return finish(ctx, { ...base, action: driver('arm-auto-merge', args), looked });
  }
  // PR-ladder 10a
  const missing = checks.filter((c) => c.status === 'missing').map((c) => c.name);
  if (missing.length && missingTimedOut(pr, opts.now)) {
    if (missing.includes(SCOPE_CHECK) && !republished) {
      return finish(ctx, { ...base, action: driver('republish-scope', { pr: pr.number, head_sha: pr.head_sha }), looked });
    }
    return stop('check-missing', `required check(s) ${missing.join(', ')} never reported on PR #${pr.number} head ${String(pr.head_sha).slice(0, 7)}`);
  }
  // PR-ladder 10 — auto-merge armed: wait for checks, then merge if GitHub does not
  const pending = checks.some((c) => c.status !== 'completed' || c.conclusion !== 'success');
  if (pending) return finish(ctx, { ...base, action: wait('checks'), looked });
  const times = checks.map((c) => c.completed_at).filter(Boolean).map((t) => Date.parse(t));
  const newest = times.length ? Math.max(...times) : 0;
  if (!newest || Date.parse(opts.now) - newest < AUTO_MERGE_FALLBACK_MS) {
    return finish(ctx, { ...base, action: wait('checks'), looked });
  }
  const args = { pr: pr.number, method: ctx.method, head_sha: pr.head_sha, scope_republished: republished };
  return finish(ctx, { ...base, action: driver('merge', args), looked });
}

function stopReasonDetail(ctx) {
  const stop = ctx.status && ctx.status.stop;
  if (stop && stop.reason === ctx.control.reason && stop.detail) return stop.detail;
  return `control derivation: ${ctx.control.reason}`;
}

function decideSync(ctx) {
  const { snapshot, obs } = ctx;
  const sync = obs.sync || {};
  const base = { state: 'sync', phase: null };
  // S1a
  if (!sync.open_pr) return finish(ctx, { ...base, action: driver('open-sync-pr', { head: 'main', base: snapshot.integration_branch }) });
  const looked = [{ label: 'sync PR', pr: sync.open_pr }];
  // S1b
  if (sync.open_pr.mergeable_state === 'dirty') {
    const n = sync.resolve_prs_since_epoch || 0;
    const limit = snapshot.settings.budgets.sync_attempts;
    if (n >= limit) return finish(ctx, { ...base, stop: { reason: 'sync-conflict', detail: `${n} sync resolutions since the epoch (limit ${limit})` }, looked });
    const branch = `cursor/${snapshot.plan_id}-sync-${n + 1}`;
    return launchOrStop(ctx, base, agent('resolve-sync', { sync_pr: sync.open_pr.number, branch }), looked);
  }
  // S1c
  return prLadder(sync.open_pr, { ...ctx, kind: 'sync', draftAction: null, method: 'merge' });
}

/** @returns {{ state, phase, action, stop, evidence, budgets }} */
function decide(snapshot, obs, opts) {
  const control = deriveControl(obs.control, { now: opts.now });
  const ctx = normalize({ snapshot, obs, opts, control });
  // D1
  if (control.stopped) return finish(ctx, { state: 'stopped', stop: { reason: control.reason, detail: stopReasonDetail(ctx) } });
  // D2
  if (obs.uat) return decideUat(snapshot, obs, { ...ctx, prLadder, applyLeaseRules, finish, wait, driver, agent });
  // D3
  const rel = obs.release && obs.release.pr;
  if (rel && rel.state === 'open') return prLadder(rel, { ...ctx, kind: 'release', draftAction: null, method: 'squash' });
  if (rel) return finish(ctx, { state: 'release:merged', action: wait('preuat'), looked: [{ label: 'release PR', pr: rel }] });
  // D4
  const phases = obs.phases || [];
  if (phases.length && phases.every((p) => p.pr && p.pr.merged_at)) {
    if ((obs.integration.behind_main_by || 0) > 0) return decideSync(ctx); // S1
    // S2
    return finish(ctx, { state: 'phase:merged', action: driver('open-release-pr', { head: snapshot.integration_branch, base: 'main' }) });
  }
  // D5 / P1
  const cur = phases.find((p) => !(p.pr && p.pr.merged_at));
  const def = snapshot.phases.find((p) => p.id === cur.id);
  const base = { state: 'phase:pending', phase: cur.id };
  // P2
  if (!cur.pr && !cur.branch_exists) {
    if (!obs.integration.head_sha) {
      return finish(ctx, {
        ...base,
        stop: {
          reason: 'integration-missing',
          detail: `integration branch ${snapshot.integration_branch} is gone and cannot seed phase ${cur.id}`,
        },
      });
    }
    return finish(ctx, { ...base, action: driver('create-phase-branch', { phase: cur.id, branch: def.branch, from_sha: obs.integration.head_sha }) });
  }
  const draftArgs = { phase: cur.id, branch: def.branch, base: snapshot.integration_branch, pr: cur.pr ? cur.pr.number : null };
  // P3
  if (!cur.pr) return launchOrStop({ ...ctx, launchKey: cur.id }, base, agent('implement', draftArgs), []);
  // P4
  return prLadder(cur.pr, { ...ctx, kind: 'phase', phase: cur.id, launchKey: cur.id, draftAction: { kind: 'implement', args: draftArgs }, method: 'squash' });
}

module.exports = { decide, prLadder, applyLeaseRules, HOLD_LABEL, BLOCKED_LABEL, workerBlockedDetail };
