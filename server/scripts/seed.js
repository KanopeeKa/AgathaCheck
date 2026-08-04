#!/usr/bin/env node
/**
 * Idempotent UAT/demo seed data (non-production only).
 *
 * Usage:
 *   node scripts/seed.js --scenario=org-clinic
 *   node scripts/seed.js --scenario=all
 */
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';
import { assertNonProduction } from '../../scripts/db/guard-non-prod.js';
import { ORG_ROLE_ADMIN, ORG_ROLE_SUPER_ADMIN } from '../lib/orgRoles.js';

const { Pool } = pg;
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');

dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

/** Documented in docs/e2e/uat-demo-personas.md — demo/UAT only. */
export const DEMO_PASSWORD = 'UatDemoPass1!';
const DEMO_PASSWORD_HASH =
  '$2b$10$BgtLHM4jS8/oSsNAjYDzfueZv0kk.qRH1fqS.AUvqqfKiKO6M6Atm';

export const DEMO_IDS = {
  alice: 'a1000001-0001-4001-8001-000000000001',
  bob: 'a1000001-0001-4001-8001-000000000002',
  happyPawsOrg: 'a2000001-0001-4001-8001-000000000001',
  aliceOrgUser: 'a3000001-0001-4001-8001-000000000001',
  bobOrgUser: 'a3000001-0001-4001-8001-000000000002',
  buddyPet: 'a4000001-0001-4001-8001-000000000001',
  clinicPet: 'a4000001-0001-4001-8001-000000000002',
  partnerPawsOrg: 'a2000001-0001-4001-8001-000000000002',
};

const DEMO_USERS = {
  alice: {
    id: DEMO_IDS.alice,
    email: 'alice@demo.agathatrack.test',
    first_name: 'Alice',
    last_name: 'Super',
    category: 'pet_guardian',
  },
  bob: {
    id: DEMO_IDS.bob,
    email: 'bob@demo.agathatrack.test',
    first_name: 'Bob',
    last_name: 'Member',
    category: 'pet_guardian',
  },
};

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

