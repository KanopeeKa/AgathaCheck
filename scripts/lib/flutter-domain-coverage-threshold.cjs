'use strict';

const fs = require('fs');
const path = require('path');

const REL_JSON =
  'docs/engineering/active-codebase-baseline/flutter-domain-coverage-threshold.json';

function jsonPath(repoRoot = path.resolve(__dirname, '..', '..')) {
  return path.join(repoRoot, REL_JSON);
}

/** Single source for the enforced Flutter domain line-coverage gate (D23 / J.1-3). */
function readThreshold(repoRoot = path.resolve(__dirname, '..', '..')) {
  const file = jsonPath(repoRoot);
  if (!fs.existsSync(file)) return 70;
  const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
  const value = Number(doc.threshold);
  return Number.isFinite(value) ? value : 70;
}

module.exports = {
  REL_JSON,
  jsonPath,
  readThreshold,
};
