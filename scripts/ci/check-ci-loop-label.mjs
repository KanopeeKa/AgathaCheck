#!/usr/bin/env node
/**
 * Fail-open ci-loop label guard for pre-push-changed.sh (exit 4 when labelled).
 */
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

const EXIT_CI_LOOP = 4;

function gh(args) {
  return spawnSync('gh', args, {
    cwd: REPO_ROOT,
    encoding: 'utf8',
    env: process.env,
  });
}

function main() {
  const overrideIdx = process.argv.indexOf('--ci-loop-override');
  const overrideReason = overrideIdx >= 0 ? process.argv[overrideIdx + 1] : null;
  if (overrideIdx >= 0 && overrideReason) {
    console.log(`ci-loop override: ${overrideReason}`);
    return;
  }

  const branch = spawnSync('git', ['rev-parse', '--abbrev-ref', 'HEAD'], {
    cwd: REPO_ROOT,
    encoding: 'utf8',
  });
  if (branch.status !== 0 || !branch.stdout.trim()) {
    console.warn('ci-loop check: cannot read branch — continuing');
    return;
  }

  const prList = gh([
    'pr',
    'list',
    '--head',
    branch.stdout.trim(),
    '--state',
    'open',
    '--json',
    'number,labels',
    '--limit',
    '50',
  ]);
  if (prList.status !== 0) {
    console.warn(`ci-loop check: gh unavailable (${prList.stderr?.trim() || 'error'}) — continuing`);
    return;
  }
  let parsed;
  try {
    parsed = JSON.parse(prList.stdout);
  } catch {
    console.warn('ci-loop check: bad gh JSON — continuing');
    return;
  }
  if (!Array.isArray(parsed) || parsed.length === 0) {
    return;
  }
  const hasCiLoop = parsed.some((pr) =>
    (pr.labels ?? []).some((l) => l.name === 'ci-loop'),
  );
  if (!hasCiLoop) {
    return;
  }
  console.error(
    'ci-loop label is on this PR — stop pushing. Reproduce locally, then push with --ci-loop-override "<reason>" if you must.',
  );
  process.exit(EXIT_CI_LOOP);
}

main();
