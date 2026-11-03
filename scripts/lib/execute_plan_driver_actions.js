'use strict';

/**
 * Execute-plan v2 driver: one pass for one plan = tick (actor `driver`) + execute the returned
 * driver action, or launch the worker for an agent action with `launch: true`.
 * The driver never waits inside a job. Spec: work-packages-platform.md §WP7b, contracts.md §3.5-3.8.
 *
 * `clients` = { bot, read, cursorApiKey, botToken, deps? }
 *   bot  — GitHub client on EXECUTE_PLAN_BOT_TOKEN (writes that must trigger workflows, status, labels)
 *   botToken — EXECUTE_PLAN_BOT_TOKEN itself, handed to each launched worker (never the GITHUB_TOKEN fallback)
 *   read — GitHub client on GITHUB_TOKEN (reads, workflow_dispatch, the execute-plan-scope check run)
 *   deps — test seams: tick, completePlan, loadPlanContext, runScopeCheck, publishScopeCheck, publishScopeResult,
 *          launchPlanAgent, getAgentRunStatus
 */

const { GitHubError } = require('./execute_plan_github');
const { HOLD_LABEL, BLOCKED_LABEL, appendCiStuckTrack, failureSignature } = require('./execute_plan_state');
const { formatStatusComment, parseStatusComment } = require('./execute_plan_status');
const { MAX_LAUNCH_HISTORY } = require('./execute_plan_constants');
const { workerLaunchEnvVars } = require('../../.github/scripts/execute-plan-launch');

const MAX_REPUBLISHES = 20;
const SCOPE_CHECK = 'execute-plan-scope';
// 405 wording when a required check has no usable result (probed 2026-11-02, see the v2 decision log).
const UNCOUNTED_CHECK_RE = /Required status check "([^"]+)" (?:is expected|was not set by the expected GitHub app)/;
const STOP_CODES = new Set(['merge-blocked', 'check-missing']);
const MAX_LISTED_FILES = 100;
const FENCE_RE = /```json\s*\n[\s\S]*?\n```/;
const FIX_KINDS = new Set(['fix-ci', 'fix-scope', 'triage-review', 'resolve-conflict', 'remedial']);
const KILL_SWITCH_VALUES = new Set(['off', 'dry-run', 'on']);

const isoNow = () => new Date().toISOString().replace(/\.\d+Z$/, 'Z');

function prObsFromCtx(obs, prNumber) {
  const n = Number(prNumber);
  if (!obs || !Number.isInteger(n)) return null;
  for (const p of obs.phases || []) if (p.pr && p.pr.number === n) return p.pr;
  if (obs.sync && obs.sync.open_pr && obs.sync.open_pr.number === n) return obs.sync.open_pr;
  if (obs.release && obs.release.pr && obs.release.pr.number === n) return obs.release.pr;
  if (obs.remedial && obs.remedial.open_pr && obs.remedial.open_pr.number === n) return obs.remedial.open_pr;
  return null;
}

/** Anything but `on` / `dry-run` (unset, typo) is `off`: the safe reading of the kill switch. */
function normalizeKillSwitch(value) {
  const v = String(value == null ? '' : value).trim().toLowerCase();
  return KILL_SWITCH_VALUES.has(v) ? v : 'off';
}

function defaultDeps() {
  const { tick, completePlan } = require('./execute_plan_tick');
  const { loadPlanContext, observe } = require('./execute_plan_observe');
  const { runScopeCheck, publishScopeCheck, publishScopeResult } = require('./execute_plan_scope_run');
  const { launchPlanAgent, getAgentRunStatus } = require('../../.github/scripts/execute-plan-launch');
  return { tick, completePlan, loadPlanContext, observe, runScopeCheck, publishScopeCheck, publishScopeResult, launchPlanAgent, getAgentRunStatus };
}

const ACTION_TEXT = {
  implement: 'build the phase on its branch (draft PR first)',
  'fix-ci': 'make the failing required checks green',
  'fix-scope': 'remove out-of-scope files; if one is required for the phase, keep it out of this PR, name it in the PR description and end with "worker done: blocked execute-plan-scope: <file>" so the owner can land it as a plan-linked side PR',
  'triage-review': 'triage every unresolved review thread (autonomous-pr-policy §Review triage: fix must-fix and safe nits, debt issue for the rest), then reply on and resolve each one',
  'resolve-conflict': 'merge the base into the branch and fix the conflicts',
  'resolve-sync': 'merge main into a new branch off the integration branch, fix conflicts, open a PR into integration',
  remedial: 'fix the UAT failure; open a PR into main',
};

