'use strict';

const path = require('path');
const { finding } = require('./findings');
const { parseFrontmatter } = require('./yaml');
const { isCanonicalFeatureDoc, normalizeRepoPath } = require('./paths');
const { isBaselineFeature } = require('./baseline');
const { readWorkingFile, readFileAtRef } = require('./git');
const {
  hasDecisionLogSection,
  detectDeliveryNoise,
  parseRequirements,
  parseDecisionLog,
  validateIdPrefix,
  validateDecisionStatuses,
} = require('./parse-md');

function gateShape(ctx) {
  const findings = [];
  const { root, base, diffFiles, baseline } = ctx;

  for (const rel of diffFiles) {
    if (!isCanonicalFeatureDoc(rel)) {
      continue;
    }
    const normalized = normalizeRepoPath(rel);
    const headText = readWorkingFile(root, normalized);
    const baseText = readFileAtRef(root, base, normalized);
    const isNew = !baseText && headText;
    const isModified = Boolean(baseText && headText && baseText !== headText);
    if (!headText) {
      continue;
    }

    const filePath = path.join(root, normalized);
    let meta;
    let body;
    try {
      ({ meta, body } = parseFrontmatter(filePath, root));
    } catch (error) {
      findings.push(finding('R-B3', 'BLOCK', error.message, normalized));
      continue;
    }

    const onBaseline = isBaselineFeature(normalized, baseline);

    if ((isNew || isModified) && !onBaseline) {
      if (!hasDecisionLogSection(body)) {
        findings.push(
          finding('R-C1', 'BLOCK', 'Missing ## Decision log section', normalized),
        );
      }
    }

    if (isNew || isModified) {
      const reqRows = parseRequirements(body);
      const badIds = validateIdPrefix(meta, reqRows, 'req');
      for (const id of badIds) {
        findings.push(
          finding('R-C3', 'BLOCK', `Requirement ID prefix mismatch: ${id}`, normalized),
        );
      }

      const decRows = parseDecisionLog(body);
      const badDec = validateIdPrefix(meta, decRows, 'dec');
      for (const id of badDec) {
        if (id.includes('-D-')) {
          findings.push(
            finding('R-C3', 'BLOCK', `Decision ID prefix mismatch: ${id}`, normalized),
          );
        }
      }

      if (!onBaseline) {
        const badStatus = validateDecisionStatuses(decRows);
        for (const id of badStatus) {
          findings.push(
            finding('R-C4', 'BLOCK', `Invalid decision status for ${id}`, normalized),
          );
        }
      }

      const noise = detectDeliveryNoise(body);
      for (const issue of noise) {
        const sev = onBaseline && isModified ? 'WARN' : 'BLOCK';
        const rule = onBaseline && isModified ? 'R-C6-legacy' : 'R-C6';
        findings.push(
          finding(rule, sev, `Delivery noise (${issue.kind})`, normalized, issue.line),
        );
      }
    }
  }

  return findings;
}

module.exports = { gateShape };
