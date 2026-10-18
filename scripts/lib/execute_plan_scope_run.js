'use strict';

/**
 * Execute-plan v2 scope check: gather GitHub state, run the pure matcher, publish the
 * `execute-plan-scope` check run. Runs in Actions from trusted `main` code; PR code is never executed.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/work-packages-platform.md §WP7a.
 */

const crypto = require('crypto');
const { PullFilesOverflow } = require('./execute_plan_github');
const { computeApprovalHash, findControlComments } = require('./execute_plan_approval');
const { loadSnapshotAtRef } = require('./execute_plan_snapshot_v2');
const { categorizePull, evaluateDiff } = require('./execute_plan_scope');
const { deriveControl } = require('./execute_plan_control');
const { planIdFromRefs, findControlIssue, labelNames } = require('./execute_plan_plans');

const CHECK_NAME = 'execute-plan-scope';
const CONFIG_PATH = '.github/execute-plan.config.json';
const SUMMARY_MAX_LINES = 50;

const result = (conclusion, title, summary, planId = null) => ({ conclusion, title, summary, planId });
const sha256Hex = (text) => crypto.createHash('sha256').update(text, 'utf8').digest('hex');

function statusMarker(planId) {
  return `<!-- execute-plan-status:${planId} -->`;
}

/**
 * Parsed JSON block of the status comment (contracts §3.5), or null. Only a comment written by
 * `botLogin` counts: on a public repo anyone can post a comment carrying the marker.
 */
function parseStatusComment(comments, planId, botLogin) {
  const marker = statusMarker(planId);
  const comment = comments.find(
    (c) => String(c.body || '').split('\n', 1)[0].trim() === marker && c.user && c.user.login === botLogin,
  );
  if (!comment) return null;
  const m = /```json\s*\n([\s\S]*?)\n```/.exec(comment.body);
  if (!m) return null;
  try {
    return JSON.parse(m[1]);
  } catch {
    return null;
  }
}

async function loadConfig(client) {
  const file = await client.getFileAtRef(CONFIG_PATH, 'main');
  if (!file) throw new Error(`${CONFIG_PATH} not found on main`);
  return JSON.parse(file.content);
}

/** Own plan files in the diff must match the approved bytes at the PR head (WP7a rule 6). */
async function verifyOwnPlanFiles(client, snapshot, headSha, files) {
  const planPath = snapshot.plan_file;
  const snapPath = `.agents/plans/${snapshot.plan_id}.snapshot.json`;
  const inDiff = [planPath, snapPath].filter((p) => files.includes(p));
  if (inDiff.length === 0) return false;
  for (const p of inDiff) {
    const file = await client.getFileAtRef(p, headSha);
    if (!file) return false;
    if (p === planPath) {
      if (sha256Hex(file.content) !== snapshot.plan_file_sha256) return false;
    } else {
      let parsed;
      try {
        parsed = JSON.parse(file.content);
      } catch {
        return false;
      }
      if (parsed.approval_hash !== snapshot.approval_hash || computeApprovalHash(parsed) !== snapshot.approval_hash) {
        return false;
      }
    }
  }
  return true;
}

function renderSummary(evaluation) {
  const lines = [];
  if (evaluation.violations.length === 0) lines.push('No violations.');
  else {
    lines.push(`${evaluation.violations.length} violation(s):`);
    for (const v of evaluation.violations.slice(0, SUMMARY_MAX_LINES)) lines.push(`- \`${v.file}\`: ${v.reason}`);
    if (evaluation.violations.length > SUMMARY_MAX_LINES) {
      lines.push(`- … and ${evaluation.violations.length - SUMMARY_MAX_LINES} more`);
    }
  }
  if (evaluation.companionsUsed.length > 0) {
    lines.push('', `Companions used (${evaluation.companionsUsed.length}):`);
    for (const f of evaluation.companionsUsed) lines.push(`- \`${f}\``);
  }
  return lines.join('\n');
}

