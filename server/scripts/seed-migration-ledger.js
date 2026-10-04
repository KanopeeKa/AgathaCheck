#!/usr/bin/env node
/**
 * Pre-seed _migrations from migration-manifest.json after canonical bootstrap.
 * Fresh installs only — production deploy also auto-seeds via migrate.js when needed.
 */
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { createAppPool } from '../lib/db/createPool.js';
import {
  loadManifest,
  resolveManifestPath,
  seedMigrationLedger,
} from './lib/migration-ledger.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

function createPool() {
  return createAppPool();
}

async function main() {
  const manifestPath = resolveManifestPath();
  const manifestMigrations = loadManifest(manifestPath);
  const pool = createPool();
  try {
    const inserted = await seedMigrationLedger(pool, manifestMigrations);
    if (inserted === 0) {
      console.log('migration-ledger: all manifest migrations already recorded');
    } else {
      console.log(`migration-ledger: recorded ${inserted} migration(s) in _migrations`);
    }
  } finally {
    await pool.end();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(`migration-ledger ERROR: ${err.message}`);
    process.exit(1);
  });
}
