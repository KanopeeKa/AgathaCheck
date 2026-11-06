#!/usr/bin/env node
/**
 * Fail when changed incremental db/migrations/*.sql files contain top-level
 * BEGIN;/COMMIT; (semicolon required). PL/pgSQL `BEGIN` inside DO $$ is allowed.
 *
 * Compare against MIGRATION_LINT_BASE or GITHUB_BASE_REF (default origin/main).
 */
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { findTopLevelSqlTransactionViolations } from '../server/scripts/lib/migration_sql.js';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function resolveDiffRange() {
  const baseSha =
    process.env.MIGRATION_LINT_BASE_SHA
    || process.env.GITHUB_EVENT_PULL_REQUEST_BASE_SHA;
  if (baseSha) {
    return `${baseSha}...HEAD`;
  }
  const raw = process.env.MIGRATION_LINT_BASE || process.env.GITHUB_BASE_REF || 'main';
  const base = raw.startsWith('origin/') ? raw : `origin/${raw}`;
  return `${base}...HEAD`;
}

function changedMigrationSqlFiles() {
  const diffRange = resolveDiffRange();
  let out = '';
  try {
    out = execSync(`git diff --name-only ${diffRange} -- db/migrations/`, {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
  } catch (err) {
    const errText = err.stderr?.toString() || err.message || String(err);
    console.error(
      `check_migration_sql_transactions: git diff ${diffRange} failed: ${errText.trim()}`,
    );
    console.error(
      'Set MIGRATION_LINT_BASE_SHA to the PR base commit, or fetch the merge base locally.',
    );
    process.exit(2);
  }
  return out
    .split('\n')
    .map((l) => l.trim())
    .filter((f) => /^\d{3}_.+\.sql$/.test(path.basename(f)) && !f.includes('_down'));
}

function violationsInFile(absPath) {
  const text = fs.readFileSync(absPath, 'utf8');
  return findTopLevelSqlTransactionViolations(text).map(
    (v) => `line ${v.line}: ${v.kind}`,
  );
}

const files = changedMigrationSqlFiles();
if (files.length === 0) {
  process.exit(0);
}

let failed = false;
for (const rel of files) {
  const abs = path.join(repoRoot, rel);
  if (!fs.existsSync(abs)) continue;
  const v = violationsInFile(abs);
  if (v.length) {
    failed = true;
    console.error(`${rel}: remove top-level transaction wrappers (${v.join(', ')})`);
  }
}

if (failed) {
  console.error(
    'Incremental migrations must not use top-level BEGIN;/COMMIT;/START TRANSACTION; — the Node runner owns the outer transaction.',
  );
  process.exit(1);
}