function evidenceText(action) {
  const a = action.args || {};
  if (a.failing) return a.failing.join(', ');
  if (a.threads) return a.threads.join(', ');
  if (a.violations && a.violations.length) return a.violations.map((v) => `${v.file} (${v.reason})`).join(', ');
  if (a.scope_reason) return `execute-plan-scope: ${a.scope_reason}`;
  if (a.sync_pr) return `sync PR #${a.sync_pr}`;
  if (a.evidence) return [].concat(a.evidence).join(', ');
  return 'none';
}

/** Contracts §3.6. `ctx` = { base?: string } resolved by the caller (the PR's base ref). */
function buildHandoffPrompt(decision, snapshot, planMarkdown, { base } = {}) {
  const { action } = decision;
  const a = action.args || {};
  const phase = snapshot.phases.find((p) => p.id === (a.phase || decision.phase)) || snapshot.phases.find((p) => p.branch === a.branch);
  const resolvedBase = a.base || base || snapshot.integration_branch;
  const list = (items) => (items && items.length ? items.join(', ') : 'none');
  const id = snapshot.plan_id;
  return [
    `/execute-plan ${id}`,
    '',
    `You are a worker for execute-plan ${id}. Do exactly the action below. Then run`,
    `\`env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN node scripts/execute_plan_runtime.js tick ${id} --json --actor agent\` and continue with what`,
    'it returns, until it returns an action whose actor is "driver", or a stop. Then end your turn',
    'with one line: "worker done: <state>".',
    '',
    `Action: ${action.kind} — ${ACTION_TEXT[action.kind] || action.kind}`,
    `Branch: ${a.branch || 'none'}   Base: ${resolvedBase}   PR: ${a.pr || a.sync_pr ? `#${a.pr || a.sync_pr}` : 'none'}   Phase: ${phase ? `${phase.id} "${phase.title}"` : 'none'}`,
    `Scope (allowed): ${phase ? list(phase.allowed_paths) : 'see the plan file'}   Companions: ${phase ? list(phase.companions) : 'none'}`,
    `Forbidden: the protected set (scripts/lib/execute_plan_scope.js) + ${phase ? list(phase.forbidden_paths) : 'none'}`,
    `Evidence: ${evidenceText(action)}`,
    `Plan file: .agents/plans/${id}.md (read it first; never edit it or the snapshot)`,
    '',
    `Rules: if no PR exists, open a draft PR into ${resolvedBase} right after your first commit. Run`,
    './scripts/pre-push-changed.sh before every push and push only when it is green (one push per batch of',
    'fixes: every push costs a full CI run and counts as an attempt against the phase budget); mark the PR',
    'ready only after it is green; never touch protected paths; never approve, merge or close anything;',
    'never add labels except `execute-plan-blocked` when blocked per below; never edit the control issue yourself.',
    'If a failing check cannot be fixed inside your scope (it needs a protected path, a CI gate or another',
    'budget file; the web bundle budget below is the exception), do not work around it and do not retry:',
    'add the `execute-plan-blocked` label to the PR, put `<!-- execute-plan-blocked: <reason> -->` in the',
    'PR body, describe the cause, and end your turn with "worker done: blocked <check>: <reason>".',
    '',
    'Web bundle budget (scripts/ci/web-bundle-budget.json): when the flutter-build-web job fails on',
    'check-web-bundle-budget.mjs and the overshoot comes from this phase\'s planned code',
    'the measured size plus about 1% and give before/after bytes in the PR body. Never cut planned scope to',
    'fit. A jump over about 1.5% of main.dart.js, or one you cannot explain, gets one trimming attempt',
    '(deferred import, drop the asset); if it is still over, report it as blocked with the numbers.',
  ].join('\n');
}

/** Rewrite only the JSON block of the status comment, keeping the table below it. */
async function updateStatus(bot, ctx, mutate, now) {
  const comments = await bot.listIssueComments(ctx.issueNumber);
  const current = comments.find((c) => c.id === ctx.statusComment.id);
  const status = current && parseStatusComment(current.body);
  if (!status) throw new Error(`status comment ${ctx.statusComment.id} vanished or is malformed`);
  const next = { ...mutate(status), updated_at: now };
  const block = `\`\`\`json\n${JSON.stringify(next, null, 2)}\n\`\`\``;
  const body = FENCE_RE.test(current.body) ? current.body.replace(FENCE_RE, () => block) : formatStatusComment(next, '');
  await bot.updateComment(ctx.statusComment.id, body);
  return next;
}

