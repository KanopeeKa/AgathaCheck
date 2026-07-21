#!/usr/bin/env node
/**
 * Verify db/schema/migration-manifest.json matches db/migrations/ on disk.
 * Phase 1 validation — run locally and in governance CI.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const MANIFEST_PATH = path.join(ROOT, 'db/schema/migration-manifest.json');
const MIGRATIONS_DIR = path.join(ROOT, 'db/migrations');

function listIncrementalMigrations(dir) {
  return fs
    .readdirSync(dir)
    .filter((name) => /^\d{3}_.+\.sql$/.test(name) && !name.includes('_down'))
    .sort();
}

function fail(message) {
  console.error(`migration-manifest: ${message}`);
  process.exit(1);
}

function main() {
  if (!fs.existsSync(MANIFEST_PATH)) {
    fail(`missing manifest at ${MANIFEST_PATH}`);
  }

  const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
  const listed = manifest.incremental_migrations;
  if (!Array.isArray(listed) || listed.length === 0) {
    fail('incremental_migrations must be a non-empty array');
  }

  const onDisk = listIncrementalMigrations(MIGRATIONS_DIR);
  const listedSet = new Set(listed);
  const diskSet = new Set(onDisk);

  const missingOnDisk = listed.filter((name) => !diskSet.has(name));
  if (missingOnDisk.length > 0) {
    fail(`manifest lists files not on disk: ${missingOnDisk.join(', ')}`);
  }

  const missingInManifest = onDisk.filter((name) => !listedSet.has(name));
  if (missingInManifest.length > 0) {
    fail(
      `disk has migrations not in manifest (update migration-manifest.json): ${missingInManifest.join(', ')}`
    );
  }

  const sortedListed = [...listed].sort();
  if (listed.join('\n') !== sortedListed.join('\n')) {
    fail('incremental_migrations must be sorted lexicographically by filename');
  }

  const baselinePath = path.join(ROOT, manifest.baseline?.file ?? '');
  if (!fs.existsSync(baselinePath)) {
    fail(`baseline file missing: ${manifest.baseline?.file}`);
  }

  const canonicalPath = path.join(ROOT, manifest.canonical ?? '');
  if (!fs.existsSync(canonicalPath)) {
    fail(
      `canonical snapshot missing at ${manifest.canonical} — run scripts/db/regenerate-canonical.sh`
    );
  }

  if (Array.isArray(manifest.code_migrations)) {
    for (const name of manifest.code_migrations) {
      if (!listedSet.has(name)) {
        fail(`code_migrations entry not in incremental_migrations: ${name}`);
      }
    }
  }

  console.log(
    `migration-manifest OK (${listed.length} incremental migrations, canonical present)`
  );
}

main();
