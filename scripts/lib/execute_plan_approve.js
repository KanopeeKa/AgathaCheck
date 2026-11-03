'use strict';

/**
 * Execute-plan v2 control-issue comments: approve, resume, revoke, plus edits and deletions of them.
 * Runs in Actions from trusted `main` code. Spec: work-packages-platform.md §WP7b, contracts.md §3.3.
 *
 * `clients` = { bot, read, deps? } as in execute_plan_driver_actions.js; `read` (GITHUB_TOKEN) dispatches the driver.
 */

const { parseControlComment, validateControlComment, findControlComments } = require('./execute_plan_approval');
const { loadSnapshotAtRef } = require('./execute_plan_snapshot_v2');
const { loadPlanContext, CONFIG_PATH } = require('./execute_plan_observe');
const { formatStatusComment, STATUS_MARKER } = require('./execute_plan_status');
const { labelNames } = require('./execute_plan_plans');
const { normalizeKillSwitch, isoNow } = require('./execute_plan_driver_actions');
const { deriveControl } = require('./execute_plan_control');
const { formatAck, formatIgnoredNote, formatStoppedNote } = require('./execute_plan_ack');

const RUNNING = new Set(['CREATING', 'RUNNING', 'UNKNOWN']);

const DRIVER_WORKFLOW = 'execute-plan-driver.yml';
const INIT_LINE_RE = /^Init branch: (\S+) @ ([0-9a-f]{40})\s*$/m;
const IGNORED_REASONS = new Set(['not-owner', 'bot']); // never answered: no comment loops, no noise

const done = (handled, detail) => ({ handled, detail });

async function loadConfig(client) {
  const file = await client.getFileAtRef(CONFIG_PATH, 'main');
  if (!file) throw new Error(`${CONFIG_PATH} not found on main`);
  return JSON.parse(file.content);
}

async function reject(bot, issueNumber, verb, reason) {
  await bot.createComment(issueNumber, `${verb}-autonomous rejected: ${reason}`);
  return done(true, `rejected: ${reason}`);
}

async function gateAuthorization(clients, ctx, { issue, comment, parsed, now, log, dry, runId }) {
  if (dry || !runId) return null;
  const { read, bot, cursorApiKey, deps } = clients;
  const lease = ctx && ctx.status && ctx.status.lease;
  let running = false;
  const agentId = (lease && lease.agent_id) || 'unknown';
  if (lease && lease.agent_id && lease.run_id && cursorApiKey) {
    const getStatus = (deps && deps.getAgentRunStatus) || require('../../.github/scripts/execute-plan-launch').getAgentRunStatus;
    const st = await getStatus({ apiKey: cursorApiKey, agentId: lease.agent_id, runId: lease.run_id });
    running = RUNNING.has(st);
  }
  const labels = labelNames(issue);
  let stopped = false;
  if (ctx) {
    const control = findControlComments(ctx.comments, ctx.snapshot, ctx.config, {
      accepted: ctx.acceptedAuthorizations || new Set(),
    });
    stopped = deriveControl(
      { ...control, labels, status: ctx.status, revoke_comment_at: control.revoke_comment_at },
      { now },
    ).stopped;
  }
  if (running) {
    if (stopped) {
      await read.createComment(issue.number, formatIgnoredNote(parsed.verb, comment.id, agentId, now));
      log(`plan ${parsed.plan}: ${parsed.verb} ignored while worker ${agentId} running (plan stopped)`);
      return done(true, 'authorization ignored (worker running, plan stopped)');
    }
    await bot.addLabels(issue.number, ['needs-owner']);
    await read.createComment(issue.number, formatStoppedNote(parsed.verb, comment.id, agentId));
    await read.dispatchWorkflow(DRIVER_WORKFLOW, 'main', { plan_id: parsed.plan });
    log(`plan ${parsed.plan}: stopped: ${parsed.verb} while worker ${agentId} running`);
    return done(true, 'authorization rejected (worker running)');
  }
  await read.createComment(issue.number, formatAck(comment.id, runId));
  log(`plan ${parsed.plan}: authorization ack for comment ${comment.id}`);
  return null;
}