async function ignoreRefExists(promise) {
  try {
    await promise;
  } catch (e) {
    if (!(e instanceof GitHubError && e.status === 422 && /already exists/i.test(e.message))) throw e;
  }
}

async function openOnce(bot, { head, base, title, body }) {
  const [open] = await bot.listPulls({ head, base, state: 'open', pages: 1 });
  if (open) return `PR #${open.number} already open`;
  const pr = await bot.createPull({ title, head, base, body, draft: false });
  return `opened PR #${pr.number}`;
}

function releaseBody(ctx, files) {
  const { snapshot, planId, issueNumber } = ctx;
  const docs = files.filter((f) => f.startsWith('docs/'));
  const shown = docs.slice(0, MAX_LISTED_FILES).map((f) => `- \`${f}\``);
  if (docs.length > MAX_LISTED_FILES) shown.push(`- … and ${docs.length - MAX_LISTED_FILES} more`);
  return [
    `<!-- execute-plan-release:${planId} -->`,
    `Release for execute-plan \`${planId}\` (control issue #${issueNumber}).`,
    '',
    '| Phase | Title | Branch |',
    '|-------|-------|--------|',
    ...snapshot.phases.map((p) => `| ${p.id} | ${p.title} | \`${p.branch}\` |`),
    '',
    '## Docs',
    docs.length ? shown.join('\n') : 'N/A — no documentation files changed in this release',
  ].join('\n');
}

async function enforceStop(clients, decision, now) {
  const { bot, read, deps } = clients;
  const reason = (decision.stop && decision.stop.reason) || 'stopped';
  const done = [];
  for (const number of decision.action.args.prs || []) {
    const pull = await bot.getPull(number);
    if (pull.auto_merge) await bot.disableAutoMerge(pull.node_id);
    await deps.publishScopeCheck(read, {
      headSha: pull.head.sha,
      conclusion: 'failure',
      title: 'plan-stopped',
      summary: `plan stopped: ${reason}`,
    });
    done.push(`#${number}`);
  }
  return `stop enforced (${reason}) on ${done.length ? done.join(', ') : 'no open PR'} at ${now}`;
}

/** Re-evaluate and publish `execute-plan-scope` on the PR head (trusted `main` code, `GITHUB_TOKEN`); recorded once per head. */
async function republishScope(clients, ctx, { pr, headSha }, now) {
  const { bot, read, deps } = clients;
  const pull = await bot.getPull(pr);
  if (headSha && pull.head.sha !== headSha) return `#${pr} head moved to ${pull.head.sha.slice(0, 7)}: nothing republished`;
  let outcome;
  try {
    outcome = await deps.runScopeCheck(read, {
      prNumber: pr,
      headSha: pull.head.sha,
      headRef: pull.head.ref,
      baseRef: pull.base.ref,
      headRepo: pull.head.repo && pull.head.repo.full_name,
      repo: read.repo,
      now: new Date(now),
    });
  } catch (e) {
    outcome = { conclusion: 'failure', title: 'drift', summary: `scope check could not complete: ${e.message}` };
  }
  outcome = await deps.publishScopeResult(read, { headSha: pull.head.sha, outcome, now: new Date(now) });
  await updateStatus(bot, ctx, (s) => {
    const d = s.dispatched || {};
    const list = [...(d.scope_republish || []), { sha: pull.head.sha, at: now }].slice(-MAX_REPUBLISHES);
    return { ...s, dispatched: { ...d, scope_republish: list } };
  }, now);
  return `republished ${SCOPE_CHECK} on #${pr}: ${outcome.conclusion} (${outcome.title})`;
}

function stopError(code, detail, pr) {
  const err = new Error(detail);
  err.code = code;
  err.detail = detail;
  err.pr = pr;
  return err;
}

/**
 * Merge directly. A 405 for an uncounted `execute-plan-scope` republishes it once per head; any
 * other uncounted check, or a second refusal, stops `check-missing`; every other refusal `merge-blocked`.
 */
async function mergeOrRecover(clients, ctx, a, now) {
  try {
    await clients.bot.mergePull(a.pr, { method: a.method });
    return null;
  } catch (e) {
    const detail = e instanceof GitHubError ? e.message : String(e);
    const m = e instanceof GitHubError && e.status === 405 ? UNCOUNTED_CHECK_RE.exec(detail) : null;
    if (!m) throw stopError('merge-blocked', detail, a.pr);
    if (m[1] === SCOPE_CHECK && !a.scope_republished) {
      const done = await republishScope(clients, ctx, { pr: a.pr, headSha: a.head_sha }, now);
      return `merge refused (${SCOPE_CHECK} not counted); ${done}`;
    }
    throw stopError('check-missing', detail, a.pr);
  }
}