/** @returns {Promise<{ conclusion: string, title: string, summary: string, planId: string|null }>} */
async function runScopeCheck(client, { prNumber, headSha, headRef, baseRef, headRepo, repo, now }) {
  if (headRepo !== repo) return result('success', 'ok', 'not an execute-plan PR (fork)');
  const planId = planIdFromRefs({ head_ref: headRef, base_ref: baseRef });
  if (!planId) return result('success', 'ok', 'not an execute-plan PR');
  const issue = await findControlIssue(client, planId);
  if (!issue) return result('success', 'ok', 'not an execute-plan PR');

  let config;
  let snapshot;
  let status;
  let comments;
  try {
    config = await loadConfig(client);
    comments = await client.listIssueComments(issue.number);
    status = parseStatusComment(comments, planId, config.bot_login);
    if (!status || typeof status.init_sha !== 'string') throw new Error('status comment with init_sha not found');
    ({ snapshot } = await loadSnapshotAtRef(client, planId, status.init_sha));
  } catch (e) {
    return result('failure', 'drift', e.message, planId);
  }

  const control = findControlComments(comments, snapshot, config);
  const stopped = deriveControl(
    { ...control, labels: labelNames(issue), status },
    { now: new Date(now).toISOString() },
  );

  let files;
  try {
    const pullFiles = await client.listPullFiles(prNumber);
    files = [...new Set(pullFiles.flatMap((f) => [f.filename, f.previous_filename].filter(Boolean)))];
  } catch (e) {
    if (e instanceof PullFilesOverflow) return result('failure', 'too-many-files', e.message, planId);
    throw e;
  }

  const { category, phaseId } = categorizePull({ head_ref: headRef, base_ref: baseRef }, snapshot);
  const ownPlanFilesVerified = category === 'release' && files.length > 0
    ? await verifyOwnPlanFiles(client, snapshot, headSha, files)
    : false;
  const evaluation = evaluateDiff({ files, snapshot, category, phaseId, ownPlanFilesVerified, stopped });
  const summary = stopped.stopped ? `plan stopped: ${stopped.reason}` : renderSummary(evaluation);
  return result(evaluation.conclusion, evaluation.title, summary, planId);
}

/** Create or update the check run named `execute-plan-scope` on `headSha`. */
async function publishScopeCheck(client, { headSha, conclusion, title, summary }) {
  const runs = await client.listCheckRuns(headSha);
  const existing = runs.find((r) => r.name === CHECK_NAME);
  if (existing) return client.updateCheckRun(existing.id, { conclusion, title, summary });
  return client.createCheckRun({ name: CHECK_NAME, head_sha: headSha, conclusion, title, summary });
}

/** `check-diff --pr <n> [--repo owner/name] [--publish]`: run the check for a PR from a terminal. */
async function cliCheckDiff(flags, { client: injected } = {}) {
  const repo = flags.repo || process.env.GITHUB_REPOSITORY;
  const prNumber = Number(flags.pr);
  if (!repo || !Number.isInteger(prNumber) || prNumber < 1) {
    throw new Error('check-diff requires --pr <number> and --repo <owner/name> (or GITHUB_REPOSITORY)');
  }
  const client = injected || require('./execute_plan_github').createGitHubClient({ repo });
  const pull = await client.getPull(prNumber);
  const outcome = await runScopeCheck(client, {
    prNumber,
    headSha: pull.head.sha,
    headRef: pull.head.ref,
    baseRef: pull.base.ref,
    headRepo: pull.head.repo && pull.head.repo.full_name,
    repo,
    now: new Date(),
  });
  if (flags.publish) await publishScopeCheck(client, { headSha: pull.head.sha, ...outcome });
  console.log(JSON.stringify(outcome, null, 2));
  if (outcome.conclusion !== 'success') process.exitCode = 1;
}

module.exports = {
  CHECK_NAME,
  cliCheckDiff,
  parseStatusComment,
  publishScopeCheck,
  runScopeCheck,
};
