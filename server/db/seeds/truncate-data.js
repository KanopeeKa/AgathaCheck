#!/usr/bin/env node
/**
 * Truncate all application data while preserving schema and migration ledger.
 * Non-production only — use before re-seeding UAT/demo databases.
 */
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';
import { assertNonProduction } from '../../scripts/lib/guard-non-prod.js';

const { Pool } = pg;
const __dirname = path.dirname(fileURLToPath(import.meta.url));

dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config();

const TABLES_TO_TRUNCATE = [
  'adoption_visits',
  'adoption_journeys',
  'foster_request_responses',
  'foster_request_targets',
  'foster_request_pets',
  'foster_requests',
  'foster_placements',
  'custody_transfers',
  'health_event_photos',
  'health_history',
  'health_issue_documents',
  'health_issue_events',
  'health_issues',
  'health_entries',
  'weight_entries',
  'pet_timeline_entries',
  'pet_activity_events',
  'family_event_history',
  'family_events',
  'notifications',
  'notification_preferences',
  'pet_access',
  'shared_pets',
  'pet_share_links',
  'org_pet_home_hidden',
  'organization_permissions',
  'document_templates',
  'org_connection_requests',
  'org_connections',
  'org_foster_parents',
  'foster_profiles',
  'prospects',
  'archived_pets',
  'audit_events',
  'password_reset_tokens',
  'refresh_tokens',
  'vets',
  'pets',
  'organization_users',
  'organizations',
  'users',
];

function createPool() {
  const databaseUrl = process.env.DATABASE_URL;
  if (databaseUrl) {
    return new Pool({ connectionString: databaseUrl });
  }
  return new Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: process.env.PGPORT || 5432,
    database: process.env.PGDATABASE || 'agatha_db',
  });
}

export async function truncateDemoData(pool) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const tableList = TABLES_TO_TRUNCATE.map((t) => `public.${t}`).join(', ');
    await client.query(`TRUNCATE TABLE ${tableList} RESTART IDENTITY CASCADE`);
    await client.query('COMMIT');
    console.log(`truncate: cleared ${TABLES_TO_TRUNCATE.length} application tables`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function main() {
  assertNonProduction('truncate demo data');
  const pool = createPool();
  try {
    await truncateDemoData(pool);
  } finally {
    await pool.end();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(`truncate ERROR: ${err.message}`);
    process.exit(1);
  });
}
