#!/usr/bin/env node
/**
 * Idempotent: split legacy "Vet contact: …" notes on organisation contacts.
 * Usage: node server/scripts/migrateVetContactNotes.js <userId>
 */
import pg from 'pg';

import { migrateVetContactNotesForUser } from '../lib/people/migrateVetContactNotes.js';

const userId = process.argv[2];
if (!userId) {
  console.error('Usage: node server/scripts/migrateVetContactNotes.js <userId>');
  process.exit(1);
}

const pool = new pg.Pool({
  user: process.env.PGUSER || 'user',
  password: process.env.PGPASSWORD || 'password',
  host: process.env.PGHOST || 'localhost',
  port: Number(process.env.PGPORT || 5432),
  database: process.env.PGDATABASE || 'agatha_db',
});

try {
  const { repaired } = await migrateVetContactNotesForUser(pool, userId);
  console.log(`Repaired ${repaired} organisation contact(s) for user ${userId}`);
} finally {
  await pool.end();
}
