'use strict';

const { RULE_FIX } = require('./constants');

function gateMode() {
  const mode = (process.env.DOCS_GATE_MODE || 'block').toLowerCase();
  return mode === 'warn' ? 'warn' : 'block';
}

/**
 * @typedef {{ ruleId: string, severity: 'BLOCK'|'WARN', message: string, file?: string, line?: number }} Finding
 */

function finding(ruleId, severity, message, file, line) {
  const fix = RULE_FIX[ruleId];
  const full = fix ? `${message} Fix: ${fix}` : message;
  return { ruleId, severity, message: full, file, line };
}

function emitFindings(findings) {
  const mode = gateMode();
  let blockCount = 0;
  let warnCount = 0;

  for (const f of findings) {
    const isBlock = f.severity === 'BLOCK';
    if (isBlock) {
      blockCount += 1;
    } else {
      warnCount += 1;
    }
    const level = isBlock && mode === 'block' ? 'error' : 'warning';
    const filePart = f.file ? `file=${f.file}` : '';
    const linePart = f.line ? `,line=${f.line}` : '';
    const title = `${f.ruleId}: ${f.message.split(' Fix:')[0]}`;
    console.error(`::${level} ${filePart}${linePart}::${title}`);
    console.error(`[${f.ruleId}] ${f.message}`);
  }

  if (blockCount > 0 && mode === 'block') {
    return 1;
  }
  if (findings.length > 0 && mode === 'warn') {
    console.error(`DOCS_GATE_MODE=warn: ${blockCount} would-block, ${warnCount} warn — exiting 0`);
  }
  return 0;
}

module.exports = { gateMode, finding, emitFindings };
