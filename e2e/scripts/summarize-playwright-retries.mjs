#!/usr/bin/env node
/**
 * Summarize Playwright retry outcomes from list-reporter text or JSON report files.
 *
 * Usage:
 *   npx playwright test --reporter=list 2>&1 | node e2e/scripts/summarize-playwright-retries.mjs
 *   node e2e/scripts/summarize-playwright-retries.mjs --file /path/to/list-output.txt
 *   node e2e/scripts/summarize-playwright-retries.mjs --json e2e/playwright-report/results.json
 *
 * Exit 0 always (instrumentation); prints JSON summary to stdout.
 */
import fs from 'node:fs';
import path from 'node:path';

function parseArgs(argv) {
  const opts = { file: null, json: null };
  for (let i = 2; i < argv.length; i += 1) {
    if (argv[i] === '--file' && argv[i + 1]) {
      opts.file = argv[++i];
    } else if (argv[i] === '--json' && argv[i + 1]) {
      opts.json = argv[++i];
    } else if (argv[i] === '--help' || argv[i] === '-h') {
      console.log(`Usage: summarize-playwright-retries.mjs [--file list.txt] [--json report.json]`);
      process.exit(0);
    }
  }
  return opts;
}

/** @typedef {{ id: string, title: string, outcome: 'pass-first' | 'pass-on-retry' | 'fail-both' | 'pass-only' }} TestOutcome */

/**
 * Parse Playwright list reporter lines (CI log friendly).
 * @param {string} text
 * @returns {TestOutcome[]}
 */
function parseListReporter(text) {
  /** @type {Map<string, { title: string, attempts: Array<'fail' | 'pass'> }>} */
  const byKey = new Map();

  const lines = text.split(/\r?\n/);
  for (const line of lines) {
    const retryMatch = line.match(/\bretry #(\d+)\b/i);
    const titleMatch = line.match(/›\s+(.+?)\s*(?:\(\d+(?:\.\d+)?s\))?$/);
    const isPass = /^\s*[✓✔]/.test(line) || /\bpassed\b/i.test(line);
    const isFail = /^\s*[✘✗xX]/.test(line) || /\bfailed\b/i.test(line);

    if (!titleMatch && !retryMatch) continue;

    const title = titleMatch?.[1]?.trim() ?? 'unknown';
    const key = title.replace(/\s*\(retry #\d+\)\s*$/i, '').trim();

    if (!byKey.has(key)) {
      byKey.set(key, { title: key, attempts: [] });
    }
    const entry = byKey.get(key);

    if (retryMatch) {
      // Retry attempt line — outcome on same or next meaningful line
      if (isPass) entry.attempts.push('pass');
      else if (isFail) entry.attempts.push('fail');
      continue;
    }

    if (isPass) entry.attempts.push('pass');
    else if (isFail) entry.attempts.push('fail');
  }

  /** @type {TestOutcome[]} */
  const results = [];
  for (const [id, { title, attempts }] of byKey) {
    if (attempts.length === 0) continue;
    let outcome;
    if (attempts.length === 1 && attempts[0] === 'pass') {
      outcome = 'pass-only';
    } else if (attempts[0] === 'fail' && attempts.slice(1).some((a) => a === 'pass')) {
      outcome = 'pass-on-retry';
    } else if (attempts.every((a) => a === 'fail')) {
      outcome = 'fail-both';
    } else if (attempts[0] === 'pass') {
      outcome = 'pass-first';
    } else {
      outcome = 'fail-both';
    }
    results.push({ id, title, outcome });
  }
  return results;
}

/**
 * Parse Playwright JSON report (reporter=json output file).
 * @param {unknown} data
 * @returns {TestOutcome[]}
 */
function parseJsonReport(data) {
  if (!data || typeof data !== 'object') return [];
  const suites = /** @type {{ suites?: unknown[] }} */ (data).suites ?? [];
  /** @type {TestOutcome[]} */
  const results = [];

  function walk(suiteList) {
    for (const suite of suiteList) {
      if (!suite || typeof suite !== 'object') continue;
      const s = /** @type {{ specs?: unknown[], suites?: unknown[] }} */ (suite);
      for (const spec of s.specs ?? []) {
        if (!spec || typeof spec !== 'object') continue;
        const sp = /** @type {{ title?: string, tests?: unknown[] }} */ (spec);
        for (const test of sp.tests ?? []) {
          if (!test || typeof test !== 'object') continue;
          const t = /** @type {{ results?: Array<{ status?: string }> }} */ (test);
          const statuses = (t.results ?? []).map((r) => r.status);
          if (statuses.length === 0) continue;
          const title = sp.title ?? 'unknown';
          let outcome;
          if (statuses.length === 1 && statuses[0] === 'passed') {
            outcome = 'pass-only';
          } else if (statuses[0] === 'failed' && statuses.slice(1).includes('passed')) {
            outcome = 'pass-on-retry';
          } else if (statuses.every((st) => st === 'failed' || st === 'timedOut')) {
            outcome = 'fail-both';
          } else if (statuses[0] === 'passed') {
            outcome = 'pass-first';
          } else {
            outcome = 'fail-both';
          }
          results.push({ id: title, title, outcome });
        }
      }
      if (s.suites?.length) walk(s.suites);
    }
  }

  walk(suites);
  return results;
}

function summarize(outcomes) {
  const counts = {
    total: outcomes.length,
    pass_first: 0,
    pass_only: 0,
    pass_on_retry: 0,
    fail_both: 0,
  };
  for (const o of outcomes) {
    if (o.outcome === 'pass-first') counts.pass_first += 1;
    if (o.outcome === 'pass-only') counts.pass_only += 1;
    if (o.outcome === 'pass-on-retry') counts.pass_on_retry += 1;
    if (o.outcome === 'fail-both') counts.fail_both += 1;
  }
  const firstFail = counts.pass_on_retry + counts.fail_both;
  const recoveryRate =
    firstFail > 0 ? Number((counts.pass_on_retry / firstFail).toFixed(3)) : null;
  return { counts, recovery_rate_on_first_fail: recoveryRate, tests: outcomes };
}

async function readStdin() {
  if (process.stdin.isTTY) return '';
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf8');
}

async function main() {
  const opts = parseArgs(process.argv);
  let outcomes = [];

  if (opts.json) {
    const abs = path.resolve(opts.json);
    const raw = JSON.parse(fs.readFileSync(abs, 'utf8'));
    outcomes = parseJsonReport(raw);
  } else {
    const text = opts.file
      ? fs.readFileSync(path.resolve(opts.file), 'utf8')
      : await readStdin();
    if (!text.trim()) {
      console.log(JSON.stringify(summarize([]), null, 2));
      console.error('summarize-playwright-retries: no input (empty summary)');
      return;
    }
    outcomes = parseListReporter(text);
  }

  const summary = summarize(outcomes);
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((err) => {
  console.error(err.message || err);
  console.log(
    JSON.stringify(
      {
        counts: {
          total: 0,
          pass_first: 0,
          pass_only: 0,
          pass_on_retry: 0,
          fail_both: 0,
        },
        recovery_rate_on_first_fail: null,
        tests: [],
        error: String(err.message || err),
      },
      null,
      2,
    ),
  );
});
