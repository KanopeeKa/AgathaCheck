'use strict';

/**
 * Execute-plan v2 scope check: gather GitHub state, run the pure matcher, publish the
 * `execute-plan-scope` commit status. Runs in Actions from trusted `main` code; PR code is never executed.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/work-packages-platform.md §WP7a.
 */

const crypto = require('crypto');
const { PullFilesOverflow } = require('./execute_plan_github');
const { computeApprovalHash, findControlComments } = require('./execute_plan_approval');
const { loadSnapshotAtRef } = require('./execute_plan_snapshot_v2');
const { categorizePull, evaluateDiff } = require('./execute_plan_scope');
const { deriveControl } = require('./execute_plan_control');
const { planIdFromRefs, findControlIssue, labelNames } = require('./execute_plan_plans');
const { SCOPE_CONTEXT, describeScope } = require('./execute_plan_scope_status');

const CHECK_NAME = SCOPE_CONTEXT;
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

/** Control issue → config, status comment, snapshot at `init_sha`, and the derived STOP state. Throws when any is unusable. */
async function loadPlanControl(client, issue, planId, now) {
  const config = await loadConfig(client);
  const comments = await client.listIssueComments(issue.number);
  const status = parseStatusComment(comments, planId, config.bot_login);
  if (!status || typeof status.init_sha !== 'string') throw new Error('status comment with init_sha not found');
  const { snapshot } = await loadSnapshotAtRef(client, planId, status.init_sha);
  const control = findControlComments(comments, snapshot, config);
  const stopped = deriveControl({ ...control, labels: labelNames(issue), status }, { now: new Date(now).toISOString() });
  return { snapshot, stopped };
}

/** @returns {Promise<{ conclusion: string, title: string, summary: string, planId: string|null }>} */
async function runScopeCheck(client, { prNumber, headSha, headRef, baseRef, headRepo, repo, now }) {
  if (headRepo !== repo) return result('success', 'ok', 'not an execute-plan PR (fork)');
  const planId = planIdFromRefs({ head_ref: headRef, base_ref: baseRef });
  if (!planId) return result('success', 'ok', 'not an execute-plan PR');
  const issue = await findControlIssue(client, planId);
  if (!issue) return result('success', 'ok', 'not an execute-plan PR');

  let snapshot;
  let stopped;
  try {
    ({ snapshot, stopped } = await loadPlanControl(client, issue, planId, now));
  } catch (e) {
    return result('failure', 'drift', e.message, planId);
  }

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

/** Post the `execute-plan-scope` commit status on `headSha`. */
async function publishScopeCheck(client, { headSha, conclusion, title, summary, targetUrl }) {
  return client.createCommitStatus(headSha, {
    state: conclusion === 'success' ? 'success' : 'failure',
    context: CHECK_NAME,
    description: describeScope(title, summary),
    target_url: targetUrl,
  });
}

/**
 * Publish an evaluated outcome. A green result for a plan PR is re-checked against the plan's STOP
 * state just before posting: a run that evaluated before a STOP must not post after `enforce-stop`'s
 * `plan-stopped` and turn the head green again. A failing re-check publishes a failure (fail closed).
 */
async function publishScopeResult(client, { headSha, outcome, targetUrl, now }) {
  let final = outcome;
  if (outcome.conclusion === 'success' && outcome.planId) {
    try {
      const issue = await findControlIssue(client, outcome.planId);
      if (!issue) throw new Error(`control issue for ${outcome.planId} not found`);
      const { stopped } = await loadPlanControl(client, issue, outcome.planId, now);
      if (stopped.stopped) final = result('failure', 'plan-stopped', `plan stopped: ${stopped.reason}`, outcome.planId);
    } catch (e) {
      final = result('failure', 'recheck-error', `scope check could not confirm the plan state: ${e.message}`, outcome.planId);
    }
  }
  await publishScopeCheck(client, { headSha, conclusion: final.conclusion, title: final.title, summary: final.summary, targetUrl });
  return final;
}

/** `check-diff --pr <n> [--repo owner/name] [--publish]`: run the check for a PR from a terminal. */
async function cliCheckDiff(flags, { client: injected } = {}) {
  const repo = flags.repo || process.env.GITHUB_REPOSITORY;
  const prNumber = Number(flags.pr);
  if (!repo || !Number.isInteger(prNumber) || prNumber < 1) {
    throw new Error('check-diff requires --pr <number> and --repo <owner/name> (or GITHUB_REPOSITORY)');
  }
  // Only a status set with a workflow GITHUB_TOKEN counts (ruleset app pin); one posted with a PAT is ignored.
  if (flags.publish && process.env.GITHUB_ACTIONS !== 'true') {
    throw new Error('check-diff --publish only runs inside GitHub Actions: a status posted with a personal token never counts');
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
  const final = flags.publish ? await publishScopeResult(client, { headSha: pull.head.sha, outcome, now: new Date() }) : outcome;
  console.log(JSON.stringify(final, null, 2));
  if (final.conclusion !== 'success') process.exitCode = 1;
}

module.exports = {
  CHECK_NAME,
  cliCheckDiff,
  parseStatusComment,
  publishScopeCheck,
  publishScopeResult,
  runScopeCheck,
};
