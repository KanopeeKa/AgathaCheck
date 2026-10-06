'use strict';

const fs = require('fs');
const path = require('path');
const { SEVERITY } = require('./constants');
const { rel } = require('./paths');

const BASELINE_PATH = 'scripts/docs-legacy-baseline.json';

function loadBaseline(root) {
  const full = path.join(root, BASELINE_PATH);
  if (!fs.existsSync(full)) {
    return { features: new Set(), changes: new Set() };
  }
  const data = JSON.parse(fs.readFileSync(full, 'utf8'));
  return {
    features: new Set(data.features || []),
    changes: new Set(data.changes || []),
  };
}

function isBaselineFeature(baseline, relPath) {
  return baseline.features.has(relPath);
}

function isBaselineChange(baseline, relPath) {
  return baseline.changes.has(relPath);
}

function checkBaselineRatchet(root, diff, baseRef) {
  const findings = [];
  const { fileAtRef } = require('./diff');
  const baseRaw = fileAtRef(root, baseRef, BASELINE_PATH);
  const headPath = path.join(root, BASELINE_PATH);
  if (!baseRaw || !fs.existsSync(headPath)) return findings;
  let base;
  let head;
  try {
    base = JSON.parse(baseRaw);
    head = JSON.parse(fs.readFileSync(headPath, 'utf8'));
  } catch {
    return findings;
  }
  const baseFeat = new Set(base.features || []);
  const headFeat = new Set(head.features || []);
  for (const p of headFeat) {
    if (!baseFeat.has(p)) {
      findings.push({
        ruleId: 'R-L1',
        severity: SEVERITY.BLOCK,
        file: BASELINE_PATH,
        line: 1,
        message: `Do not add baseline entries; consolidate and shrink only. Remove added entry: ${p}`,
      });
    }
  }
  const baseCh = new Set(base.changes || []);
  const headCh = new Set(head.changes || []);
  for (const p of headCh) {
    if (!baseCh.has(p)) {
      findings.push({
        ruleId: 'R-L1',
        severity: SEVERITY.BLOCK,
        file: BASELINE_PATH,
        line: 1,
        message: `Do not add baseline entries; consolidate and shrink only. Remove added entry: ${p}`,
      });
    }
  }
  for (const p of [...headFeat, ...headCh]) {
    if (!fs.existsSync(path.join(root, p))) {
      findings.push({
        ruleId: 'R-L2',
        severity: SEVERITY.BLOCK,
        file: BASELINE_PATH,
        line: 1,
        message: `Remove stale baseline entry for missing file: ${p}`,
      });
    }
  }
  return findings;
}

function baselineReport(root) {
  const baseline = loadBaseline(root);
  const byDomain = {};
  for (const p of baseline.features) {
    const d = p.split('/')[2] || 'unknown';
    byDomain[d] = byDomain[d] || { features: 0, changes: 0 };
    byDomain[d].features += 1;
  }
  for (const p of baseline.changes) {
    const d = p.split('/')[2] || 'unknown';
    byDomain[d] = byDomain[d] || { features: 0, changes: 0 };
    byDomain[d].changes += 1;
  }
  return byDomain;
}

function writeBaseline(root, features, changes) {
  const out = {
    _comment:
      'Grandfathered docs. Shrink-only. Remove an entry when /canonical-docs consolidate migrates it.',
    features: [...features].sort(),
    changes: [...changes].sort(),
  };
  fs.writeFileSync(path.join(root, BASELINE_PATH), `${JSON.stringify(out, null, 2)}\n`);
}

function generateBaselineFile(root) {
  const { listFeatureDocs, listChangeDocs, rel, isPolicyDoc } = require('./paths');
  const { docPassesGateC } = require('./gates-shape');
  const emptyBaseline = { features: new Set(), changes: new Set() };
  const baseline = loadBaseline(root);
  const features = [];
  for (const f of listFeatureDocs(root)) {
    const r = rel(root, f);
    if (!isPolicyDoc(r) && !docPassesGateC(root, f, emptyBaseline)) features.push(r);
  }
  const changes = listChangeDocs(root).map((f) => rel(root, f));
  writeBaseline(root, features, changes);
  console.log(`Wrote baseline: ${features.length} features, ${changes.length} changes`);
}

module.exports = {
  BASELINE_PATH,
  loadBaseline,
  isBaselineFeature,
  isBaselineChange,
  checkBaselineRatchet,
  baselineReport,
  writeBaseline,
  generateBaselineFile,
};
