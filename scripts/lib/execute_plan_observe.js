'use strict';

/**
 * Execute-plan v2 observation: every GitHub read that feeds `decide()` (state-machine §4.0).
 * Reads only; writes live in execute_plan_tick.js.
 */

const { ExecutePlanError } = require('./execute_plan_constants');
const { findControlComments } = require('./execute_plan_approval');
const { loadSnapshotAtRef } = require('./execute_plan_snapshot_v2');
const { parseStatusComment, STATUS_MARKER } = require('./execute_plan_status');

const CONFIG_PATH = '.github/execute-plan.config.json';
const SCOPE_CHECK = 'execute-plan-scope';
const FAILED = new Set(['failure', 'timed_out', 'action_required']);
const UNKNOWN_RETRY_MS = 3000;
const PREUAT_ACTIVE = new Set(['queued', 'in_progress']);

/** Config / approval errors that prevent a decision exit `3` (contracts §3.7). */
function configError(message) {
  const err = new ExecutePlanError(message, 'config');
  err.exitCode = 3;
  return err;
}

const ms = (iso) => Date.parse(iso);
const labelNames = (labels) => (labels || []).map((l) => (typeof l === 'string' ? l : l.name));
const newest = (items, key = 'created_at') => items.reduce((a, b) => (!a || ms(b[key]) > ms(a[key]) ? b : a), null);

/** Config from main, control issue, status comment, snapshot at `init_sha`. Never reads the checkout. */
async function loadPlanContext(client, { planId, controlIssue }) {
  const file = await client.getFileAtRef(CONFIG_PATH, 'main');
  if (!file) throw configError(`${CONFIG_PATH} not found on main`);
  let config;
  try {
    config = JSON.parse(file.content);
  } catch (e) {
    throw configError(`${CONFIG_PATH} is not valid JSON: ${e.message}`);
  }

  let issueNumber = controlIssue ? Number(controlIssue) : null;
  if (!issueNumber && typeof client.listIssues === 'function') {
    const found = await client.listIssues({ labels: `plan:${planId}`, state: 'open' });
    const hit = (found || []).find((i) => !i.pull_request);
    issueNumber = hit ? hit.number : null;
  }
  if (!issueNumber) throw configError(`control issue for ${planId} not found (pass --issue N)`);

  const issue = await client.getIssue(issueNumber);
  const comments = await client.listIssueComments(issueNumber);
  const marker = STATUS_MARKER(planId);
  // Only the bot's own comment counts: its `init_sha` selects the snapshot everything else trusts.
  const statusComment = newest(
    comments.filter((c) => String(c.body || '').trimStart().startsWith(marker) && c.user && c.user.login === config.bot_login),
    'created_at',
  );
  const status = statusComment ? parseStatusComment(statusComment.body) : null;
  if (!status) throw configError(`status comment ${marker} not found on issue #${issueNumber}`);
  if (!status.init_sha) throw configError(`status comment on issue #${issueNumber} has no init_sha`);

  let loaded;
  try {
    loaded = await loadSnapshotAtRef(client, planId, status.init_sha);
  } catch (e) {
    throw configError(e.message);
  }
  return { planId, config, issueNumber, issue, comments, statusComment, status, snapshot: loaded.snapshot, planMarkdown: loaded.planMarkdown };
}

async function readPull(client, number, sleep) {
  let pull = await client.getPull(number);
  if (pull.mergeable_state === 'unknown' && pull.state === 'open') {
    await sleep(UNKNOWN_RETRY_MS);
    pull = await client.getPull(number);
  }
  return pull;
}

function latestRuns(runs, names) {
  return names.map((name) => {
    const mine = runs.filter((r) => r.name === name);
    const run = mine.reduce((a, b) => (!a || Number(b.id) > Number(a.id) ? b : a), null);
    if (!run) return { name, status: 'missing', conclusion: null, reason: null };
    return {
      name,
      status: run.status,
      conclusion: run.conclusion || null,
      reason: name === SCOPE_CHECK ? (run.output && run.output.title) || null : null,
    };
  });
}

async function failedAttempts(client, pr, names, epoch, headRuns) {
  if (!epoch) return 0;
  const commits = await client.listPullCommits(pr.number);
  const shas = [...new Set(commits.map((c) => c.sha))];
  let attempts = 0;
  for (const sha of shas) {
    const runs = sha === pr.head.sha ? headRuns : await client.listCheckRuns(sha);
    const failed = runs.some(
      (r) => names.includes(r.name) && FAILED.has(r.conclusion) && r.completed_at && ms(r.completed_at) > ms(epoch),
    );
    if (failed) attempts += 1;
  }
  return attempts;
}

async function readyAt(client, pull) {
  if (pull.draft) return null;
  const timeline = await client.listIssueTimeline(pull.number);
  const ready = newest(timeline.filter((e) => e.event === 'ready_for_review'));
  return ready ? ready.created_at : pull.created_at;
}

