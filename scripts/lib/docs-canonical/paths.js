'use strict';

const path = require('path');
const {
  BEHAVIOUR_PREFIXES,
  BEHAVIOUR_EXCLUDE_PREFIXES,
  GENERATED_SUFFIXES,
} = require('./constants');

function normalizeRepoPath(p) {
  return p.replace(/\\/g, '/');
}

function isGeneratedDart(rel) {
  return GENERATED_SUFFIXES.some((s) => rel.endsWith(s));
}

function isBehaviourPath(rel) {
  const p = normalizeRepoPath(rel);
  for (const ex of BEHAVIOUR_EXCLUDE_PREFIXES) {
    if (p.startsWith(ex)) {
      return false;
    }
  }
  if (p.startsWith('flutter_app/lib/')) {
    if (isGeneratedDart(p)) {
      return false;
    }
    return true;
  }
  if (p.startsWith('flutter_app/lib/l10n/') && p.endsWith('.arb')) {
    return true;
  }
  for (const prefix of BEHAVIOUR_PREFIXES) {
    if (prefix === 'flutter_app/lib/' || prefix === 'flutter_app/lib/l10n/') {
      continue;
    }
    if (p.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

function behaviourPathsInList(files) {
  return files.filter(isBehaviourPath);
}

function docsSectionPaths(body) {
  const paths = new Set();
  const section = body.match(/^## Docs\s*\n([\s\S]*?)(?=^## |\s*$)/im);
  if (!section) {
    return { hasSection: false, paths, na: false, naReason: '' };
  }
  const block = section[1];
  let na = false;
  let naReason = '';
  const naMatch = block.match(/N\/A\s*—\s*(.+)/i);
  if (naMatch) {
    na = true;
    naReason = naMatch[1].trim();
  }
  const pathRe = /docs\/domains\/[^\s`),]+\.md/g;
  for (const m of block.matchAll(pathRe)) {
    paths.add(m[0].replace(/^\.\//, ''));
  }
  return { hasSection: true, paths, na, naReason };
}

function isCanonicalFeatureDoc(rel) {
  const p = normalizeRepoPath(rel);
  return /^docs\/domains\/[^/]+\/features\/[^/]+\.md$/.test(p);
}

function isChangeDoc(rel) {
  const p = normalizeRepoPath(rel);
  return /^docs\/domains\/[^/]+\/changes\/.+\.md$/.test(p);
}

function domainFromDocPath(rel) {
  const m = normalizeRepoPath(rel).match(/^docs\/domains\/([^/]+)\//);
  return m ? m[1] : null;
}

function featureIdPrefix(featureId) {
  return String(featureId || '')
    .trim()
    .replace(/_/g, '-')
    .toUpperCase();
}

module.exports = {
  normalizeRepoPath,
  isBehaviourPath,
  behaviourPathsInList,
  docsSectionPaths,
  isCanonicalFeatureDoc,
  isChangeDoc,
  domainFromDocPath,
  featureIdPrefix,
};
