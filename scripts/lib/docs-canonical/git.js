'use strict';

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function runGit(root, args, opts = {}) {
  try {
    return execSync(`git ${args.join(' ')}`, {
      cwd: root,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
      ...opts,
    }).trim();
  } catch (error) {
    if (opts.allowFail) {
      return null;
    }
    throw error;
  }
}

function resolveShas(root, baseEnv, headEnv) {
  const base = baseEnv || runGit(root, ['merge-base', 'HEAD', 'origin/main'], { allowFail: true }) || 'HEAD';
  const head = headEnv || 'HEAD';
  return { base, head };
}

function diffNameOnly(root, base, head) {
  const out = runGit(root, ['diff', '--name-only', base, head], { allowFail: true });
  if (!out) {
    return [];
  }
  return out.split('\n').filter(Boolean);
}

function diffStatus(root, base, head) {
  const out = runGit(root, ['diff', '--name-status', base, head], { allowFail: true });
  if (!out) {
    return [];
  }
  return out.split('\n').filter(Boolean).map((line) => {
    const parts = line.split('\t');
    const status = parts[0];
    const file = parts[parts.length - 1];
    return { status, file };
  });
}

function readFileAtRef(root, ref, relPath) {
  try {
    return runGit(root, ['show', `${ref}:${relPath}`]);
  } catch {
    return null;
  }
}

function fileExistsAtRef(root, ref, relPath) {
  return readFileAtRef(root, ref, relPath) !== null;
}

function readWorkingFile(root, relPath) {
  const full = path.join(root, relPath);
  if (!fs.existsSync(full)) {
    return null;
  }
  return fs.readFileSync(full, 'utf8');
}

module.exports = {
  runGit,
  resolveShas,
  diffNameOnly,
  diffStatus,
  readFileAtRef,
  fileExistsAtRef,
  readWorkingFile,
};
