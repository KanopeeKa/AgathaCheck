'use strict';

const { SEVERITY } = require('./constants');
const { rel, listFeatureDocs } = require('./paths');
const { parseCanonicalDoc } = require('./parse');
const { fileAtRef, workingTreeFile, touchedInDiff } = require('./diff');

function requirementIds(doc) {
  const ids = new Set();
  if (!doc.requirements) return ids;
  for (const row of doc.requirements.rows) ids.add(row.cells[0]);
  return ids;
}

function decisionRows(doc) {
  const rows = new Map();
  if (!doc.decisions) return rows;
  for (const row of doc.decisions.rows) {
    const [id, decision, rationale, , date] = row.cells;
    rows.set(id, { decision, rationale, date });
  }
  return rows;
}

function parseDocAt(root, baseRef, relPath) {
  const text = workingTreeFile(root, relPath) ?? fileAtRef(root, baseRef, relPath);
  if (!text) return null;
  const full = require('path').join(root, relPath);
  const { parseCanonicalDoc: pc } = require('./parse');
  const tmp = require('fs').writeFileSync;
  return pc(full, root);
}

function runGateIds(ctx) {
  const findings = [];
  const { root, diff, baseRef, reportDuplicates } = ctx;
  const globalReq = new Map();
  const globalDec = new Map();

  for (const filePath of listFeatureDocs(root)) {
    const relPath = rel(root, filePath);
    const headDoc = parseCanonicalDoc(filePath, root);
    for (const id of requirementIds(headDoc)) {
      if (globalReq.has(id) && globalReq.get(id) !== relPath) {
        if (reportDuplicates) {
          findings.push({
            ruleId: 'R-D3',
            severity: SEVERITY.REPORT,
            file: relPath,
            message: `Duplicate requirement ID ${id} also in ${globalReq.get(id)}.`,
          });
        }
      } else globalReq.set(id, relPath);
    }
    for (const id of decisionRows(headDoc).keys()) {
      if (globalDec.has(id) && globalDec.get(id) !== relPath) {
        if (reportDuplicates) {
          findings.push({
            ruleId: 'R-D3',
            severity: SEVERITY.REPORT,
            file: relPath,
            message: `Duplicate decision ID ${id} also in ${globalDec.get(id)}.`,
          });
        }
      } else globalDec.set(id, relPath);
    }
  }

  if (reportDuplicates) return findings;

  for (const relPath of [...diff.modified, ...diff.added]) {
    if (!relPath.includes('/features/') || !relPath.endsWith('.md')) continue;
    const baseText = fileAtRef(root, baseRef, relPath);
    const headPath = require('path').join(root, relPath);
    if (!require('fs').existsSync(headPath)) continue;
    const headDoc = parseCanonicalDoc(headPath, root);
    let baseDoc = null;
    if (baseText) {
      const { parseCanonicalDocFromText } = require('./parse');
      baseDoc = parseCanonicalDocFromText(baseText, root);
    }
    if (!baseDoc) continue;

    const baseReq = requirementIds(baseDoc);
    const headReq = requirementIds(headDoc);
    for (const id of baseReq) {
      if (!headReq.has(id)) {
        const retired = headDoc.requirements?.rows.some(
          (r) => r.cells[0] === id && r.cells[2] === 'Retired',
        );
        if (!retired) {
          findings.push({
            ruleId: 'R-D1',
            severity: SEVERITY.BLOCK,
            file: relPath,
            message: 'Set removed requirement to Retired; never delete or reuse a requirement ID.',
          });
        }
      }
    }

    const baseDec = decisionRows(baseDoc);
    const headDec = decisionRows(headDoc);
    for (const [id, baseRow] of baseDec) {
      const headRow = headDec.get(id);
      if (!headRow) {
        findings.push({
          ruleId: 'R-D2',
          severity: SEVERITY.BLOCK,
          file: relPath,
          message: 'Decision rows must not be deleted; supersede instead.',
        });
        continue;
      }
      if (
        headRow.decision !== baseRow.decision ||
        headRow.rationale !== baseRow.rationale ||
        headRow.date !== baseRow.date
      ) {
        findings.push({
          ruleId: 'R-D2',
          severity: SEVERITY.BLOCK,
          file: relPath,
          message: 'Only Decision Status (→ Superseded) and PR may change on existing rows.',
        });
      }
    }

    for (const id of headReq) {
      if (globalReq.get(id) && globalReq.get(id) !== relPath) {
        findings.push({
          ruleId: 'R-D3',
          severity: SEVERITY.BLOCK,
          file: relPath,
          message: `Requirement ID ${id} already defined in ${globalReq.get(id)}.`,
        });
      }
    }
  }
  return findings;
}

module.exports = { runGateIds, requirementIds };
