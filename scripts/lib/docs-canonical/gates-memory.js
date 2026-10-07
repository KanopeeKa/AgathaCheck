'use strict';

const fs = require('fs');
const path = require('path');
const { SEVERITY, LEGACY_DECISION_PREFIXES } = require('./constants');
const { fileAtRef } = require('./diff');

const MEMORY_DIR = '.agents/memory/';
const BACKLOG_PATH = 'scripts/docs-memory-backlog.json';

// A memory file that cites a requirement/decision ID is almost certainly carrying a
// product rule (D-CSM-019, CARE-ITEM-R-014, NAV-D1, …), not an agent lesson.
const ID_RE = new RegExp(
  `\\b(?:D-[A-Z]+-\\d{3}|[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-[RD]-\\d{3}|(?:${LEGACY_DECISION_PREFIXES.join('|')})-D\\d+)\\b`,
);
const MEMORY_REF_RE = /\.agents\/memory\/[\w./-]+/g;

function isMemoryFile(relPath) {
  return relPath.startsWith(MEMORY_DIR) && relPath.endsWith('.md') && !relPath.endsWith('/MEMORY.md');
}

function memoryRefs(text) {
  return new Set((text || '').match(MEMORY_REF_RE) || []);
}

function loadBacklog(root) {
  const full = path.join(root, BACKLOG_PATH);
  if (!fs.existsSync(full)) return [];
  return JSON.parse(fs.readFileSync(full, 'utf8')).entries || [];
}

/**
 * Memory guards (all non-blocking):
 *  R-M1 WARN   memory file added/modified that cites decision/requirement IDs
 *  R-M2 WARN   canonical doc gains a `.agents/memory/` reference
 *  R-M3 WARN   backlog entry points at a missing memory file (remove it)
 *  R-M4 REPORT (--all) backlog entries still waiting to move into a canonical doc
 *  R-M1 REPORT (--all) every memory file citing IDs
 */
function runGateMemory(ctx) {
  const { root, diff, baseRef, scopeAll } = ctx;
  const findings = [];

  const memoryCandidates = scopeAll
    ? fs
        .readdirSync(path.join(root, MEMORY_DIR), { withFileTypes: true })
        .filter((e) => e.isFile())
        .map((e) => `${MEMORY_DIR}${e.name}`)
    : [...diff.added, ...diff.modified];
  for (const relPath of memoryCandidates) {
    if (!isMemoryFile(relPath) || !fs.existsSync(path.join(root, relPath))) continue;
    const text = fs.readFileSync(path.join(root, relPath), 'utf8');
    const hit = text.match(ID_RE);
    if (hit) {
      findings.push({
        ruleId: 'R-M1',
        severity: scopeAll ? SEVERITY.REPORT : SEVERITY.WARN,
        file: relPath,
        message: `Memory file cites ${hit[0]} — memory holds agent lessons only. Move the product rule into its canonical doc (/canonical-docs sync) and keep a pointer here.`,
      });
    }
  }

  for (const relPath of [...diff.added, ...diff.modified]) {
    if (!relPath.includes('/features/') || !relPath.endsWith('.md')) continue;
    const full = path.join(root, relPath);
    if (!fs.existsSync(full)) continue;
    const before = memoryRefs(fileAtRef(root, baseRef, relPath));
    for (const ref of memoryRefs(fs.readFileSync(full, 'utf8'))) {
      if (before.has(ref)) continue;
      findings.push({
        ruleId: 'R-M2',
        severity: SEVERITY.WARN,
        file: relPath,
        message: `Canonical doc now points to ${ref} as a source. The rule itself must live in this doc; memory may only be linked as an agent lesson.`,
      });
    }
  }

  for (const entry of loadBacklog(root)) {
    if (!fs.existsSync(path.join(root, entry.file))) {
      findings.push({
        ruleId: 'R-M3',
        severity: SEVERITY.WARN,
        file: BACKLOG_PATH,
        message: `Backlog entry ${entry.file} no longer exists — remove it from ${BACKLOG_PATH}.`,
      });
    } else if (scopeAll) {
      findings.push({
        ruleId: 'R-M4',
        severity: SEVERITY.REPORT,
        file: entry.file,
        message: `Product rule still in memory — move into ${entry.target} (${entry.capability}).`,
      });
    }
  }
  return findings;
}

module.exports = { runGateMemory, BACKLOG_PATH };
