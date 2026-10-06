'use strict';

const { VALID_REQ_STATUSES, VALID_DECISION_STATUSES } = require('./constants');
const { featureIdPrefix } = require('./paths');

function splitTableRows(body, headerMarker) {
  const idx = body.search(new RegExp(`^## ${headerMarker}`, 'im'));
  if (idx < 0) {
    return null;
  }
  const rest = body.slice(idx);
  const lines = rest.split('\n');
  let start = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim().startsWith('|') && lines[i].includes('---')) {
      start = i + 1;
      break;
    }
    if (lines[i].trim().startsWith('| ID |')) {
      start = i + 2;
      break;
    }
  }
  if (start < 0) {
    return [];
  }
  const rows = [];
  for (let i = start; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line.startsWith('|')) {
      break;
    }
    if (line.includes('---')) {
      continue;
    }
    const cells = line
      .split('|')
      .map((c) => c.trim())
      .filter((c, ci) => ci > 0 && ci < line.split('|').length - 1);
    if (cells.length) {
      rows.push(cells);
    }
  }
  return rows;
}

function parseRequirements(body) {
  const rows = splitTableRows(body, 'Requirements') || [];
  return rows.map((cells) => ({
    id: cells[0] || '',
    rule: cells[1] || '',
    status: cells[2] || '',
  }));
}

function parseAcceptanceCriteria(body) {
  const rows = splitTableRows(body, 'Acceptance criteria') || [];
  return rows.map((cells) => ({
    gwt: cells[0] || '',
    requirement: cells[1] || '',
    coverage: cells[2] || '',
  }));
}

function parseDecisionLog(body) {
  const rows = splitTableRows(body, 'Decision log') || [];
  return rows.map((cells) => ({
    id: cells[0] || '',
    decision: cells[1] || '',
    rationale: cells[2] || '',
    status: cells[3] || '',
    date: cells[4] || '',
    pr: cells[5] || '',
  }));
}

function hasDecisionLogSection(body) {
  return /^## Decision log\s*$/im.test(body);
}

function detectDeliveryNoise(body) {
  const issues = [];
  if (/^## Phasing\s*$/im.test(body)) {
    issues.push({ kind: 'phasing-h2', line: lineNumberOf(body, /^## Phasing/m) });
  }
  if (/\*\*amended\s+\d{4}-\d{2}-\d{2}/i.test(body) || /\*\*Status:\*\*.*amended/i.test(body)) {
    issues.push({ kind: 'amendment-banner', line: 1 });
  }
  const reqs = parseRequirements(body);
  for (const row of reqs) {
    if (!row.id || !row.status) {
      continue;
    }
    if (/^In delivery$/i.test(row.status.trim())) {
      continue;
    }
    if (/shipped/i.test(row.status) && !/-R-\d{3}$/i.test(row.id)) {
      issues.push({ kind: 'phase-shipped', id: row.id, line: lineNumberOf(body, new RegExp(`\\| ${row.id} `)) });
    }
  }
  return issues;
}

function lineNumberOf(text, re) {
  const m = text.match(re);
  if (!m || m.index === undefined) {
    return 1;
  }
  return text.slice(0, m.index).split('\n').length;
}

function validateIdPrefix(meta, rows, kind) {
  const prefix = featureIdPrefix(meta?.feature_id);
  if (!prefix) {
    return [];
  }
  const bad = [];
  const suffix = kind === 'req' ? '-R-' : '-D-';
  for (const row of rows) {
    const id = row.id || '';
    if (!id || !id.includes(suffix)) {
      continue;
    }
    const expectedStart = `${prefix}${suffix}`;
    if (!id.toUpperCase().startsWith(expectedStart)) {
      bad.push(id);
    }
  }
  return bad;
}

function validateDecisionStatuses(rows) {
  const bad = [];
  for (const row of rows) {
    const st = (row.status || '').trim();
    if (!st) {
      continue;
    }
    if (!VALID_DECISION_STATUSES.test(st) && !/^Superseded by /i.test(st)) {
      bad.push(row.id || st);
    }
  }
  return bad;
}

function validateRequirementStatuses(rows) {
  const bad = [];
  for (const row of rows) {
    const st = (row.status || '').trim();
    if (st && !VALID_REQ_STATUSES.has(st)) {
      bad.push(`${row.id}: ${st}`);
    }
  }
  return bad;
}

module.exports = {
  parseRequirements,
  parseAcceptanceCriteria,
  parseDecisionLog,
  hasDecisionLogSection,
  detectDeliveryNoise,
  validateIdPrefix,
  validateDecisionStatuses,
  validateRequirementStatuses,
  splitTableRows,
};
