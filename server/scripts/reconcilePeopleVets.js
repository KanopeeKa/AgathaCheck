#!/usr/bin/env node
/**
 * Idempotent repair: vets → people_contacts + pets.vet_id → primary_vet links.
 *
 * Usage: node server/scripts/reconcilePeopleVets.js
 */
import pg from 'pg';

import { rebuildAll } from '../lib/people/vetProjection.js';

const pool = new pg.Pool({
  user: process.env.PGUSER || 'user',
  password: process.env.PGPASSWORD || 'password',
  host: process.env.PGHOST || 'localhost',
  port: Number(process.env.PGPORT || 5432),
  database: process.env.PGDATABASE || 'agatha_db',
});

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await rebuildAll(client);
    await client.query('COMMIT');
    console.log('reconcilePeopleVets: OK');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main();