async function upsertUser(client, user) {
  await client.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name, category)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (id) DO UPDATE SET
       email = EXCLUDED.email,
       password_hash = EXCLUDED.password_hash,
       first_name = EXCLUDED.first_name,
       last_name = EXCLUDED.last_name,
       category = EXCLUDED.category,
       updated_at = NOW()`,
    [
      user.id,
      user.email,
      DEMO_PASSWORD_HASH,
      user.first_name,
      user.last_name,
      user.category,
    ]
  );
}

async function seedGuardian(client) {
  await upsertUser(client, DEMO_USERS.alice);
  await client.query(
    `INSERT INTO pets (id, user_id, name, species, care_holder_kind, care_holder_user_id)
     VALUES ($1, $2, $3, $4, 'user', $2)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       species = EXCLUDED.species,
       user_id = EXCLUDED.user_id,
       care_holder_kind = EXCLUDED.care_holder_kind,
       care_holder_user_id = EXCLUDED.care_holder_user_id,
       updated_at = NOW()`,
    [DEMO_IDS.buddyPet, DEMO_IDS.alice, 'Buddy', 'dog']
  );
  console.log('seed: guardian scenario ready (alice + Buddy)');
}

async function seedOrgClinic(client) {
  await upsertUser(client, DEMO_USERS.alice);
  await upsertUser(client, DEMO_USERS.bob);

  await client.query(
    `INSERT INTO organizations (id, name, type, bio)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       type = EXCLUDED.type,
       bio = EXCLUDED.bio,
       updated_at = NOW()`,
    [
      DEMO_IDS.happyPawsOrg,
      'Happy Paws Clinic',
      'professional',
      'UAT demo veterinary clinic',
    ]
  );

  await client.query(
    `INSERT INTO organization_users (id, organization_id, user_id, role)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (organization_id, user_id) DO UPDATE SET role = EXCLUDED.role`,
    [DEMO_IDS.aliceOrgUser, DEMO_IDS.happyPawsOrg, DEMO_IDS.alice, ORG_ROLE_SUPER_ADMIN]
  );

  await client.query(
    `INSERT INTO organization_users (id, organization_id, user_id, role)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (organization_id, user_id) DO UPDATE SET role = EXCLUDED.role`,
    [DEMO_IDS.bobOrgUser, DEMO_IDS.happyPawsOrg, DEMO_IDS.bob, ORG_ROLE_ADMIN]
  );

  await client.query(
    `INSERT INTO pets (id, user_id, name, species, organization_id, care_holder_kind, care_holder_org_id)
     VALUES ($1, $2, $3, $4, $5, 'org', $5)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       species = EXCLUDED.species,
       organization_id = EXCLUDED.organization_id,
       care_holder_kind = EXCLUDED.care_holder_kind,
       care_holder_org_id = EXCLUDED.care_holder_org_id,
       updated_at = NOW()`,
    [DEMO_IDS.clinicPet, DEMO_IDS.alice, 'Clinic Cat', 'cat', DEMO_IDS.happyPawsOrg]
  );

  console.log('seed: org-clinic scenario ready (Happy Paws Clinic)');
}

/** Org UX v3 demo: discoverable clinic + connected partner (no hero photos). */
async function seedOrgV3Demo(client) {
  await seedOrgClinic(client);

  await client.query(
    `UPDATE organizations
     SET is_discoverable = true,
         town = 'Springfield',
         administrative_area = 'Demo County',
         description = 'UAT demo veterinary clinic (discoverable)',
         photo_url = '',
         logo_url = '',
         updated_at = NOW()
     WHERE id = $1`,
    [DEMO_IDS.happyPawsOrg],
  );

  await client.query(
    `INSERT INTO organizations (id, name, type, bio, is_discoverable, town, administrative_area, description)
     VALUES ($1, $2, $3, $4, true, $5, $6, $7)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       type = EXCLUDED.type,
       bio = EXCLUDED.bio,
       is_discoverable = EXCLUDED.is_discoverable,
       town = EXCLUDED.town,
       administrative_area = EXCLUDED.administrative_area,
       description = EXCLUDED.description,
       photo_url = '',
       logo_url = '',
       updated_at = NOW()`,
    [
      DEMO_IDS.partnerPawsOrg,
      'Partner Paws',
      'charity',
      'UAT demo connected rescue',
      'Riverside',
      'Demo County',
      'Partner organisation for connections/discover demos',
    ],
  );

  const [orgLowId, orgHighId] =
    DEMO_IDS.happyPawsOrg < DEMO_IDS.partnerPawsOrg
      ? [DEMO_IDS.happyPawsOrg, DEMO_IDS.partnerPawsOrg]
      : [DEMO_IDS.partnerPawsOrg, DEMO_IDS.happyPawsOrg];

  await client.query(
    `INSERT INTO org_connections (id, org_low_id, org_high_id, status)
     VALUES ($1, $2, $3, 'active')
     ON CONFLICT (org_low_id, org_high_id) DO UPDATE SET
       status = 'active',
       revoked_at = NULL`,
    [crypto.randomUUID(), orgLowId, orgHighId],
  );

  console.log('seed: org-v3-demo scenario ready (discoverable Happy Paws + Partner Paws)');
}

const SCENARIOS = {
  guardian: seedGuardian,
  'org-clinic': seedOrgClinic,
  'org-v3-demo': seedOrgV3Demo,
};

async function runScenario(pool, name) {
  const fn = SCENARIOS[name];
  if (!fn) {
    throw new Error(`Unknown scenario: ${name}`);
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await fn(client);
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

function parseScenarios(argv) {
  const arg = argv.find((a) => a.startsWith('--scenario='));
  if (!arg) return ['org-clinic'];
  const value = arg.slice('--scenario='.length);
  if (value === 'all') return Object.keys(SCENARIOS);
  return value.split(',').map((s) => s.trim()).filter(Boolean);
}

async function main() {
  assertNonProduction('database seed');
  const scenarios = parseScenarios(process.argv.slice(2));
  const pool = createPool();
  try {
    for (const scenario of scenarios) {
      await runScenario(pool, scenario);
    }
    console.log(`seed: completed (${scenarios.join(', ')})`);
  } finally {
    await pool.end();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(`seed ERROR: ${err.message}`);
    process.exit(1);
  });
}
