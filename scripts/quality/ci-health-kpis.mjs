#!/usr/bin/env node
/**
 * Advisory CI health KPIs from GitHub Actions (PR CI + Pre-UAT).
 *
 * Usage:
 *   node scripts/quality/ci-health-kpis.mjs [--days 14]
 *
 * Requires GH_TOKEN or GITHUB_TOKEN with actions:read (workflow job on main).
 */
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';

const REPO = process.env.GITHUB_REPOSITORY || 'KanopeeKa/AgathaCheck';

function parseDays(argv) {
  const i = argv.indexOf('--days');
  if (i === -1 || !argv[i + 1]) return 14;
  return Math.max(1, Number(argv[i + 1]) || 14);
}

function ghApi(path) {
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  if (!token) {
    return null;
  }
  try {
    const out = execFileSync(
      'gh',
      ['api', path, '-H', 'Accept: application/vnd.github+json'],
      { encoding: 'utf8', env: { ...process.env, GH_TOKEN: token, GITHUB_TOKEN: token } },
    );
    return JSON.parse(out);
  } catch (err) {
    console.warn(`ci-health-kpis: gh api failed for ${path}: ${err.message}`);
    return null;
  }
}

function percentile(sorted, p) {
  if (sorted.length === 0) return 0;
  const idx = Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length));
  return sorted[idx];
}

function summarizeRuns(runs, cutoffMs) {
  const durations = [];
  let success = 0;
  let failure = 0;
  let cancelled = 0;
  for (const run of runs) {
    const started = Date.parse(run.run_started_at || run.created_at);
    if (Number.isNaN(started) || started < cutoffMs) continue;
    if (run.status !== 'completed') continue;
    const updated = Date.parse(run.updated_at);
    if (!Number.isNaN(updated) && updated > started) {
      durations.push((updated - started) / 1000);
    }
    if (run.conclusion === 'success') success += 1;
    else if (run.conclusion === 'failure') failure += 1;
    else if (run.conclusion === 'cancelled') cancelled += 1;
  }
  durations.sort((a, b) => a - b);
  const decided = success + failure;
  return {
    samples: durations.length,
    success,
    failure,
    cancelled,
    passRate: decided > 0 ? success / decided : null,
    p50Sec: percentile(durations, 50),
    p90Sec: percentile(durations, 90),
  };
}

function fetchWorkflowRuns(workflowFile, { perPage = 100, event } = {}) {
  const base = `/repos/${REPO}/actions/workflows/${workflowFile}/runs?per_page=${perPage}`;
  const path = event ? `${base}&event=${encodeURIComponent(event)}` : `${base}&exclude_pull_requests=false`;
  return ghApi(path);
}

function remediationShare(days) {
  try {
    execFileSync('git', ['fetch', 'origin', 'main'], { stdio: 'ignore' });
    const since = new Date(Date.now() - days * 86400000).toISOString().slice(0, 10);
    const totalOut = execFileSync(
      'git',
      ['log', 'origin/main', `--since=${since}`, '--oneline'],
      { encoding: 'utf8' },
    );
    const totalLines = totalOut.trim() ? totalOut.trim().split('\n') : [];
    const remedial = totalLines.filter(
      (line) => /preuat|e2e-debug|pre-uat/i.test(line),
    ).length;
    const total = totalLines.length;
    return { remedialCommits: remedial, mainCommits: total, share: total > 0 ? remedial / total : null };
  } catch {
    return { remedialCommits: 0, mainCommits: 0, share: null };
  }
}

function ciprPassRateNote(ci) {
  const decided = (ci.success ?? 0) + (ci.failure ?? 0);
  if (!decided) return null;
  const rate = ci.passRate;
  const lines = [
    '',
    '### CIPR pass-rate (PR CI)',
    '',
    `Raw pass rate (success ÷ success+failure): **${(rate * 100).toFixed(1)}%** (${ci.success} / ${decided} in window).`,
    'Targets and baseline: `docs/agent-efficiency/plans/ci-pass-rate-improvement.md` §2.',
    '',
  ];
  return lines.join('\n');
}

function formatSummary(kpis) {
  const lines = ['## CI health KPIs (advisory)', ''];
  if (!kpis.tokenPresent) {
    lines.push('_GH_TOKEN not set — skipped GitHub API metrics._');
    return lines.join('\n');
  }
  const fmtPct = (v) => (v == null ? 'n/a' : `${(v * 100).toFixed(1)}%`);
  const fmtSec = (v) => (v ? `${Math.round(v)}s` : 'n/a');
  lines.push(`Window: last **${kpis.days}** days (workflow run sample ≤100 each).`);
  lines.push('');
  lines.push('| Workflow | Pass rate | p50 | p90 | Samples |');
  lines.push('|----------|----------:|----:|----:|--------:|');
  lines.push(
    `| PR CI (\`ci.yml\`) | ${fmtPct(kpis.ci.passRate)} | ${fmtSec(kpis.ci.p50Sec)} | ${fmtSec(kpis.ci.p90Sec)} | ${kpis.ci.samples} |`,
  );
  lines.push(
    `| Pre-UAT (\`pre-uat-e2e.yml\`) | ${fmtPct(kpis.preUat.passRate)} | ${fmtSec(kpis.preUat.p50Sec)} | ${fmtSec(kpis.preUat.p90Sec)} | ${kpis.preUat.samples} |`,
  );
  lines.push('');
  lines.push(
    `Post-merge remedial commits (grep preuat/e2e): **${kpis.remediation.remedialCommits}** / ${kpis.remediation.mainCommits} on main (${fmtPct(kpis.remediation.share)}).`,
  );
  const cipr = ciprPassRateNote(kpis.ci);
  if (cipr) lines.push(cipr);
  return lines.join('\n');
}

function main() {
  const days = parseDays(process.argv);
  const cutoffMs = Date.now() - days * 86400000;
  const tokenPresent = Boolean(process.env.GITHUB_TOKEN || process.env.GH_TOKEN);

  const ciRuns = fetchWorkflowRuns('ci.yml', { event: 'pull_request' });
  const preRuns = fetchWorkflowRuns('pre-uat-e2e.yml');

  const kpis = {
    days,
    tokenPresent,
    ci: summarizeRuns(ciRuns?.workflow_runs || [], cutoffMs),
    preUat: summarizeRuns(preRuns?.workflow_runs || [], cutoffMs),
    remediation: remediationShare(days),
  };

  const summary = formatSummary(kpis);
  console.log(summary);
  if (process.env.GITHUB_STEP_SUMMARY) {
    fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, `${summary}\n`);
  }
}

main();
