#!/usr/bin/env node
/**
 * Fail CI when incremental db/migrations/*.sql files contain top-level BEGIN/COMMIT.
 * Only files changed vs origin/main are checked (grandfather existing SQL).
 */
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const migrationsDir = path.join(repoRoot, 'db/migrations');

function changedMigrationSqlFiles() {
  let out = '';
  try {
    out = execSync('git diff --name-only origin/main...HEAD -- db/migrations/', {
      cwd: repoRoot,
      encoding: 'utf8',
    });
  } catch {
    return [];
  }
  return out
    .split('\n')
    .map((l) => l.trim())
    .filter((f) => /^\d{3}_.+\.sql$/.test(path.basename(f)) && !f.includes('_down'));
}

function violationsInFile(absPath) {
  const text = fs.readFileSync(absPath, 'utf8');
  const bad = [];
  for (const [i, line] of text.split('\n').entries()) {
    const trimmed = line.trim();
    if (/^BEGIN;?\s*(--.*)?$/i.test(trimmed)) bad.push(`line ${i + 1}: BEGIN`);
    if (/^COMMIT;?\s*(--.*)?$/i.test(trimmed)) bad.push(`line ${i + 1}: COMMIT`);
  }
  return bad;
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
    'Incremental migrations must not BEGIN/COMMIT; the Node runner owns the outer transaction.',
  );
  process.exit(1);
}
