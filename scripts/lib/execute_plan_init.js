'use strict';

/**
 * Execute-plan v2 `init`: validate the plan file, create the control issue, commit plan + snapshot
 * on the init branch, then print the one line the owner must post. The session ends there.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/work-packages-runtime.md §WP3 rule 5.
 */

const fs = require('fs');
const { execFileSync } = require('child_process');
const path = require('path');
const { ExecutePlanError, V2_DEFAULTS } = require('./execute_plan_constants');
const { buildSnapshotFromPlan, parsePlanMarkdown } = require('./execute_plan_snapshot_v2');

const INIT_EXIT_CODE = 3;

function initError(message) {
  const err = new ExecutePlanError(message, 'init_precondition');
  err.exitCode = INIT_EXIT_CODE;
  return err;
}

function approvalLine(snapshot) {
  return `approve-autonomous ${snapshot.plan_id} ${snapshot.approval_hash} until ${snapshot.approved_until}`;
}

function renderIssueBody(snapshot, hashText) {
  const rows = snapshot.phases.map(
    (p) => `| ${p.id} | ${p.title} | \`${p.branch}\` | ${p.allowed_paths.map((g) => `\`${g}\``).join(', ')} |`,
  );
  return [
    `Plan: \`${snapshot.plan_file}\``,
    '',
    '| Phase | Title | Branch | Allowed paths |',
    '|-------|-------|--------|---------------|',
    ...rows,
    '',
    `Approval window: until ${snapshot.approved_until}`,
    `Approval hash: ${hashText}`,
  ].join('\n');
}

/**
 * @param {{ client, planId: string, windowDays?: number, dryRun?: boolean, git, now?: Date|string,
 *           cwd?: string, fsImpl?: typeof fs }} args
 * `git` exposes: currentBranch(), statusPorcelain(), add(paths), commit(message), pushUpstream(), headSha().
 */
async function runInit({ client, planId, windowDays = V2_DEFAULTS.window_days, dryRun = false, git, now = new Date(), cwd = process.cwd(), fsImpl = fs }) {
  const planRel = `.agents/plans/${planId}.md`;
  const snapRel = `.agents/plans/${planId}.snapshot.json`;

  if (!dryRun) {
    const branch = git.currentBranch();
    if (branch !== `cursor/${planId}-init`) {
      throw initError(`init must run on branch cursor/${planId}-init (current: ${branch || 'detached'})`);
    }
    const dirty = git
      .statusPorcelain()
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean)
      .map((l) => l.replace(/^\S+\s+/, ''))
      .filter((file) => file !== planRel);
    if (dirty.length > 0) {
      throw initError(`working tree must be clean except ${planRel} (found: ${dirty.join(', ')})`);
    }
  }

  const planMarkdown = fsImpl.readFileSync(path.join(cwd, planRel), 'utf8');
  const parsed = parsePlanMarkdown(planMarkdown);
  const build = (controlIssue) => buildSnapshotFromPlan({ planId, planMarkdown, controlIssue, now, windowDays });

  if (dryRun) {
    const snapshot = build(0);
    const line = approvalLine(snapshot);
    return { snapshot, approvalLine: line, output: `${JSON.stringify(snapshot, null, 2)}\n${line}` };
  }

  if (typeof client.createIssue !== 'function' || typeof client.updateIssue !== 'function') {
    throw initError('GitHub client lacks createIssue/updateIssue (needed to create the control issue)');
  }
  const draft = build(0);
  const issue = await client.createIssue({
    title: `execute-plan: ${parsed.title} (${planId})`,
    body: renderIssueBody(draft, 'pending'),
    labels: ['execute-plan'],
  });
  const snapshot = build(issue.number);
  fsImpl.writeFileSync(path.join(cwd, snapRel), `${JSON.stringify(snapshot, null, 2)}\n`);
  git.add([planRel, snapRel]);
  git.commit(`execute-plan init ${planId}`);
  git.pushUpstream();
  const sha = git.headSha();
  const line = approvalLine(snapshot);
  await client.updateIssue(issue.number, {
    body: [
      renderIssueBody(snapshot, snapshot.approval_hash),
      `Init branch: cursor/${planId}-init @ ${sha}`,
      '',
      'Owner: post this exact line as a comment to approve:',
      '',
      '```',
      line,
      '```',
    ].join('\n'),
  });
  return { snapshot, approvalLine: line, output: line, issue: issue.number };
}

function realGit(cwd = process.cwd()) {
  const run = (...args) => execFileSync('git', args, { cwd, encoding: 'utf8' });
  return {
    currentBranch: () => run('rev-parse', '--abbrev-ref', 'HEAD').trim().replace(/^HEAD$/, ''),
    statusPorcelain: () => run('status', '--porcelain'),
    add: (paths) => run('add', '--', ...paths),
    commit: (message) => run('commit', '-m', message),
    pushUpstream: () => run('push', '-u', 'origin', 'HEAD'),
    headSha: () => run('rev-parse', 'HEAD').trim(),
  };
}

function resolveRepo() {
  if (process.env.GITHUB_REPOSITORY) return process.env.GITHUB_REPOSITORY;
  const url = execFileSync('git', ['remote', 'get-url', 'origin'], { encoding: 'utf8' }).trim();
  const m = /github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?$/.exec(url);
  if (!m) throw new ExecutePlanError(`cannot derive owner/name from origin URL ${url}`);
  return m[1];
}

/** CLI entry: `init <plan_id> [--window-days N] [--dry-run]`. */
async function cliInit(planId, flags) {
  const windowDays = flags['window-days'] === undefined ? V2_DEFAULTS.window_days : Number(flags['window-days']);
  const dryRun = Boolean(flags['dry-run']);
  let client = null;
  if (!dryRun) {
    const { createGitHubClient } = require('./execute_plan_github');
    client = createGitHubClient({ repo: resolveRepo() });
  }
  const result = await runInit({ client, planId, windowDays, dryRun, git: realGit() });
  console.log(result.output);
}

module.exports = { INIT_EXIT_CODE, approvalLine, cliInit, runInit };
