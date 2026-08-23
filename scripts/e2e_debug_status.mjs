#!/usr/bin/env node
/**
 * Preflight guard for /e2e-debug — detect in-progress remedial work before bootstrap.
 *
 * Usage:
 *   node scripts/e2e_debug_status.mjs --json
 *   node scripts/e2e_debug_status.mjs --join --remedial-branch cursor/preuat-fix-abc12345-6bba --json
 *   node scripts/e2e_debug_status.mjs --claim --issue <n> --merge-sha <sha> --json
 *   node scripts/e2e_debug_status.mjs --release --issue <n> --json
 *
 * Exit codes:
 *   0 — safe to start (or join when --join matches an open remedial PR)
 *   2 — blocked (another agent busy, or open remedial PR without --join)
 *   1 — error
 */
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REMEDIAL_BRANCH_RE = /^cursor\/preuat-fix-[0-9a-f]{6,40}-6bba$/i;
export const SESSION_START_MARKER = '/e2e-debug session start';

function usageError(msg) {
  console.error(`e2e_debug_status: ${msg}`);
  console.error(
    'usage: node scripts/e2e_debug_status.mjs [--join] [--remedial-branch <branch>] [--claim|--release --issue <n>] [--merge-sha <sha>] [--force] [--json]',
  );
  process.exit(2);
}

function ghJson(args) {
  const result = spawnSync('gh', args, { cwd: repoRoot, encoding: 'utf8' });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(1);
  }
  const text = (result.stdout || '').trim();
  return text ? JSON.parse(text) : null;
}

function ghRun(args) {
  const result = spawnSync('gh', args, { cwd: repoRoot, encoding: 'utf8' });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(1);
  }
  return result.stdout || '';
}

function ghTry(args) {
  const result = spawnSync('gh', args, { cwd: repoRoot, encoding: 'utf8' });
  return {
    ok: result.status === 0,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
    status: result.status ?? 1,
  };
}

function resolveRepo() {
  const data = ghJson(['repo', 'view', '--json', 'nameWithOwner']);
  const [owner, repo] = String(data.nameWithOwner).split('/');
  return { owner, repo };
}

function parseArgs() {
  const opts = {
    json: false,
    join: false,
    force: false,
    claim: false,
    release: false,
    issue: null,
    mergeSha: null,
    remedialBranch: null,
  };
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case '--json':
        opts.json = true;
        break;
      case '--join':
        opts.join = true;
        break;
      case '--force':
        opts.force = true;
        break;
      case '--claim':
        opts.claim = true;
        break;
      case '--release':
        opts.release = true;
        break;
      case '--issue':
        opts.issue = Number(argv[++i]);
        if (!Number.isInteger(opts.issue) || opts.issue < 1) {
          usageError('--issue requires a positive integer');
        }
        break;
      case '--merge-sha':
        opts.mergeSha = argv[++i];
        if (!opts.mergeSha) usageError('--merge-sha requires a value');
        break;
      case '--remedial-branch':
        opts.remedialBranch = argv[++i];
        if (!opts.remedialBranch) usageError('--remedial-branch requires a value');
        break;
      default:
        usageError(`unknown argument: ${arg}`);
    }
  }
  if (opts.claim && opts.release) {
    usageError('--claim and --release are mutually exclusive');
  }
  if ((opts.claim || opts.release) && !opts.issue) {
    usageError('--claim/--release require --issue');
  }
  return opts;
}

export function isRemedialBranch(branch) {
  return REMEDIAL_BRANCH_RE.test(branch || '');
}

/**
 * @param {{ labels?: { name: string }[], title?: string }} issue
 * @param {boolean} hasSessionComment
 */
export function issueMatchesE2eDebugSession(issue, hasSessionComment = false) {
  const labels = (issue.labels || []).map((label) => label.name);
  if (labels.includes('e2e-debug')) {
    return true;
  }
  if (/e2e-debug/i.test(issue.title || '')) {
    return true;
  }
  return hasSessionComment;
}

/**
 * @param {{ remedialPrs: object[], busyIssues: object[], join: boolean, force: boolean, remedialBranch: string|null }} input
 */
