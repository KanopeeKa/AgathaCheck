#!/usr/bin/env node
'use strict';

/**
 * Canonical documentation CI gates (docs-ci-gates-a496).
 *
 * Usage:
 *   node scripts/check_docs_canonical.js [--pr-body [--body-file path]]
 *   node scripts/check_docs_canonical.js [--changes [--all]]
 *   node scripts/check_docs_canonical.js --shape | --ids | --trace
 *   node scripts/check_docs_canonical.js --report [--json]
 *   node scripts/check_docs_canonical.js --baseline-report
 *   node scripts/check_docs_canonical.js   # default: all diff-scoped gates
 *
 * Env: DOCS_BASE_SHA, DOCS_HEAD_SHA, DOCS_GATE_MODE=warn|block, DOCS_PR_AUTHOR
 */

const fs = require('fs');
const path = require('path');

const { resolveShas, diffNameOnly } = require('./lib/docs-canonical/git');
const { loadBaseline, checkBaselineFileDiff } = require('./lib/docs-canonical/baseline');
const { emitFindings, finding } = require('./lib/docs-canonical/findings');
const { gatePrBody } = require('./lib/docs-canonical/gate-pr-body');
const { gateChanges } = require('./lib/docs-canonical/gate-changes');
const { gateShape } = require('./lib/docs-canonical/gate-shape');
const { gateIds } = require('./lib/docs-canonical/gate-ids');
const { gateTrace, buildBddIndex, buildTestIndex } = require('./lib/docs-canonical/gate-trace');
const { gateReport } = require('./lib/docs-canonical/gate-report');
const { runHygieneReport } = require('./lib/docs-canonical/hygiene');

const ROOT = path.resolve(__dirname, '..');

function parseArgs(argv) {
  const opts = {
    root: ROOT,
    prBody: false,
    bodyFile: null,
    changes: false,
    changesAll: false,
    shape: false,
    ids: false,
    trace: false,
    report: false,
    reportJson: false,
    baselineReport: false,
    hygiene: false,
    author: process.env.DOCS_PR_AUTHOR || null,
    clock: process.env.DOCS_GATE_CLOCK || null,
  };

  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--pr-body') {
      opts.prBody = true;
    } else if (a === '--body-file' && argv[i + 1]) {
      opts.bodyFile = argv[++i];
    } else if (a === '--changes') {
      opts.changes = true;
    } else if (a === '--all') {
      opts.changesAll = true;
    } else if (a === '--shape') {
      opts.shape = true;
    } else if (a === '--ids') {
      opts.ids = true;
    } else if (a === '--trace') {
      opts.trace = true;
    } else if (a === '--report') {
      opts.report = true;
    } else if (a === '--json') {
      opts.reportJson = true;
    } else if (a === '--baseline-report') {
      opts.baselineReport = true;
    } else if (a === '--hygiene') {
      opts.hygiene = true;
    } else if (a === '--root' && argv[i + 1]) {
      opts.root = path.resolve(argv[++i]);
    } else if (a === '--author' && argv[i + 1]) {
      opts.author = argv[++i];
    } else if (a === '--help' || a === '-h') {
      console.log(fs.readFileSync(__filename, 'utf8').split('\n').slice(0, 16).join('\n'));
      process.exit(0);
    } else {
      console.error(`Unknown argument: ${a}`);
      process.exit(2);
    }
  }
  return opts;
}

function readPrBody(opts) {
  if (opts.bodyFile) {
    return fs.readFileSync(opts.bodyFile, 'utf8');
  }
  if (process.env.GITHUB_EVENT_PATH && fs.existsSync(process.env.GITHUB_EVENT_PATH)) {
    try {
      const ev = JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
      return ev.pull_request?.body || '';
    } catch {
      return '';
    }
  }
  return process.env.DOCS_PR_BODY || '';
}

function main() {
  const opts = parseArgs(process.argv);
  const { base, head } = resolveShas(
    opts.root,
    process.env.DOCS_BASE_SHA,
    process.env.DOCS_HEAD_SHA,
  );

  if (opts.report) {
    const { exitCode } = gateReport({ root: opts.root, json: opts.reportJson });
    process.exit(exitCode);
  }

  if (opts.baselineReport) {
    const md = runHygieneReport(opts.root, { clock: opts.clock });
    console.log(md || 'No hygiene findings.');
    process.exit(0);
  }

  if (opts.hygiene) {
    console.log(runHygieneReport(opts.root, { clock: opts.clock }));
    process.exit(0);
  }

  const baseline = loadBaseline(opts.root);
  const diffFiles = diffNameOnly(opts.root, base, head);
  const bddIndex = buildBddIndex(opts.root);
  const testIndex = buildTestIndex(opts.root);

  const ctx = {
    root: opts.root,
    base,
    head,
    diffFiles,
    baseline,
    prBody: readPrBody(opts),
    author: opts.author,
    bddIndex,
    testIndex,
    clock: opts.clock,
    scanAll: opts.changesAll,
  };

  const explicit =
    opts.prBody ||
    opts.changes ||
    opts.shape ||
    opts.ids ||
    opts.trace;
  const runAll = !explicit;

  const findings = [];

  const baselineDiffFindings = checkBaselineFileDiff(diffFiles, baseline, opts.root, loadBaseline(opts.root));
  findings.push(...baselineDiffFindings.map((f) => finding(f.ruleId, f.severity, f.message, f.file)));

  if (runAll || opts.prBody) {
    findings.push(...gatePrBody(ctx));
  }
  if (runAll || opts.changes) {
    findings.push(...gateChanges(ctx));
  }
  if (runAll || opts.shape) {
    findings.push(...gateShape(ctx));
  }
  if (runAll || opts.ids) {
    findings.push(...gateIds(ctx));
  }
  if (runAll || opts.trace) {
    findings.push(...gateTrace(ctx));
  }

  const code = emitFindings(findings);
  if (findings.length === 0) {
    console.log('check_docs_canonical: OK');
  } else {
    console.error(`check_docs_canonical: ${findings.length} finding(s)`);
  }
  process.exit(code);
}

main();
