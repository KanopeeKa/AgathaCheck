/**
 * Active server production files for lint/size/coverage gates (manifest-aware).
 * Shared by validate_eslint.js and check_file_size.js.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const ACTIVE_SERVER_ROOTS = ['server/lib', 'server/services', 'server/routes'];

function underPrefix(rel, prefix) {
  const p = prefix.replace(/\\/g, '/').replace(/\/$/, '');
  return rel === p || rel.startsWith(`${p}/`);
}

function expandFrozenServerRoots(roots) {
  const expanded = [];
  for (const root of roots) {
    const r = root.replace(/\\/g, '/').replace(/\/$/, '');
    expanded.push(r);
    if (!r.endsWith('.js') && !r.endsWith('.mjs')) {
      expanded.push(`${r}.js`);
    }
  }
  return expanded;
}

function loadManifest(repoRoot) {
  const manifestPath = path.join(repoRoot, 'docs/engineering/frozen-domains/manifest.json');
  if (!fs.existsSync(manifestPath)) return { serverRoots: [] };
  return JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
}

function isFrozenServerFile(rel, frozenRoots) {
  return frozenRoots.some((root) => underPrefix(rel, root));
}

function listActiveServerFiles(repoRoot) {
  const manifest = loadManifest(repoRoot);
  const frozen = expandFrozenServerRoots(manifest.serverRoots || []);
  const files = [];

  for (const base of ACTIVE_SERVER_ROOTS) {
    const absBase = path.join(repoRoot, base);
    if (!fs.existsSync(absBase)) continue;
    walk(absBase, base);
  }

  return files.sort();

  function walk(absDir, relDir) {
    for (const entry of fs.readdirSync(absDir, { withFileTypes: true })) {
      const rel = path.posix.join(relDir, entry.name);
      if (entry.isDirectory()) {
        walk(path.join(absDir, entry.name), rel);
        continue;
      }
      if (!entry.isFile()) continue;
      if (!/\.(js|mjs)$/.test(entry.name)) continue;
      if (isFrozenServerFile(rel, frozen)) continue;
      files.push(rel);
    }
  }
}

module.exports = {
  ACTIVE_SERVER_ROOTS,
  expandFrozenServerRoots,
  isFrozenServerFile,
  listActiveServerFiles,
  loadManifest,
};
