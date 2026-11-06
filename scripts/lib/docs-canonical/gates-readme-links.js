'use strict';

const fs = require('fs');
const path = require('path');
const { SEVERITY } = require('./constants');
const { rel, listChangeDocs } = require('./paths');
const { fileAtRef, workingTreeFile } = require('./diff');

const CHANGE_LINK_RE = /(?:\]\(|^|\s)(?:docs\/domains\/[^/]+\/)?changes\/([^\s)\]|#]+\.md)/gi;

function extractChangeLinks(text) {
  const links = new Set();
  if (!text) return links;
  let m;
  while ((m = CHANGE_LINK_RE.exec(text)) !== null) {
    links.add(`changes/${m[1].replace(/^\//, '')}`);
  }
  CHANGE_LINK_RE.lastIndex = 0;
  return links;
}

function domainFromReadmeRel(relPath) {
  const parts = relPath.split('/');
  return parts.length >= 3 ? parts[2] : null;
}

function changeDocRel(domain, suffix) {
  return `docs/domains/${domain}/changes/${suffix}`;
}

function runGateReadmeLinks(ctx) {
  const findings = [];
  const { root, diff, baseRef, scopeAll } = ctx;

  for (const relPath of diff.modified) {
    if (!relPath.endsWith('/README.md') || !relPath.startsWith('docs/domains/')) continue;
    const domain = domainFromReadmeRel(relPath);
    if (!domain) continue;
    const baseText = fileAtRef(root, baseRef, relPath);
    const headText = workingTreeFile(root, relPath);
    const removed = [...extractChangeLinks(baseText)].filter(
      (link) => !extractChangeLinks(headText).has(link),
    );
    for (const suffix of removed) {
      const fullRel = changeDocRel(domain, path.basename(suffix));
      if (fs.existsSync(path.join(root, fullRel))) {
        findings.push({
          ruleId: 'R-B6',
          severity: SEVERITY.BLOCK,
          file: relPath,
          message: `Removed README link to orphaned change doc ${fullRel} — restore the link or delete the change doc.`,
        });
      }
    }
  }

  if (scopeAll) {
    for (const filePath of listChangeDocs(root)) {
      const relPath = rel(root, filePath);
      if (relPath.includes('/changes/archive/')) continue;
      const domain = domainFromReadmeRel(relPath.replace(/\/changes\/.*$/, '/README.md'));
      const domainDir = path.dirname(path.dirname(filePath));
      const readmePath = path.join(domainDir, 'README.md');
      if (!fs.existsSync(readmePath)) continue;
      const readmeText = fs.readFileSync(readmePath, 'utf8');
      const name = path.basename(relPath);
      const linked =
        readmeText.includes(name) ||
        readmeText.includes(relPath) ||
        readmeText.includes(`changes/${name}`);
      if (!linked) {
        findings.push({
          ruleId: 'R-B6',
          severity: SEVERITY.REPORT,
          file: relPath,
          message: `Change doc is not linked from domain README (${rel(root, readmePath)}).`,
        });
      }
    }
  }

  return findings;
}

module.exports = { runGateReadmeLinks, extractChangeLinks };
