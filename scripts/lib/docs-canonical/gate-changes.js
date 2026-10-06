'use strict';

const path = require('path');
const { finding } = require('./findings');
const { parseFrontmatter } = require('./yaml');
const { isChangeDoc, normalizeRepoPath } = require('./paths');
const { isBaselineChange } = require('./baseline');
const { readWorkingFile, readFileAtRef } = require('./git');

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

function gateChanges(ctx) {
  const findings = [];
  const { root, base, head, diffFiles, baseline, clock, scanAll } = ctx;
  const now = clock ? new Date(clock) : new Date();

  const candidates = scanAll
    ? [...baseline.changes]
    : diffFiles.filter((f) => isChangeDoc(f));

  for (const rel of candidates) {
    const normalized = normalizeRepoPath(rel);
    if (normalized.includes('/changes/archive/')) {
      continue;
    }
    const inDiff = diffFiles.includes(normalized);
    const wasBaseline = isBaselineChange(normalized, baseline);
    if (!inDiff && wasBaseline && !scanAll) {
      continue;
    }

    const headText = readWorkingFile(root, normalized);
    const baseText = readFileAtRef(root, base, normalized);
    const isNew = !baseText && headText;
    const isModified = baseText && headText && baseText !== headText;

    if (!headText && !baseText) {
      continue;
    }

    if (isNew || isModified || scanAll) {
      const filePath = path.join(root, normalized);
      if (!headText) {
        continue;
      }
      let meta;
      try {
        ({ meta } = parseFrontmatter(filePath, root));
      } catch (error) {
        findings.push(
          finding('R-B3', 'BLOCK', `${normalized}: ${error.message}`, normalized),
        );
        continue;
      }

      const status = String(meta?.status || '').toLowerCase();
      const baseName = path.basename(normalized);

      if (isNew && /-decisions\.md$/i.test(baseName)) {
        findings.push(
          finding('R-B4', 'BLOCK', `New decisions-only change doc: ${normalized}`, normalized),
        );
      }

      if (isNew && status === 'completed') {
        findings.push(
          finding('R-B1', 'BLOCK', `New change doc cannot be completed: ${normalized}`, normalized),
        );
      }

      if (status === 'in-delivery' && inDiff) {
        const plan = meta?.plan || meta?.related_plan;
        const since = meta?.status_since;
        if (!plan) {
          findings.push(
            finding('R-B3', 'BLOCK', `in-delivery missing plan/related_plan: ${normalized}`, normalized),
          );
        }
        if (!since || !DATE_RE.test(String(since))) {
          findings.push(
            finding('R-B3', 'BLOCK', `in-delivery missing valid status_since: ${normalized}`, normalized),
          );
        }
      }

      if (status === 'proposed') {
        const since = meta?.status_since || meta?.last_updated;
        if (since && DATE_RE.test(String(since).slice(0, 10))) {
          const sinceDate = new Date(String(since).slice(0, 10));
          const ageDays = (now - sinceDate) / (86400 * 1000);
          if (ageDays >= 45) {
            findings.push(
              finding('R-B5', 'WARN', `Proposed change stale (${Math.floor(ageDays)}d): ${normalized}`, normalized),
            );
          }
        }
      }
    }
  }

  return findings;
}

module.exports = { gateChanges };
