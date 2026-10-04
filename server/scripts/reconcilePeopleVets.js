#!/usr/bin/env node
/**
 * Idempotent repair: vets → people_contacts + pets.vet_id → primary_vet links.
 *
 * Usage: node server/scripts/reconcilePeopleVets.js
 */
import { createAppPool } from '../lib/db/createPool.js';
import { rebuildAll } from '../lib/people/vetProjection.js';

const pool = createAppPool();

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
