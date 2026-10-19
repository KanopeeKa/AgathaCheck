'use strict';

/**
 * Execute-plan v2 driver: one pass for one plan = tick (actor `driver`) + execute the returned
 * driver action, or launch the worker for an agent action with `launch: true`.
 * The driver never waits inside a job. Spec: work-packages-platform.md §WP7b, contracts.md §3.5-3.8.
 *
 * `clients` = { bot, read, cursorApiKey, deps? }
 *   bot  — GitHub client on EXECUTE_PLAN_BOT_TOKEN (writes that must trigger workflows, status, labels)
 *   read — GitHub client on GITHUB_TOKEN (reads, workflow_dispatch, the execute-plan-scope check run)
 *   deps — test seams: tick, completePlan, loadPlanContext, publishScopeCheck, launchPlanAgent, getAgentRunStatus
 */

const { GitHubError } = require('./execute_plan_github');
const { formatStatusComment, parseStatusComment } = require('./execute_plan_status');

const MAX_LAUNCHES = 50;
const MAX_LISTED_FILES = 100;
const FENCE_RE = /```json\s*\n[\s\S]*?\n```/;
const FIX_KINDS = new Set(['fix-ci', 'fix-scope', 'triage-review', 'resolve-conflict', 'remedial']);
const KILL_SWITCH_VALUES = new Set(['off', 'dry-run', 'on']);

const isoNow = () => new Date().toISOString().replace(/\.\d+Z$/, 'Z');

/** Anything but `on` / `dry-run` (unset, typo) is `off`: the safe reading of the kill switch. */
function normalizeKillSwitch(value) {
  const v = String(value == null ? '' : value).trim().toLowerCase();
  return KILL_SWITCH_VALUES.has(v) ? v : 'off';
}

function defaultDeps() {
  const { tick, completePlan } = require('./execute_plan_tick');
  const { loadPlanContext } = require('./execute_plan_observe');
  const { publishScopeCheck } = require('./execute_plan_scope_run');
  const { launchPlanAgent, getAgentRunStatus } = require('../../.github/scripts/execute-plan-launch');
  return { tick, completePlan, loadPlanContext, publishScopeCheck, launchPlanAgent, getAgentRunStatus };
}

const ACTION_TEXT = {
  implement: 'build the phase on its branch (draft PR first)',
  'fix-ci': 'make the failing required checks green',
  'fix-scope': 'remove or move out-of-scope files',
  'triage-review': 'address and resolve the unresolved review threads',
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
    `\`node scripts/execute_plan_runtime.js tick ${id} --json --actor agent\` and continue with what`,
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
    `Rules: if no PR exists, open a draft PR into ${resolvedBase} right after your first commit; push often;`,
    'mark the PR ready only after ./scripts/pre-push-changed.sh is green; never touch protected',
    'paths; never approve, label, merge or close anything; never edit the control issue yourself.',
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

async function launchWorker(clients, ctx, decision, now) {
  const { bot, deps, cursorApiKey } = clients;
  const { snapshot, config } = ctx;
  const { action } = decision;
  const a = action.args || {};
  if (!cursorApiKey) throw new Error('cursor_api_key is not available: cannot launch a worker');

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
  });
  const key = decision.phase || 'release';
  await updateStatus(bot, ctx, (s) => ({
    ...s,
    launches: [...(s.launches || []), { at: now, phase: key, kind: action.kind, agent_id: launched.agentId, run_id: launched.runId }].slice(-MAX_LAUNCHES),
    lease: { platform: 'cursor', agent_id: launched.agentId, run_id: launched.runId, launched_at: now, last_tick_at: now },
  }), now);
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
        await bot.mergePull(a.pr, { method: a.method });
        return `#${a.pr} already clean: merged (${a.method})`;
      }
    }
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
  const label = action ? `${action.actor}:${action.kind}${action.launch ? ' (launch)' : ''}` : 'none';
  log(`plan ${planId}: state ${decision.state}, action ${label}${decision.stop ? `, stop ${decision.stop.reason}` : ''}`);
  if (sw === 'dry-run') return { planId, decision, executed: false };

  let outcome = null;
  if (action && action.actor === 'driver' && action.kind !== 'wait') {
    outcome = await executeDriverAction(all, ctx, decision, now);
  } else if (action && action.actor === 'agent' && action.launch) {
    outcome = await launchWorker(all, ctx, decision, now);
  }
  if (outcome) log(`plan ${planId}: ${outcome}`);
  return { planId, decision, executed: Boolean(outcome), outcome };
}

module.exports = { runDriverPass, buildHandoffPrompt, normalizeKillSwitch, isoNow };
