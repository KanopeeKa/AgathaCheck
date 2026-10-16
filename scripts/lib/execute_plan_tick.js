'use strict';

/**
 * Execute-plan v2 `tick` and `watch-ci`: load context → observe → decide → persist → output.
 * `tick` never executes driver actions; it returns them (work-packages-tick.md §WP4b rule 4).
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/contracts.md §3.7.
 */

const { execFileSync } = require('child_process');
const { ExecutePlanError } = require('./execute_plan_constants');
const { decide } = require('./execute_plan_state');
const { deriveControl } = require('./execute_plan_control');
const { loadPlanContext, observe, configError, CONFIG_PATH } = require('./execute_plan_observe');
const { formatStatusComment, formatLogLine, applyDecisionToStatus } = require('./execute_plan_status');

const FAILED = new Set(['failure', 'timed_out', 'action_required']);
const STOP_EXIT_CODE = 2;

const isoNow = () => new Date().toISOString().replace(/\.\d+Z$/, 'Z');

function statusTable(snapshot, obs, decision) {
  const launches = decision.budgets.launches_phase || {};
  return snapshot.phases.map((def) => {
    const p = (obs.phases || []).find((x) => x.id === def.id) || {};
    return {
      phase: def.id,
      branch: def.branch,
      pr: p.pr ? `#${p.pr.number}` : null,
      state: p.pr ? p.pr.state + (p.pr.draft ? ' (draft)' : '') : p.branch_exists ? 'branch' : 'pending',
      failed: p.pr ? p.pr.failed_attempts_since_epoch : 0,
      launches: launches[def.id] || 0,
    };
  });
}

const sameStatus = (a, b) => JSON.stringify({ ...a, updated_at: null }) === JSON.stringify({ ...b, updated_at: null });

async function maybeObserveUat(client, ctx, obs, now) {
  const merged = (obs.release.pr && obs.release.pr.merged_at) || (obs.remedial.merged_since_epoch > 0);
  if (!merged) return null;
  let uatModule = {};
  try {
    uatModule = require('./execute_plan_uat');
  } catch {
    // WP5 not present
  }
  return typeof uatModule.observeUat === 'function' ? uatModule.observeUat(client, ctx, obs, { now }) : null;
}

/** @returns {Promise<object>} contracts §3.7 output (plus `writes` on dry-run) */
async function tick(client, { planId, controlIssue, now = isoNow(), actor = 'agent', lease, dryRun = false, sleep } = {}) {
  const ctx = await loadPlanContext(client, { planId, controlIssue });
  const obs = await observe(client, ctx, { now, sleep });
  obs.uat = await maybeObserveUat(client, ctx, obs, now);
  const opts = { actor, lease: lease === undefined ? (actor === 'agent' ? { status: 'UNKNOWN' } : null) : lease, now, config: ctx.config, repo: client.repo };
  const decision = decide(ctx.snapshot, obs, opts);
  const { epoch } = deriveControl(obs.control, { now });

  const next = applyDecisionToStatus(ctx.status, decision, { now, actor, observations: obs, epoch });
  const writes = [];
  if (!sameStatus(ctx.status, next)) {
    writes.push({ kind: 'update-status', comment_id: ctx.statusComment.id, body: formatStatusComment(next, statusTable(ctx.snapshot, obs, decision)) });
  }
  if (ctx.status.state !== decision.state) {
    const url = (decision.evidence[0] && decision.evidence[0].url) || ctx.issue.html_url || `https://github.com/${client.repo}/issues/${ctx.issueNumber}`;
    writes.push({ kind: 'log-comment', body: formatLogLine(ctx.status.state || 'new', decision.state, url) });
  }
  if (decision.stop && !obs.control.labels.includes('needs-owner')) writes.push({ kind: 'add-label', label: 'needs-owner' });

  if (!dryRun) {
    for (const w of writes) {
      if (w.kind === 'update-status') await client.updateComment(w.comment_id, w.body);
      else if (w.kind === 'log-comment') await client.createComment(ctx.issueNumber, w.body);
      else await client.addLabels(ctx.issueNumber, [w.label]);
    }
  }
  const out = {
    schema: 1,
    plan_id: planId,
    state: decision.state,
    phase: decision.phase,
    action: decision.action,
    stop: decision.stop,
    evidence: decision.evidence,
    budgets: decision.budgets,
  };
  if (dryRun) out.writes = writes.map((w) => (w.kind === 'update-status' ? { kind: w.kind, comment_id: w.comment_id } : w));
  return out;
}

