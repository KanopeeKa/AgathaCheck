'use strict';

const path = require('path');
const { SEVERITY } = require('./constants');
const { rel } = require('./paths');
const { isBaselineChange } = require('./baseline');
const { parseDoc } = require('./parse');
const { touchedInDiff } = require('./diff');

const VALID_STATUS = new Set(['proposed', 'in-delivery']);

function formatStatusSince(value) {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString().slice(0, 10);
  }
  return String(value || '').slice(0, 10);
}

function resolveFoldsInto(root, foldsInto, diff) {
  if (!foldsInto || typeof foldsInto !== 'string') return false;
  const target = foldsInto.replace(/^\//, '');
  if (target === 'docs/domains/documentation/standards.md') return true;
  if (!target.includes('/features/') || !target.endsWith('.md')) return false;
  const full = path.join(root, target);
  if (require('fs').existsSync(full)) return true;
  return diff.added.has(target);
}

function runGateChanges(ctx) {
  const findings = [];
  const { root, diff, baseline, now, scopeAll } = ctx;
  const { listChangeDocs } = require('./paths');
  const clock = now || new Date();

  for (const filePath of listChangeDocs(root)) {
    const relPath = rel(root, filePath);
    if (relPath.includes('/changes/archive/')) continue;
    const inBaseline = isBaselineChange(baseline, relPath);
    const touched = touchedInDiff(diff, relPath);
    if (!scopeAll && !touched) continue;
    if (inBaseline && !touched) continue;

    const { meta } = parseDoc(filePath, root);
    if (!VALID_STATUS.has(String(meta.status || '').toLowerCase())) {
      findings.push({
        ruleId: 'R-B1',
        severity: SEVERITY.BLOCK,
        file: relPath,
        message: 'Change doc status must be proposed or in-delivery.',
      });
    }
    if (!resolveFoldsInto(root, meta.folds_into, diff)) {
      findings.push({
        ruleId: 'R-B2',
        severity: SEVERITY.BLOCK,
        file: relPath,
        message: 'folds_into must point to an existing features/*.md at HEAD or added in this PR.',
      });
    }
    if (String(meta.status || '').toLowerCase() === 'in-delivery' && !meta.plan) {
      findings.push({
        ruleId: 'R-B3',
        severity: SEVERITY.BLOCK,
        file: relPath,
        message: 'in-delivery change docs require plan and valid status_since.',
      });
    }
    const statusSince = formatStatusSince(meta.status_since);
    if (!statusSince || !/^\d{4}-\d{2}-\d{2}$/.test(statusSince)) {
      findings.push({
        ruleId: 'R-B3',
        severity: SEVERITY.BLOCK,
        file: relPath,
        message: 'status_since must be YYYY-MM-DD.',
      });
    }
    if (diff.added.has(relPath) && relPath.endsWith('-decisions.md')) {
      findings.push({
        ruleId: 'R-B4',
        severity: SEVERITY.BLOCK,
        file: relPath,
        message: 'Do not add new *-decisions.md under changes/ — use canonical Decision log.',
      });
    }

    if (!inBaseline || scopeAll) {
      const sinceRaw = formatStatusSince(meta.status_since);
    const since = /^\d{4}-\d{2}-\d{2}$/.test(sinceRaw) ? new Date(`${sinceRaw}T00:00:00Z`) : null;
      const days = since ? (clock - since) / (86400000) : 0;
      if (String(meta.status || '').toLowerCase() === 'proposed' && days > 30) {
        findings.push({
          ruleId: 'R-B5',
          severity: scopeAll ? SEVERITY.REPORT : SEVERITY.WARN,
          file: relPath,
          message: 'Proposal older than 30 days — fold or refresh status_since.',
        });
      }
    }
  }
  return findings;
}

module.exports = { runGateChanges };
