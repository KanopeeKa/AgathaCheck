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

function resolveDiffBaseRef() {
  const raw = process.env.MIGRATION_LINT_BASE || process.env.GITHUB_BASE_REF || 'main';
  return raw.startsWith('origin/') ? raw : `origin/${raw}`;
}

function changedMigrationSqlFiles() {
  const base = resolveDiffBaseRef();
  let out = '';
  let errText = '';
  try {
    out = execSync(`git diff --name-only ${base}...HEAD -- db/migrations/`, {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
  } catch (err) {
    errText = err.stderr?.toString() || err.message || String(err);
    console.error(
      `check_migration_sql_transactions: git diff ${base}...HEAD failed: ${errText.trim()}`,
    );
    console.error(`Fetch the PR base (e.g. git fetch origin ${base.replace(/^origin\//, '')}) and retry.`);
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