export function evaluatePreflight(input) {
  const { remedialPrs, busyIssues, join, force, remedialBranch } = input;
  const blockers = [];

  for (const issue of busyIssues) {
    blockers.push({
      type: 'busy_issue',
      issue: issue.number,
      url: issue.url,
      title: issue.title,
      updated_at: issue.updatedAt,
    });
  }

  for (const pr of remedialPrs) {
    blockers.push({
      type: 'open_remedial_pr',
      number: pr.number,
      url: pr.url,
      branch: pr.headRefName,
      updated_at: pr.updatedAt,
    });
  }

  if (busyIssues.length > 0 && !force) {
    return {
      safe_to_start: false,
      reason: 'e2e_debug_in_progress',
      recommended_action: 'wait_or_join',
      blockers,
      busy_issue: busyIssues[0],
      open_remedial_pr: remedialPrs[0] ?? null,
    };
  }

  if (remedialPrs.length > 0 && !force) {
    const target = remedialPrs.find((pr) => pr.headRefName === remedialBranch) || remedialPrs[0];
    if (join) {
      if (remedialBranch && target.headRefName !== remedialBranch) {
        return {
          safe_to_start: false,
          reason: 'join_branch_mismatch',
          recommended_action: 'use_existing_branch',
          blockers,
          open_remedial_pr: target,
          expected_branch: target.headRefName,
          requested_branch: remedialBranch,
        };
      }
      return {
        safe_to_start: true,
        reason: 'join_existing_remedial_pr',
        recommended_action: 'join_existing_pr',
        blockers: blockers.filter((b) => b.type !== 'open_remedial_pr'),
        open_remedial_pr: target,
      };
    }

    return {
      safe_to_start: false,
      reason: 'open_remedial_pr',
      recommended_action: 'join_existing_pr',
      blockers,
      open_remedial_pr: target,
    };
  }

  return {
    safe_to_start: true,
    reason: 'clear',
    recommended_action: 'start_fresh',
    blockers: [],
    open_remedial_pr: null,
  };
}

function findOpenRemedialPrs() {
  const prs = ghJson([
    'pr',
    'list',
    '--state',
    'open',
    '--base',
    'main',
    '--limit',
    '30',
    '--json',
    'number,url,headRefName,updatedAt,title',
  ]);
  if (!Array.isArray(prs)) {
    return [];
  }
  return prs.filter((pr) => isRemedialBranch(pr.headRefName));
}

function issueHasSessionStartComment(issueNumber) {
  const { owner, repo } = resolveRepo();
  const comments = ghJson([
    'api',
    `repos/${owner}/${repo}/issues/${issueNumber}/comments`,
    '--paginate',
  ]);
  if (!Array.isArray(comments)) {
    return false;
  }
  return comments.some((comment) => (comment.body || '').includes(SESSION_START_MARKER));
}

function findBusyE2eDebugIssues() {
  const issues = ghJson([
    'issue',
    'list',
    '--state',
    'open',
    '--label',
    'busy',
    '--limit',
    '50',
    '--json',
    'number,url,title,updatedAt,labels',
  ]);
  if (!Array.isArray(issues)) {
    return [];
  }
  return issues.filter((issue) => {
    if (issueMatchesE2eDebugSession(issue)) {
      return true;
    }
    return issueHasSessionStartComment(issue.number);
  });
}

function getIssue(issueNumber) {
  return ghJson(['issue', 'view', String(issueNumber), '--json', 'number,url,title,labels']);
}

function issueHasLabel(issue, label) {
  return (issue.labels || []).some((entry) => entry.name === label);
}

function ensureE2eDebugLabel() {
  const created = ghTry([
    'label',
    'create',
    'e2e-debug',
    '--description',
    'Active /e2e-debug pre-UAT remedial session',
    '--color',
    'd93f0b',
  ]);
  if (!created.ok && !/already exists/i.test(created.stderr)) {
    console.error(created.stderr || created.stdout);
    process.exit(1);
  }
}

function postIssueComment(issueNumber, body) {
  const result = spawnSync(
    'node',
    ['scripts/github_issue_workflow.js', 'comment', '--issue', String(issueNumber), '--body', body],
    { cwd: repoRoot, encoding: 'utf8' },
  );
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(1);
  }
}

function rollbackClaim(issueNumber) {
  ghTry([
    'issue',
    'edit',
    String(issueNumber),
    '--remove-label',
    'busy',
    '--remove-label',
    'e2e-debug',
  ]);
}

function claimBlocked(payload) {
  if (process.argv.includes('--json')) {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    console.error(`claim blocked: ${payload.reason}`);
    if (payload.busy_issue?.url) {
      console.error(`busy_issue: ${payload.busy_issue.url}`);
    }
  }
  process.exit(2);
}