async function launchWorker(clients, ctx, decision, now) {
  const { bot, deps, cursorApiKey, botToken } = clients;
  const { snapshot, config } = ctx;
  const { action } = decision;
  const a = action.args || {};
  if (!cursorApiKey) throw new Error('cursor_api_key is not available: cannot launch a worker');
  // A worker holding the owner's token could forge approvals: it must act as the bot or not launch at all.
  if (!botToken) throw new Error('EXECUTE_PLAN_BOT_TOKEN is not set: refusing to launch a worker');

  // New branches for sync resolution and remedial work; the others already exist.
  if (action.kind === 'resolve-sync' || action.kind === 'remedial') {
    const from = (await bot.getBranch(action.kind === 'resolve-sync' ? snapshot.integration_branch : 'main'));
    if (!from) throw new Error(`cannot create ${a.branch}: source branch missing`);
    if (!(await bot.getBranch(a.branch))) await ignoreRefExists(bot.createRef(`refs/heads/${a.branch}`, from.commit.sha));
  }
  const pullNumber = a.pr || a.sync_pr;
  const base = !a.base && pullNumber ? (await bot.getPull(pullNumber)).base.ref : a.base;
  const prompt = buildHandoffPrompt(decision, snapshot, ctx.planMarkdown, { base });
  const model = FIX_KINDS.has(action.kind) ? config.cursor_model_fix : config.cursor_model_implement;
  const launched = await deps.launchPlanAgent({
    apiKey: cursorApiKey,
    repoUrl: `https://github.com/${bot.repo}`,
    startingRef: a.branch,
    prompt,
    model,
    envVars: workerLaunchEnvVars(botToken),
  });
  const key = decision.phase || 'release';
  const obs = await deps.observe(bot, ctx, { now });
  const prObs = pullNumber ? prObsFromCtx(obs, pullNumber) : null;
  const sig = prObs ? failureSignature(prObs) : null;
  await updateStatus(bot, ctx, (s) => {
    const tracked = appendCiStuckTrack(s, key, prObs && prObs.head_sha, sig, now);
    return {
      ...tracked,
      launches: [...(tracked.launches || []), { at: now, phase: key, kind: action.kind, agent_id: launched.agentId, run_id: launched.runId }].slice(-MAX_LAUNCH_HISTORY),
      lease: { platform: 'cursor', agent_id: launched.agentId, run_id: launched.runId, launched_at: now, last_tick_at: now },
    };
  }, now);
  return `launched ${action.kind} on ${a.branch} (agent ${launched.agentId})`;
}

async function executeDriverAction(clients, ctx, decision, now) {
  const { bot, read } = clients;
  const { action } = decision;
  const a = action.args || {};
  switch (action.kind) {
    case 'create-phase-branch':
      await ignoreRefExists(bot.createRef(`refs/heads/${a.branch}`, a.from_sha));
      return `created ${a.branch} at ${a.from_sha}`;
    case 'arm-auto-merge': {
      const pull = await bot.getPull(a.pr);
      try {
        await bot.enableAutoMerge(pull.node_id, a.method);
        return `auto-merge armed on #${a.pr} (${a.method})`;
      } catch (e) {
        if (!(e instanceof GitHubError && /clean status/i.test(e.message))) throw e;
        return (await mergeOrRecover(clients, ctx, a, now)) || `#${a.pr} already clean: merged (${a.method})`;
      }
    }
    case 'merge':
      return (await mergeOrRecover(clients, ctx, a, now)) || `merged #${a.pr} (${a.method})`;
    case 'republish-scope':
      return republishScope(clients, ctx, { pr: a.pr, headSha: a.head_sha }, now);
    case 'update-branch':
      await bot.updateBranch(a.pr);
      return `updated branch of #${a.pr}`;
    case 'open-sync-pr':
      return openOnce(bot, {
        head: 'main',
        base: a.base,
        title: `execute-plan sync: main → ${a.base}`,
        body: `<!-- execute-plan-sync:${ctx.planId} -->\nMerge \`main\` into \`${a.base}\` for execute-plan \`${ctx.planId}\`.`,
      });
    case 'open-release-pr': {
      const { files } = await bot.compare('main', a.head);
      return openOnce(bot, {
        head: a.head,
        base: 'main',
        title: `Release: ${ctx.snapshot.title} (${ctx.planId})`,
        body: releaseBody(ctx, files.map((f) => f.filename)),
      });
    }
    case 'dispatch-preuat':
      await read.dispatchWorkflow(ctx.config.uat.preuat_workflow, 'main');
      await updateStatus(bot, ctx, (s) => {
        const d = s.dispatched || {};
        return { ...s, dispatched: { ...d, preuat_heads: [...(d.preuat_heads || []), a.main_head_sha] } };
      }, now);
      return `dispatched ${ctx.config.uat.preuat_workflow} for main ${a.main_head_sha}`;
    case 'dispatch-deploy':
      await read.dispatchWorkflow(ctx.config.uat.deploy_workflow, 'main', { deploy_ref: a.tag });
      await updateStatus(bot, ctx, (s) => {
        const d = s.dispatched || {};
        return { ...s, dispatched: { ...d, deploy_tags: [...(d.deploy_tags || []), a.tag] } };
      }, now);
      return `re-dispatched ${ctx.config.uat.deploy_workflow} for ${a.tag}`;
    case 'enforce-stop':
      return enforceStop(clients, decision, now);
    case 'complete-plan': {
      const res = await clients.deps.completePlan(bot, { planId: ctx.planId, controlIssue: ctx.issueNumber, now });
      return res.complete ? 'plan complete' : `not complete: ${res.missing}`;
    }
    default:
      throw new Error(`unknown driver action ${action.kind}`);
  }
}