async function handleApprove(clients, { issue, comment, parsed, config }, { now, log, dry, runId }) {
  const { bot, read } = clients;
  const rejectWith = (reason) => (dry ? done(false, `would reject: ${reason}`) : reject(bot, issue.number, 'approve', reason));

  const init = INIT_LINE_RE.exec(issue.body || '');
  if (!init) return rejectWith('no "Init branch: <name> @ <sha>" line in the issue body');
  const [, initBranch, sha] = init;
  if (initBranch !== `cursor/${parsed.plan}-init`) return rejectWith(`init branch ${initBranch} is not cursor/${parsed.plan}-init`);

  let snapshot;
  try {
    ({ snapshot } = await loadSnapshotAtRef(read, parsed.plan, sha));
  } catch (e) {
    return rejectWith(e.message);
  }
  const res = validateControlComment({ comment, snapshot, config });
  if (!res.valid) {
    if (IGNORED_REASONS.has(res.reason)) return done(false, `ignored: ${res.reason}`);
    return rejectWith(res.reason);
  }

  const own = new Set([snapshot.plan_file, `.agents/plans/${snapshot.plan_id}.snapshot.json`]);
  const files = (await read.compare('main', sha)).files.map((f) => f.filename);
  if (files.length !== own.size || !files.every((f) => own.has(f))) {
    return rejectWith(`the init branch must change exactly the two plan files (found: ${files.join(', ') || 'none'})`);
  }
  const existing = await read.getBranch(snapshot.integration_branch);
  if (existing && existing.commit.sha !== sha) {
    return rejectWith(`integration branch ${snapshot.integration_branch} already exists at ${existing.commit.sha}`);
  }
  if (dry) return done(false, 'dry-run: approve is valid');
  const blocked = await gateAuthorization(clients, null, { issue, comment, parsed, now, log, dry, runId });
  if (blocked) return blocked;

  if (!existing) await bot.createRef(`refs/heads/${snapshot.integration_branch}`, sha);
  const marker = STATUS_MARKER(snapshot.plan_id);
  const comments = await bot.listIssueComments(issue.number);
  const hasStatus = comments.some((c) => String(c.body || '').trimStart().startsWith(marker) && c.user && c.user.login === config.bot_login);
  if (!hasStatus) {
    await bot.createComment(issue.number, formatStatusComment({
      schema: 1,
      plan_id: snapshot.plan_id,
      init_sha: sha,
      state: 'phase:pending',
      phase: snapshot.phases[0].id,
      lease: null,
      launches: [],
      dispatched: { preuat_heads: [], deploy_tags: [] },
      release: null,
      uat: null,
      stop: null,
      updated_at: now,
    }, ''));
  }
  await bot.addLabels(issue.number, ['autonomous-approved', `plan:${snapshot.plan_id}`]);
  const line = `Approval: valid (comment ${comment.id})`;
  if (!(issue.body || '').includes(line)) await bot.updateIssue(issue.number, { body: `${issue.body}\n\n${line}` });
  log(`plan ${snapshot.plan_id}: approved by comment ${comment.id}`);
  return done(true, 'approved');
}

/** Snapshot of an already approved plan (status comment `init_sha`), or null when the issue is not approved. */
async function approvedContext(clients, issue, planId) {
  if (!labelNames(issue).includes('autonomous-approved')) return null;
  const load = (clients.deps && clients.deps.loadPlanContext) || loadPlanContext;
  return load(clients.read, { planId, controlIssue: issue.number });
}

/**
 * @param {{ action: string, issue: object, comment: object }} event  parsed issue_comment payload
 * @returns {Promise<{ handled: boolean, detail: string }>}
 */
async function handleControlComment(clients, event, { now = isoNow(), killSwitch, log = () => {}, runId = null } = {}) {
  const sw = normalizeKillSwitch(killSwitch);
  if (sw === 'off') return done(false, 'kill switch off');
  const dry = sw === 'dry-run';
  const { issue, comment } = event;
  if (issue.pull_request) return done(false, 'comment on a PR');
  const labels = labelNames(issue);
  if (!labels.includes('execute-plan')) return done(false, 'not an execute-plan issue');
  const parsed = parseControlComment(comment.body);
  if (!parsed) return done(false, 'not a control comment');

  const config = await loadConfig(clients.read);
  // The pass runs in the driver workflow's concurrency group, never inline: two passes for one plan
  // would race on the status comment and could pick the same action (issue #2005).
  const pass = async (planId) => {
    if (dry) return done(false, `dry-run: would dispatch ${DRIVER_WORKFLOW} for ${planId}`);
    await clients.read.dispatchWorkflow(DRIVER_WORKFLOW, 'main', { plan_id: planId });
    log(`plan ${planId}: dispatched ${DRIVER_WORKFLOW}`);
    return done(true, 'driver pass dispatched');
  };

  if (event.action === 'edited' || event.action === 'deleted') {
    // tick re-validates the authorizing comment and stops with approval-invalid; the pass enforces it.
    if (parsed.verb === 'revoke') return done(false, 'revoke comment changed: label still in force');
    const planLabel = labels.find((l) => l.startsWith('plan:') && l !== 'plan:complete');
    if (!labels.includes('autonomous-approved') || !planLabel) return done(false, 'issue not approved');
    return pass(planLabel.slice('plan:'.length));
  }
  if (event.action !== 'created') return done(false, `ignored action ${event.action}`);

  if (parsed.verb === 'approve') {
    const res = await handleApprove(clients, { issue, comment, parsed, config }, { now, log, dry, runId });
    return res.handled && res.detail === 'approved' ? pass(parsed.plan) : res;
  }

  const ctx = await approvedContext(clients, issue, parsed.plan);
  if (!ctx) return done(false, 'issue not approved');
  const res = validateControlComment({ comment, snapshot: ctx.snapshot, config });
  if (!res.valid) {
    log(`${parsed.verb} comment ${comment.id} ignored: ${res.reason}`);
    return done(false, `invalid ${parsed.verb}: ${res.reason}`);
  }
  const blocked = await gateAuthorization(clients, ctx, { issue, comment, parsed, now, log, dry, runId });
  if (blocked) return blocked;
  if (parsed.verb === 'revoke' && !dry) await clients.bot.addLabels(issue.number, ['autonomous-revoked']);
  if (parsed.verb === 'resume' && !dry) {
    if (labels.includes('needs-owner')) await clients.bot.removeLabel(issue.number, 'needs-owner');
    if (labels.includes('autonomous-revoked')) await clients.bot.removeLabel(issue.number, 'autonomous-revoked');
  }
  return pass(parsed.plan);
}

module.exports = { handleControlComment };
