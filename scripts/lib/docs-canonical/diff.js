'use strict';

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function runGit(root, args) {
  try {
    return execSync(`git ${args.join(' ')}`, {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();
  } catch (e) {
    return '';
  }
}

function resolveBase(root, baseRef) {
  if (!baseRef) return 'HEAD';
  const ok = runGit(root, ['rev-parse', '--verify', baseRef]);
  return ok || 'HEAD';
}

function diffNameStatus(root, baseRef) {
  const base = resolveBase(root, baseRef);
  const out = runGit(root, ['diff', '-M', '--name-status', `${base}...HEAD`]);
  if (!out) {
    const out2 = runGit(root, ['diff', '-M', '--name-status', base]);
    return parseNameStatus(out2);
  }
  return parseNameStatus(out);
}

function parseNameStatus(text) {
  const added = new Set();
  const modified = new Set();
  const deleted = new Set();
  const renames = [];
  for (const line of text.split('\n').filter(Boolean)) {
    const parts = line.split('\t');
    const status = parts[0];
    if (status.startsWith('R')) {
      renames.push({ from: parts[1], to: parts[2] });
      deleted.add(parts[1]);
      added.add(parts[2]);
      modified.add(parts[2]);
    } else if (status === 'A') added.add(parts[1]);
    else if (status === 'M') modified.add(parts[1]);
    else if (status === 'D') deleted.add(parts[1]);
  }
  return { added, modified, deleted, renames };
}

function fileAtRef(root, ref, relPath) {
  const base = resolveBase(root, ref);
  try {
    return execSync(`git show ${base}:${relPath}`, {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch {
    return null;
  }
}

function workingTreeFile(root, relPath) {
  const full = path.join(root, relPath);
  if (!fs.existsSync(full)) return null;
  return fs.readFileSync(full, 'utf8');
}

function touchedInDiff(diff, relPath) {
  return diff.added.has(relPath) || diff.modified.has(relPath) || diff.deleted.has(relPath);
}

function allChangedPaths(diff) {
  return new Set([...diff.added, ...diff.modified, ...diff.deleted]);
}

module.exports = {
  runGit,
  resolveBase,
  diffNameStatus,
  fileAtRef,
  workingTreeFile,
  touchedInDiff,
  allChangedPaths,
};
