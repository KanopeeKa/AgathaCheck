#!/usr/bin/env node
/**
 * Ensure every Playwright spec (except allowlist) appears in shard-files.mjs.
 *
 * Usage:
 *   node e2e/scripts/validate-shard-manifest.mjs           # enforce (exit 1 on orphan)
 *   node e2e/scripts/validate-shard-manifest.mjs --report-only
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { SHARDS } from './shard-files.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TESTS_DIR = path.join(__dirname, '..', 'playwright', 'tests');

/** Specs intentionally excluded from Pre-UAT localhost shards. */
const ALLOWLIST = new Set(['uat-auth-warmup.spec.ts']);

const reportOnly = process.argv.includes('--report-only');

const manifestFiles = new Set(
  SHARDS.flat().map((rel) => path.basename(rel)),
);

const diskFiles = fs
  .readdirSync(TESTS_DIR)
  .filter((f) => f.endsWith('.spec.ts'));

const orphans = diskFiles.filter((f) => !manifestFiles.has(f) && !ALLOWLIST.has(f));
const missingOnDisk = [...manifestFiles].filter(
  (f) => !diskFiles.includes(f),
);

console.log(`Shard manifest: ${manifestFiles.size} files across ${SHARDS.length} shards`);
console.log(`Disk specs: ${diskFiles.length} (allowlist: ${ALLOWLIST.size})`);

if (orphans.length > 0) {
  console.log(`\nOrphan specs (not in shard-files.mjs): ${orphans.length}`);
  for (const f of orphans.sort()) console.log(`  - ${f}`);
}

if (missingOnDisk.length > 0) {
  console.log(`\nManifest entries missing on disk: ${missingOnDisk.length}`);
  for (const f of missingOnDisk.sort()) console.log(`  - ${f}`);
}

if (!reportOnly && (orphans.length > 0 || missingOnDisk.length > 0)) {
  console.error('\n::error::Playwright shard manifest is out of sync with spec files');
  process.exit(1);
}

console.log('\nvalidate-shard-manifest: OK');
