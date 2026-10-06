#!/usr/bin/env node
'use strict';

/** Documentation CI gates — docs/domains/documentation/changes/docs-ci-gates.md */
const fs = require('fs');
const path = require('path');
const { diffNameStatus } = require('./lib/docs-canonical/diff');
const {
  loadBaseline,
  checkBaselineRatchet,
  baselineReport,
  generateBaselineFile,
} = require('./lib/docs-canonical/baseline');
const { runGatePrBody } = require('./lib/docs-canonical/gates-pr-body');
const { runGateChanges } = require('./lib/docs-canonical/gates-changes');
const { runGateShape } = require('./lib/docs-canonical/gates-shape');
const { runGateIds } = require('./lib/docs-canonical/gates-ids');
const { runGateTrace, buildDomainReport, baselineReportMarkdown } = require('./lib/docs-canonical/gates-trace');
const { summarize } = require('./lib/docs-canonical/report');

const ROOT = path.resolve(__dirname, '..');

function parseArgs(argv) {
  const o = {
    base: process.env.DOCS_BASE || 'origin/main',
    gateMode: process.env.DOCS_GATE_MODE || 'block',
    prBody: false,
    bodyFile: null,
    changes: false,
    changesAll: false,
    shape: false,
    ids: false,
    reportDuplicates: false,
    trace: false,
    closedIssues: false,
    report: false,
    json: false,
    baselineReport: false,
    writeBaseline: false,
    author: process.env.GITHUB_ACTOR || '',
    labels: (process.env.DOCS_GATE_LABELS || '').split(',').filter(Boolean),
  };
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (a === '--pr-body') o.prBody = true;
    else if (a === '--body-file') o.bodyFile = argv[++i];
    else if (a === '--base') o.base = argv[++i];
    else if (a === '--root') process.env.DOCS_CANONICAL_ROOT = path.resolve(argv[++i]);
    else if (a === '--changes') o.changes = true;
    else if (a === '--all') o.changesAll = true;
    else if (a === '--shape') o.shape = true;
    else if (a === '--ids') o.ids = true;
    else if (a === '--report-duplicates') o.reportDuplicates = true;
    else if (a === '--trace') o.trace = true;
    else if (a === '--closed-issues') o.closedIssues = true;
    else if (a === '--report') o.report = true;
    else if (a === '--json') o.json = true;
    else if (a === '--baseline-report') o.baselineReport = true;
    else if (a === '--write-baseline') o.writeBaseline = true;
    else if (a === '--author') o.author = argv[++i];
  }
  const any =
    o.prBody || o.changes || o.shape || o.ids || o.trace || o.report || o.baselineReport || o.writeBaseline;
  if (!any) o.changes = o.shape = o.ids = o.trace = true;
  return o;
}

function rootDir() {
  return process.env.DOCS_CANONICAL_ROOT ? path.resolve(process.env.DOCS_CANONICAL_ROOT) : ROOT;
}

function readBody(opts) {
  if (opts.bodyFile && fs.existsSync(opts.bodyFile)) return fs.readFileSync(opts.bodyFile, 'utf8');
  return process.env.PR_BODY || '';
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const root = rootDir();
  if (opts.writeBaseline) {
    generateBaselineFile(root);
    process.exit(0);
  }
  const baseline = loadBaseline(root);
  const diff = diffNameStatus(root, opts.base);
  const ctx = {
    root,
    baseRef: opts.base,
    diff,
    baseline,
    scopeAll: opts.changesAll,
    now: process.env.DOCS_GATE_NOW ? new Date(process.env.DOCS_GATE_NOW) : new Date(),
    closedIssues: opts.closedIssues
      ? new Set(JSON.parse(process.env.DOCS_CLOSED_ISSUES || '[]'))
      : null,
  };
  const findings = [...checkBaselineRatchet(root, diff, opts.base)];
  if (opts.prBody) {
    findings.push(
      ...runGatePrBody({ ...ctx, bodyText: readBody(opts), author: opts.author, labels: opts.labels }),
    );
  }
  if (opts.changes) findings.push(...runGateChanges(ctx));
  if (opts.shape) findings.push(...runGateShape(ctx));
  if (opts.ids) findings.push(...runGateIds({ ...ctx, reportDuplicates: opts.reportDuplicates }));
  if (opts.trace) findings.push(...runGateTrace(ctx));
  if (opts.baselineReport) console.log(JSON.stringify(baselineReport(root), null, 2));
  if (opts.report) {
    const domainReport = buildDomainReport(root, baseline);
    if (opts.json) {
      console.log(
        JSON.stringify(
          { domains: domainReport.byDomain, canonical_ratio: domainReport.canonical_ratio },
          null,
          2,
        ),
      );
    } else console.log(baselineReportMarkdown(root, baseline));
  }
  process.exit(summarize(findings.filter((f) => f.severity !== 'REPORT'), opts.gateMode));
}

if (require.main === module) {
  try {
    main();
  } catch (e) {
    console.error(`check_docs_canonical: ${e.message}`);
    process.exit(1);
  }
}

module.exports = { parseArgs, ROOT };
