'use strict';

const fs = require('fs');
const path = require('path');

function baselinePath(root) {
  return path.join(root, 'scripts/docs-legacy-baseline.json');
}

function loadBaseline(root) {
  const file = baselinePath(root);
  if (!fs.existsSync(file)) {
    return { version: 1, features: [], changes: [] };
  }
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  const features = new Set((data.features || []).map((p) => p.replace(/\\/g, '/')));
  const changes = new Set((data.changes || []).map((p) => p.replace(/\\/g, '/')));
  return { version: data.version || 1, features, changes, raw: data };
}

function isBaselineFeature(rel, baseline) {
  return baseline.features.has(rel.replace(/\\/g, '/'));
}

function isBaselineChange(rel, baseline) {
  return baseline.changes.has(rel.replace(/\\/g, '/'));
}

function checkBaselineFileDiff(diffFiles, baselineAtBase, root, headBaseline) {
  const findings = [];
  const relBaseline = path.relative(root, baselinePath(root)).replace(/\\/g, '/');
  if (!diffFiles.includes(relBaseline)) {
    return findings;
  }
  const onDisk = headBaseline || loadBaseline(root);
  const committed = baselineAtBase;
  for (const p of onDisk.features) {
    if (!committed.features.has(p)) {
      findings.push({
        ruleId: 'R-L1',
        severity: 'BLOCK',
        message: `New baseline feature entry: ${p}`,
        file: relBaseline,
      });
    }
  }
  for (const p of committed.features) {
    if (!onDisk.features.has(p)) {
      findings.push({
        ruleId: 'R-L2',
        severity: 'BLOCK',
        message: `Removed baseline feature entry (stale?): ${p}`,
        file: relBaseline,
      });
    }
  }
  for (const p of onDisk.changes) {
    if (!committed.changes.has(p)) {
      findings.push({
        ruleId: 'R-L1',
        severity: 'BLOCK',
        message: `New baseline change entry: ${p}`,
        file: relBaseline,
      });
    }
  }
  for (const p of committed.changes) {
    if (!onDisk.changes.has(p)) {
      findings.push({
        ruleId: 'R-L2',
        severity: 'BLOCK',
        message: `Removed baseline change entry (stale?): ${p}`,
        file: relBaseline,
      });
    }
  }
  return findings;
}

module.exports = {
  baselinePath,
  loadBaseline,
  isBaselineFeature,
  isBaselineChange,
  checkBaselineFileDiff,
};
