'use strict';

const fs = require('fs');
const path = require('path');
const { SEVERITY } = require('./constants');
const { rel, listFeatureDocs } = require('./paths');
const { parseCanonicalDoc, parseCanonicalDocFromText } = require('./parse');
const { fileAtRef } = require('./diff');

function requirementIds(doc) {
  const ids = new Set();
  if (!doc || !doc.requirements) return ids;
  for (const row of doc.requirements.rows) ids.add(row.cells[0]);
  return ids;
}

function decisionRows(doc) {
  const rows = new Map();
  if (!doc || !doc.decisions) return rows;
  for (const row of doc.decisions.rows) {
    const [id, decision, rationale, , date] = row.cells;
    rows.set(id, { decision, rationale, date });
  }
  return rows;
}

/** id → every feature doc (repo-relative) that defines it at HEAD. */
function indexIds(root, pick) {
  const index = new Map();
  for (const filePath of listFeatureDocs(root)) {
    const relPath = rel(root, filePath);
    for (const id of pick(parseCanonicalDoc(filePath, root))) {
      if (!index.has(id)) index.set(id, []);
      index.get(id).push(relPath);
    }
  }
  return index;
}

function duplicateFindings(index, kind) {
  const findings = [];
  for (const [id, paths] of index) {
    if (paths.length < 2) continue;
    for (const file of paths) {
      findings.push({
        ruleId: 'R-D3',
        severity: SEVERITY.REPORT,
        file,
        message: `Duplicate ${kind} ID ${id} also in ${paths.filter((p) => p !== file).join(', ')}.`,
      });
    }
  }
  return findings;
}

function baseDocFor(root, baseRef, diff, relPath) {
  const rename = (diff.renames || []).find((r) => r.to === relPath);
  const text = fileAtRef(root, baseRef, rename ? rename.from : relPath);
  return text ? parseCanonicalDocFromText(text, root) : null;
}

function runGateIds(ctx) {
  const findings = [];
  const { root, diff, baseRef, reportDuplicates } = ctx;
  const reqIndex = indexIds(root, requirementIds);
  const decIndex = indexIds(root, (doc) => decisionRows(doc).keys());

  if (reportDuplicates) {
    return [...duplicateFindings(reqIndex, 'requirement'), ...duplicateFindings(decIndex, 'decision')];
  }

  for (const relPath of [...diff.modified, ...diff.added]) {
    if (!relPath.includes('/features/') || !relPath.endsWith('.md')) continue;
    const headPath = path.join(root, relPath);
    if (!fs.existsSync(headPath)) continue;
    const headDoc = parseCanonicalDoc(headPath, root);
    // A doc new to this diff has no base: nothing to compare (R-D1/R-D2), but its
    // IDs are all "introduced here" and must not collide with another doc (R-D3).
    const baseDoc = baseDocFor(root, baseRef, diff, relPath);

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

    // R-D3: an ID this diff introduces into the doc must not already live in another doc.
    for (const [ids, base, index, kind] of [
      [headReq, baseReq, reqIndex, 'Requirement'],
      [new Set(headDec.keys()), new Set(baseDec.keys()), decIndex, 'Decision'],
    ]) {
      for (const id of ids) {
        if (base.has(id)) continue;
        const others = (index.get(id) || []).filter((p) => p !== relPath);
        if (others.length) {
          findings.push({
            ruleId: 'R-D3',
            severity: SEVERITY.BLOCK,
            file: relPath,
            message: `${kind} ID ${id} already defined in ${others.join(', ')}. IDs are unique across docs; use this doc's <FEATURE_ID> prefix.`,
          });
        }
      }
    }
  }
  return findings;
}

module.exports = { runGateIds, requirementIds, decisionRows };