/** @returns {Promise<object>} PrObs (state-machine §4.0) */
async function observePr(client, pr, { requiredChecks, epoch, owners = [], sleep = (t) => new Promise((r) => setTimeout(r, t)) }) {
  const pull = await readPull(client, pr.number, sleep);
  const headSha = pull.head.sha;
  const headRuns = await client.listCheckRuns(headSha);
  const [threads, reviews, ready, attempts] = await Promise.all([
    client.listUnresolvedThreads(pull.number),
    client.listPullReviews(pull.number),
    readyAt(client, pull),
    failedAttempts(client, { number: pull.number, head: { sha: headSha } }, requiredChecks, epoch, headRuns),
  ]);
  const lastByUser = new Map();
  for (const r of reviews) {
    if (!r.user || !['APPROVED', 'CHANGES_REQUESTED', 'DISMISSED'].includes(r.state)) continue;
    const prev = lastByUser.get(r.user.login);
    if (!prev || ms(r.submitted_at) >= ms(prev.submitted_at)) lastByUser.set(r.user.login, r);
  }
  return {
    number: pull.number,
    node_id: pull.node_id,
    state: pull.merged_at ? 'merged' : pull.state,
    draft: Boolean(pull.draft),
    merged_at: pull.merged_at || null,
    merge_commit_sha: pull.merged_at ? pull.merge_commit_sha || null : null,
    head_ref: pull.head.ref,
    head_sha: headSha,
    base_ref: pull.base.ref,
    created_at: pull.created_at,
    ready_at: ready,
    mergeable_state: pull.mergeable_state || 'unknown',
    auto_merge_enabled: Boolean(pull.auto_merge),
    labels: labelNames(pull.labels),
    checks: latestRuns(headRuns, requiredChecks),
    failed_attempts_since_epoch: attempts,
    unresolved_threads: threads,
    copilot_review_submitted: reviews.some((r) => r.user && /^copilot/i.test(r.user.login)),
    owner_approved: owners.some((o) => lastByUser.has(o) && lastByUser.get(o).state === 'APPROVED'),
  };
}

const usable = (p) => p.state === 'open' || Boolean(p.merged_at); // closed-unmerged is ignored

/** @returns {Promise<object>} Observations with `uat: null` (tick fills it via observeUat, WP5). */
async function observe(client, ctx, { now, sleep }) {
  const { snapshot, config, status } = ctx;
  const integ = snapshot.integration_branch;
  const auth = findControlComments(ctx.comments, snapshot, config);
  const epoch = auth.authorizing && auth.authorizing.valid ? auth.authorizing.created_at : null;
  const prOpts = (base) => ({
    requiredChecks: (base === 'main' ? config.required_checks.main : config.required_checks.integration),
    epoch,
    owners: config.owners,
    sleep,
  });
  const mostRecent = async (query) => {
    const pulls = (await client.listPulls({ ...query, state: 'all', pages: 1 })).filter(usable);
    const pick = newest(pulls);
    return pick ? observePr(client, pick, prOpts(pick.base.ref)) : null;
  };

  const mainBranch = await client.getBranch('main');
  const mainHead = mainBranch && mainBranch.commit && mainBranch.commit.sha;
  const runs = await client.listWorkflowRuns(config.uat.preuat_workflow, { branch: 'main', pages: 1 });
  const preuatQueued = runs.some((r) => PREUAT_ACTIVE.has(r.status) && r.head_sha === mainHead);

  const integBranch = await client.getBranch(integ);
  const integration = { exists: Boolean(integBranch), head_sha: integBranch ? integBranch.commit.sha : null, behind_main_by: 0 };
  if (integBranch) integration.behind_main_by = (await client.compare(integ, 'main')).ahead_by || 0;

  const phases = [];
  for (const def of snapshot.phases) {
    const exists = integration.exists && Boolean(await client.getBranch(def.branch));
    const pr = integration.exists ? await mostRecent({ head: def.branch, base: integ }) : null;
    phases.push({ id: def.id, branch_exists: exists || Boolean(pr), pr });
  }

  const syncOpen = integration.exists ? (await client.listPulls({ head: 'main', base: integ, state: 'open', pages: 1 }))[0] : null;
  const intoInteg = integration.exists ? await client.listPulls({ base: integ, state: 'all', pages: 3 }) : [];
  const syncPrefix = `cursor/${snapshot.plan_id}-sync-`;
  const resolves = intoInteg.filter((p) => p.head.ref.startsWith(syncPrefix) && epoch && ms(p.created_at) > ms(epoch)).length;

  const intoMain = await client.listPulls({ base: 'main', state: 'all', pages: 3 });
  const remPrefix = `cursor/${snapshot.plan_id}-remedial-`;
  const rem = intoMain.filter((p) => p.head.ref.startsWith(remPrefix));
  const remOpen = newest(rem.filter((p) => p.state === 'open'));
  const mergedRem = rem.filter((p) => p.merged_at && epoch && ms(p.merged_at) > ms(epoch)).length;

  return {
    now,
    control: {
      labels: labelNames(ctx.issue.labels),
      authorizing: auth.authorizing,
      revoke_comment_at: auth.revoke_comment_at,
      status,
    },
    init_sha: status.init_sha,
    main: { head_sha: mainHead, preuat_queued_for_head: preuatQueued },
    integration,
    phases,
    sync: { open_pr: syncOpen ? await observePr(client, syncOpen, prOpts(integ)) : null, resolve_prs_since_epoch: resolves },
    release: { pr: integration.exists ? await mostRecent({ head: integ, base: 'main' }) : null },
    remedial: { open_pr: remOpen ? await observePr(client, remOpen, prOpts('main')) : null, merged_since_epoch: mergedRem },
    uat: null,
  };
}

module.exports = { CONFIG_PATH, configError, loadPlanContext, observe, observePr };
