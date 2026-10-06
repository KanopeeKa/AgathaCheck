'use strict';

const fs = require('fs');
const path = require('path');

const GENERATED_DART = /\.(g\.dart|mocks\.dart|freezed\.dart)$/;
const L10N_GEN = /l10n\/app_localizations.*\.dart$/;

function rel(root, filePath) {
  return path.relative(root, filePath).split(path.sep).join('/');
}

function walkMarkdown(dir, visitor) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walkMarkdown(full, visitor);
    else if (entry.isFile() && entry.name.endsWith('.md')) visitor(full);
  }
}

function listFeatureDocs(root) {
  const docs = [];
  const domains = path.join(root, 'docs/domains');
  if (!fs.existsSync(domains)) return docs;
  for (const domain of fs.readdirSync(domains, { withFileTypes: true })) {
    if (!domain.isDirectory()) continue;
    const featDir = path.join(domains, domain.name, 'features');
    walkMarkdown(featDir, (f) => docs.push(f));
  }
  return docs;
}

function listChangeDocs(root) {
  const docs = [];
  const domains = path.join(root, 'docs/domains');
  if (!fs.existsSync(domains)) return docs;
  for (const domain of fs.readdirSync(domains, { withFileTypes: true })) {
    if (!domain.isDirectory()) continue;
    const chDir = path.join(domains, domain.name, 'changes');
    walkMarkdown(chDir, (f) => docs.push(f));
  }
  return docs;
}

function isPolicyDoc(relPath) {
  const { POLICY_DOC_GLOBS } = require('./constants');
  return POLICY_DOC_GLOBS.some((re) => re.test(relPath));
}

function isBehaviourPath(relPath) {
  if (
    relPath.startsWith('flutter_app/test/') ||
    relPath.startsWith('server/test/') ||
    relPath.startsWith('e2e/') ||
    relPath.startsWith('scripts/') ||
    relPath.startsWith('.cursor/') ||
    relPath.startsWith('.github/') ||
    relPath.startsWith('docs/')
  ) {
    return false;
  }
  if (relPath.startsWith('flutter_app/lib/l10n/') && relPath.endsWith('.arb')) {
    return true;
  }
  if (relPath.startsWith('flutter_app/lib/')) {
    if (GENERATED_DART.test(relPath) || L10N_GEN.test(relPath)) return false;
    return true;
  }
  if (
    relPath.startsWith('server/routes/') ||
    relPath.startsWith('server/lib/') ||
    relPath.startsWith('server/migrations/') ||
    relPath.startsWith('server/bin/')
  ) {
    return true;
  }
  return false;
}

function domainFromFeaturePath(relPath) {
  const m = relPath.match(/^docs\/domains\/([^/]+)\//);
  return m ? m[1] : null;
}

module.exports = {
  rel,
  walkMarkdown,
  listFeatureDocs,
  listChangeDocs,
  isPolicyDoc,
  isBehaviourPath,
  domainFromFeaturePath,
};
