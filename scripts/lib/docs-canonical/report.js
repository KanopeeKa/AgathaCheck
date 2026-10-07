'use strict';

const { SEVERITY } = require('./constants');

/** @typedef {{ ruleId: string, severity: string, file?: string, line?: number, message: string }} Finding */

function formatAnnotation(finding, gateMode) {
  let sev = finding.severity;
  if (gateMode === 'warn' && sev === SEVERITY.BLOCK) {
    sev = SEVERITY.WARN;
  }
  const file = finding.file || '';
  const line = finding.line || 1;
  const tag = sev === SEVERITY.WARN ? 'warning' : sev === SEVERITY.BLOCK ? 'error' : 'notice';
  const loc = file ? `${file},line=${line},col=1` : '';
  const prefix = loc ? `::${tag} file=${loc}::` : `::${tag}::`;
  return `${prefix}[${finding.ruleId}] ${finding.message}`;
}

function summarize(findings, gateMode) {
  let block = 0;
  let warn = 0;
  for (const f of findings) {
    if (f.severity === SEVERITY.BLOCK) block += 1;
    else if (f.severity === SEVERITY.WARN) warn += 1;
  }
  // REPORT findings only come from report modes (--all, --report-duplicates,
  // --closed-issues, --memory --all); print them as notices so the weekly job can grep them.
  for (const f of findings) {
    console.error(formatAnnotation(f, gateMode));
  }
  if (findings.length) {
    console.error(`docs-canonical: ${block} block, ${warn} warn (${findings.length} total)`);
  }
  const failBlocks = gateMode === 'block' && block > 0;
  return failBlocks ? 1 : 0;
}

module.exports = { formatAnnotation, summarize };