/**
 * Poll the PR head's required checks until all complete (or one fails) or the timeout elapses.
 * Timeout is counted in polls, so the injected `sleep` makes it deterministic.
 * @returns {Promise<{ timedOut: boolean, conclusion: 'success'|'failure'|null, failing: string[] }>}
 */
async function watchCi(client, { pr, timeoutMin = 25, pollSec = 60, sleep = (ms) => new Promise((r) => setTimeout(r, ms)) } = {}) {
  const file = await client.getFileAtRef(CONFIG_PATH, 'main');
  if (!file) throw configError(`${CONFIG_PATH} not found on main`);
  const config = JSON.parse(file.content);
  const polls = Math.max(1, Math.ceil((timeoutMin * 60) / pollSec));
  for (let i = 0; i < polls; i += 1) {
    const pull = await client.getPull(pr);
    const names = pull.base.ref === 'main' ? config.required_checks.main : config.required_checks.integration;
    const runs = await client.listCheckRuns(pull.head.sha);
    const latest = names.map((n) => runs.filter((r) => r.name === n).reduce((a, b) => (!a || Number(b.id) > Number(a.id) ? b : a), null));
    const failing = names.filter((n, k) => latest[k] && latest[k].status === 'completed' && FAILED.has(latest[k].conclusion));
    if (failing.length) return { timedOut: false, conclusion: 'failure', failing };
    if (latest.every((r) => r && r.status === 'completed')) return { timedOut: false, conclusion: 'success', failing: [] };
    if (i < polls - 1) await sleep(pollSec * 1000);
  }
  return { timedOut: true, conclusion: null, failing: [] };
}

function resolveRepo() {
  if (process.env.GITHUB_REPOSITORY) return process.env.GITHUB_REPOSITORY;
  const url = execFileSync('git', ['remote', 'get-url', 'origin'], { encoding: 'utf8' }).trim();
  const m = /github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?$/.exec(url);
  if (!m) throw new ExecutePlanError(`cannot derive owner/name from origin URL ${url}`);
  return m[1];
}

function makeClient() {
  const { createGitHubClient } = require('./execute_plan_github');
  return createGitHubClient({ repo: resolveRepo() });
}

/** CLI: `tick <plan_id> [--issue N] [--json] [--actor agent|driver] [--dry-run]`. Exit 0 action, 2 stop, 3 config. */
async function cliTick(planId, flags) {
  const actor = flags.actor === undefined ? 'agent' : flags.actor;
  if (actor !== 'agent' && actor !== 'driver') throw new ExecutePlanError('--actor must be agent or driver');
  const out = await tick(makeClient(), {
    planId,
    controlIssue: flags.issue === undefined || flags.issue === true ? undefined : Number(flags.issue),
    actor,
    dryRun: Boolean(flags['dry-run']),
  });
  if (flags.json) console.log(JSON.stringify(out, null, 2));
  else console.log(`${out.state}${out.action ? ` → ${out.action.actor}:${out.action.kind}` : ''}${out.stop ? ` (stop: ${out.stop.reason})` : ''}`);
  if (out.stop) process.exitCode = STOP_EXIT_CODE;
}

/** CLI: `watch-ci <plan_id> --pr <n> [--timeout-min 25]`. Timeout exits 0 with `timedOut: true`. */
async function cliWatchCi(planId, flags) {
  if (!flags.pr || flags.pr === true) throw new ExecutePlanError('watch-ci requires --pr <n>');
  const timeoutMin = flags['timeout-min'] === undefined ? 25 : Number(flags['timeout-min']);
  console.log(JSON.stringify(await watchCi(makeClient(), { pr: Number(flags.pr), timeoutMin }), null, 2));
}

module.exports = { tick, watchCi, cliTick, cliWatchCi, STOP_EXIT_CODE };