function claimWork(issueNumber, mergeSha, { force = false } = {}) {
  const remedialPrs = findOpenRemedialPrs();
  const busyIssues = findBusyE2eDebugIssues();
  const preflight = evaluatePreflight({
    remedialPrs,
    busyIssues,
    join: false,
    force,
    remedialBranch: null,
  });

  if (!preflight.safe_to_start && preflight.reason === 'e2e_debug_in_progress') {
    claimBlocked({
      action: 'claim',
      ok: false,
      reason: 'e2e_debug_in_progress',
      busy_issue: preflight.busy_issue,
      blockers: preflight.blockers,
    });
  }

  if (!preflight.safe_to_start && preflight.reason === 'open_remedial_pr') {
    claimBlocked({
      action: 'claim',
      ok: false,
      reason: 'open_remedial_pr',
      open_remedial_pr: preflight.open_remedial_pr,
      recommended_action: 'join_existing_pr',
      blockers: preflight.blockers,
    });
  }

  const issue = getIssue(issueNumber);
  if (!force && issueHasLabel(issue, 'busy')) {
    claimBlocked({
      action: 'claim',
      ok: false,
      reason: 'issue_already_busy',
      issue: issueNumber,
      url: issue.url,
    });
  }

  ensureE2eDebugLabel();

  const labelResult = ghTry([
    'issue',
    'edit',
    String(issueNumber),
    '--add-label',
    'e2e-debug',
    '--add-label',
    'busy',
  ]);
  if (!labelResult.ok) {
    console.error(labelResult.stderr || labelResult.stdout);
    process.exit(1);
  }

  const body = [
    '## /e2e-debug session start',
    mergeSha ? `- merge_sha: \`${mergeSha}\`` : null,
    `- claimed_at: ${new Date().toISOString()}`,
    '',
    'Remedial orchestration in progress — do not start a duplicate `/e2e-debug` until this session releases `busy`.',
  ]
    .filter(Boolean)
    .join('\n');
  postIssueComment(issueNumber, body);

  const competitors = findBusyE2eDebugIssues().filter((entry) => entry.number !== issueNumber);
  if (competitors.length > 0) {
    rollbackClaim(issueNumber);
    claimBlocked({
      action: 'claim',
      ok: false,
      reason: 'claim_race_detected',
      competitors,
    });
  }

  return { ok: true, issue: issueNumber, merge_sha: mergeSha ?? null };
}

function releaseWork(issueNumber) {
  const body = [
    '## /e2e-debug session end',
    `- released_at: ${new Date().toISOString()}`,
    '',
    'Remedial PR ready for `/babysit-uat` handoff (or session halted).',
  ].join('\n');

  postIssueComment(issueNumber, body);

  ghRun([
    'issue',
    'edit',
    String(issueNumber),
    '--remove-label',
    'busy',
    '--remove-label',
    'e2e-debug',
  ]);
  return { ok: true, issue: issueNumber };
}

function main() {
  const opts = parseArgs();

  if (opts.claim) {
    const claim = claimWork(opts.issue, opts.mergeSha, { force: opts.force });
    const payload = { action: 'claim', ...claim };
    if (opts.json) {
      console.log(JSON.stringify(payload, null, 2));
    } else {
      console.log(`claimed issue #${opts.issue}`);
    }
    return;
  }

  if (opts.release) {
    const released = releaseWork(opts.issue);
    const payload = { action: 'release', ...released };
    if (opts.json) {
      console.log(JSON.stringify(payload, null, 2));
    } else {
      console.log(`released issue #${opts.issue}`);
    }
    return;
  }

  const remedialPrs = findOpenRemedialPrs();
  const busyIssues = findBusyE2eDebugIssues();
  const result = evaluatePreflight({
    remedialPrs,
    busyIssues,
    join: opts.join,
    force: opts.force,
    remedialBranch: opts.remedialBranch,
  });

  const payload = {
    ...result,
    remedial_prs: remedialPrs,
    busy_issues: busyIssues,
  };

  if (opts.json) {
    console.log(JSON.stringify(payload, null, 2));
  } else if (result.safe_to_start) {
    console.log(`safe_to_start: yes (${result.reason})`);
    if (result.open_remedial_pr) {
      console.log(`join: ${result.open_remedial_pr.url}`);
    }
  } else {
    console.log(`safe_to_start: no (${result.reason})`);
    console.log(`recommended_action: ${result.recommended_action}`);
    for (const blocker of result.blockers) {
      console.log(`blocker: ${blocker.type} ${blocker.url}`);
    }
  }

  if (!result.safe_to_start) {
    process.exit(2);
  }
}

const invokedAsMain =
  process.argv[1] && fileURLToPath(import.meta.url) === fileURLToPath(`file://${process.argv[1]}`);
if (invokedAsMain) {
  main();
}
