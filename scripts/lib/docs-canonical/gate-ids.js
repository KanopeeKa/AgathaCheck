'use strict';

const path = require('path');
const { finding } = require('./findings');
const { parseFrontmatter } = require('./yaml');
const { isCanonicalFeatureDoc, normalizeRepoPath } = require('./paths');
const { readWorkingFile, readFileAtRef, runGit } = require('./git');
const { parseRequirements, parseDecisionLog } = require('./parse-md');

function gateIds(ctx) {
  const findings = [];
  const { root, base, head, diffFiles } = ctx;

  for (const rel of diffFiles) {
    if (!isCanonicalFeatureDoc(rel)) {
      continue;
    }
    const normalized = normalizeRepoPath(rel);
    const headText = readWorkingFile(root, normalized);
    const baseText = readFileAtRef(root, base, normalized);
    if (!baseText || !headText) {
      continue;
    }

    const renamed = wasRenameOnly(root, base, head, normalized);
    const baseBody = stripFm(baseText);
    const headBody = stripFm(headText);
    const baseReq = new Map(parseRequirements(baseBody).map((r) => [r.id, r]));
    const headReq = parseRequirements(headBody);
    const headIds = new Set(headReq.map((r) => r.id));

    for (const [id, row] of baseReq) {
      if (!id || headIds.has(id)) {
        continue;
      }
      if (renamed) {
        continue;
      }
      if (/retired/i.test(row.status || '')) {
        continue;
      }
      findings.push(
        finding('R-D1', 'BLOCK', `Requirement row removed: ${id}`, normalized),
      );
    }

    const baseDec = new Map(parseDecisionLog(baseBody).map((r) => [r.id, r]));
    const headDec = new Map(parseDecisionLog(headBody).map((r) => [r.id, r]));

    for (const [id, baseRow] of baseDec) {
      if (!id) {
        continue;
      }
      const headRow = headDec.get(id);
      if (!headRow) {
        if (!renamed) {
          findings.push(
            finding('R-D1', 'BLOCK', `Decision row removed: ${id}`, normalized),
          );
        }
        continue;
      }
      if (
        baseRow.rationale !== headRow.rationale &&
        baseRow.status === headRow.status &&
        !/^Superseded by /i.test(headRow.status)
      ) {
        findings.push(
          finding('R-D2', 'BLOCK', `Decision rationale edited: ${id}`, normalized),
        );
      }
    }
  }

  return findings;
}

function stripFm(text) {
  return text.replace(/^---\r?\n[\s\S]*?\r?\n---/, '');
}

function wasRenameOnly(root, base, head, pathRel) {
  try {
    const out = runGit(root, ['diff', '--name-status', '-M', base, head], { allowFail: true });
    if (!out) {
      return false;
    }
    for (const line of out.split('\n')) {
      if (line.includes(pathRel) && line.startsWith('R')) {
        return true;
      }
    }
  } catch {
    return false;
  }
  return false;
}

function findDuplicateRequirementIds(root, featurePaths) {
  const idToFiles = new Map();
  for (const rel of featurePaths) {
    const full = path.join(root, rel);
    let body;
    try {
      ({ body } = parseFrontmatter(full, root));
    } catch {
      continue;
    }
    for (const row of parseRequirements(body)) {
      if (!row.id || !/-R-\d{3}$/i.test(row.id)) {
        continue;
      }
      if (!idToFiles.has(row.id)) {
        idToFiles.set(row.id, []);
      }
      idToFiles.get(row.id).push(rel);
    }
  }
  const dups = [];
  for (const [id, files] of idToFiles) {
    if (files.length > 1) {
      dups.push({ id, files });
    }
  }
  return dups;
}

module.exports = { gateIds, findDuplicateRequirementIds };