/**
 * @returns {Promise<{ planId: string, skipped?: string, decision?: object, executed: boolean, outcome?: string }>}
 */
async function runDriverPass(clients, { planId, issueNumber, now = isoNow(), killSwitch, log = () => {} }) {
  const sw = normalizeKillSwitch(killSwitch);
  if (sw === 'off') {
    log(`plan ${planId}: kill switch off — nothing done`);
    return { planId, skipped: 'kill-switch-off', executed: false };
  }
  const deps = { ...defaultDeps(), ...(clients.deps || {}) };
  const all = { ...clients, deps };
  const { bot } = all;
  if (typeof bot.ensureLabel === 'function') {
    await bot.ensureLabel(HOLD_LABEL);
    await bot.ensureLabel(BLOCKED_LABEL, {
      color: 'B60205',
      description: 'Worker cannot fix the PR inside scope; driver STOP worker-blocked',
    });
  }
  const ctx = await deps.loadPlanContext(bot, { planId, controlIssue: issueNumber });

  let lease = null;
  if (ctx.status.lease) {
    const l = ctx.status.lease;
    const status = all.cursorApiKey && l.agent_id && l.run_id
      ? await deps.getAgentRunStatus({ apiKey: all.cursorApiKey, agentId: l.agent_id, runId: l.run_id })
      : 'UNKNOWN';
    lease = { ...l, status };
  }
  const decision = await deps.tick(bot, { planId, controlIssue: ctx.issueNumber, actor: 'driver', lease, now, dryRun: sw === 'dry-run' });
  const action = decision.action;
  let label = 'none';
  if (action) {
    if (action.kind === 'wait' && action.args && action.args.reason) label = `${action.actor}:wait(${action.args.reason})`;
    else label = `${action.actor}:${action.kind}${action.launch ? ' (launch)' : ''}`;
  }
  log(`plan ${planId}: state ${decision.state}, action ${label}${decision.stop ? `, stop ${decision.stop.reason}` : ''}`);
  if (sw === 'dry-run') return { planId, decision, executed: false };

  let outcome = null;
  try {
    if (action && action.actor === 'driver' && action.kind !== 'wait') {
      outcome = await executeDriverAction(all, ctx, decision, now);
    } else if (action && action.actor === 'agent' && action.launch) {
      outcome = await launchWorker(all, ctx, decision, now);
    }
  } catch (e) {
    if (STOP_CODES.has(e.code)) {
      await updateStatus(bot, ctx, (s) => ({ ...s, state: 'stopped', stop: { reason: e.code, detail: e.detail, at: now } }), now);
      await bot.addLabels(ctx.issueNumber, ['needs-owner']);
      // Auto-merge may already be armed: GitHub would merge once the missing check shows up.
      if (e.pr) await enforceStop(all, { stop: { reason: e.code }, action: { args: { prs: [e.pr] } } }, now);
      outcome = `${e.code === 'merge-blocked' ? 'merge blocked' : 'check missing'}: ${e.detail}`;
    } else throw e;
  }
  if (outcome) log(`plan ${planId}: ${outcome}`);
  return { planId, decision, executed: Boolean(outcome), outcome };
}

module.exports = { runDriverPass, buildHandoffPrompt, normalizeKillSwitch, isoNow };
