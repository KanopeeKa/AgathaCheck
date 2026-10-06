'use strict';

const path = require('path');
const { SEVERITY } = require('./constants');
const { rel, isPolicyDoc } = require('./paths');
const { isBaselineFeature } = require('./baseline');
const {
  parseCanonicalDoc,
  REQ_HEADER,
  AC_HEADER,
  DEC_HEADER,
  reqStatusOk,
  decisionStatusOk,
} = require('./parse');
const { touchedInDiff } = require('./diff');

const PHASE_CELL = /^(Phase\s+)?[A-Z]{1,6}-?\d{1,2}[a-z]?$/i;
const STATUS_CELL = /^(Shipped|Merged|Done|Completed?|Landed|In progress|Pending)$/i;
const BANNED_HEADINGS = [
  /^## Phasing\s*$/im,
  /^## Delivery status\s*$/im,
  /^## Delivery plan\s*$/im,
  /^## Mockup corrections\s*$/im,
  /^## Change history\s*$/im,
  /^## Changelog\s*$/im,
  /^## Sprint .+$/im,
  /^### Phasing\s*$/im,
];
const AMEND_BANNER = /\bamended\s+\d{4}-\d{2}-\d{2}\b/i;

function deliveryNoiseInBody(body, prefix) {
  const findings = [];
  const idLike = new RegExp(`^${prefix}-R-\\d{3}$`, 'i');

  const reqSec = body.match(/^## Requirements\s*$([\s\S]*?)(?=^## |\Z)/im);
  const decSec = body.match(/^## Decision log\s*$([\s\S]*?)(?=^## |\Z)/im);
  let scanBody = body;
  if (reqSec) scanBody = scanBody.replace(reqSec[0], '');
  if (decSec) scanBody = scanBody.replace(decSec[0], '');

  for (const re of BANNED_HEADINGS) {
    if (re.test(scanBody)) {
      findings.push('banned heading');
    }
  }
  if (/^\*\*Delivery status:\*\*/im.test(scanBody)) findings.push('delivery status banner');
  if (AMEND_BANNER.test(scanBody.split('\n').filter((l) => !l.trim().startsWith('|')).join('\n'))) {
    findings.push('amended banner');
  }

  const lines = scanBody.split('\n');
  for (const line of lines) {
    if (!line.trim().startsWith('|')) continue;
    if (line.includes('Given / When / Then')) continue;
    const cells = line.split('|').slice(1, -1).map((c) => c.trim());
    if (cells.length < 2) continue;
    const hasPhase = cells.some((c) => PHASE_CELL.test(c) && !idLike.test(c));
    const hasShip = cells.some((c) => STATUS_CELL.test(c));
    if (hasPhase && hasShip) findings.push(`phase row: ${line.trim()}`);
  }
  return findings;
}

function runShapeOnFile(root, filePath, ctx) {
  const findings = [];
  const relPath = rel(root, filePath);
  if (isPolicyDoc(relPath)) return findings;
  if (isBaselineFeature(ctx.baseline, relPath)) {
    if (touchedInDiff(ctx.diff, relPath)) {
      const { body } = parseCanonicalDoc(filePath, root);
      const noise = deliveryNoiseInBody(body, ctx.prefix || 'X');
      if (noise.length) {
        findings.push({
          ruleId: 'R-C6a',
          severity: SEVERITY.WARN,
          file: relPath,
          message: 'Delivery noise in baseline doc — clean up when syncing (see standards §Feature doc rules).',
        });
      }
    }
    return findings;
  }

  const doc = parseCanonicalDoc(filePath, root);
  ctx.prefix = doc.prefix;

  if (!doc.reqSec || !doc.acSec || !doc.decSec) {
    findings.push({
      ruleId: 'R-C1',
      severity: SEVERITY.BLOCK,
      file: relPath,
      message: 'Missing required H2: Requirements, Acceptance criteria, and/or Decision log.',
    });
  }

  if (doc.requirements && doc.requirements.header !== REQ_HEADER) {
    findings.push({
      ruleId: 'R-C2',
      severity: SEVERITY.BLOCK,
      file: relPath,
      line: doc.reqSec ? doc.reqSec.line + doc.requirements.headerLine : 1,
      message: `Requirements table header must be exactly: ${REQ_HEADER}`,
    });
  }
  if (doc.acceptance && doc.acceptance.header !== AC_HEADER) {
    findings.push({
      ruleId: 'R-C2',
      severity: SEVERITY.BLOCK,
      file: relPath,
      line: doc.acSec ? doc.acSec.line + doc.acceptance.headerLine : 1,
      message: `Acceptance criteria header must be exactly: ${AC_HEADER}`,
    });
  }
  if (doc.decisions && doc.decisions.header !== DEC_HEADER) {
    findings.push({
      ruleId: 'R-C2',
      severity: SEVERITY.BLOCK,
      file: relPath,
      line: doc.decSec ? doc.decSec.line + doc.decisions.headerLine : 1,
      message: `Decision log header must be exactly: ${DEC_HEADER}`,
    });
  }

  const reqIds = new Set();
  if (doc.requirements) {
    for (const row of doc.requirements.rows) {
      const [id, , status] = row.cells;
      const expected = new RegExp(`^${doc.prefix}-R-\\d{3}$`);
      if (!expected.test(id)) {
        findings.push({
          ruleId: 'R-C3',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message: `Requirement ID must match ^${doc.prefix}-R-###$ (from feature_id).`,
        });
      }
      if (reqIds.has(id)) {
        findings.push({
          ruleId: 'R-C3',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message: `Duplicate requirement ID ${id}.`,
        });
      }
      reqIds.add(id);
      if (!reqStatusOk(status)) {
        findings.push({
          ruleId: 'R-C4',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message: 'Requirement Status must be Live, In delivery, Planned, or Retired.',
        });
      }
    }
  }

  if (doc.decisions) {
    for (const row of doc.decisions.rows) {
      const [id, , , status] = row.cells;
      const ok =
        new RegExp(`^${doc.prefix}-D-\\d{3}$`).test(id) ||
        /^D-[A-Z]+-\d{3}$/.test(id) ||
        /^[A-Z]+-D\d+$/.test(id);
      if (!ok) {
        findings.push({
          ruleId: 'R-C7',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message: 'Decision ID must match PREFIX-D-### or legacy D-* pattern.',
        });
      }
      if (!decisionStatusOk(status)) {
        findings.push({
          ruleId: 'R-C4',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message: 'Decision Status must be Live or Superseded by <ID> (legacy Agreed → Live on consolidate).',
        });
      }
    }
  }

  if (doc.acceptance) {
    for (const row of doc.acceptance.rows) {
      const [, reqCell] = row.cells;
      const ids = String(reqCell || '')
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      for (const id of ids) {
        if (!reqIds.has(id)) {
          findings.push({
            ruleId: 'R-C5',
            severity: SEVERITY.BLOCK,
            file: relPath,
            line: row.lineNum,
            message: `AC cites unknown requirement ID ${id}.`,
          });
        }
      }
    }
  }

  const noise = deliveryNoiseInBody(doc.body, doc.prefix);
  if (noise.length) {
    findings.push({
      ruleId: 'R-C6',
      severity: SEVERITY.BLOCK,
      file: relPath,
      message: 'Delivery noise detected (phase/shipped tables, banned headings, amendment banners).',
    });
  }

  return findings;
}

function docPassesGateC(root, filePath, baseline) {
  const ctx = { baseline, diff: { added: new Set(), modified: new Set(), deleted: new Set() } };
  return runShapeOnFile(root, filePath, ctx).length === 0;
}

function runGateShape(ctx) {
  const findings = [];
  const { root, diff, baseline, scopeAll } = ctx;
  const { listFeatureDocs } = require('./paths');
  for (const filePath of listFeatureDocs(root)) {
    const relPath = rel(root, filePath);
    if (!scopeAll && !touchedInDiff(diff, relPath)) continue;
    findings.push(...runShapeOnFile(root, filePath, { ...ctx, baseline, diff }));
  }
  return findings;
}

module.exports = { runGateShape, runShapeOnFile, docPassesGateC, deliveryNoiseInBody };
