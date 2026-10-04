/**
 * Canonical pg.Pool factory — registers calendar DATE parsing before any query.
 */

import { Pool } from 'pg';

import { assertPgDateWireFormat, registerPgCalendarTypes } from './pgTypes.js';

registerPgCalendarTypes();

/**
 * @param {import('pg').PoolConfig} [overrides]
 * @returns {import('pg').Pool}
 */
export function createAppPool(overrides = {}) {
  const databaseUrl = overrides.connectionString ?? process.env.DATABASE_URL;
  const pool = databaseUrl
    ? new Pool({ connectionString: databaseUrl, ...overrides })
    : new Pool({
        user: process.env.PGUSER || 'user',
        password: process.env.PGPASSWORD || 'password',
        host: process.env.PGHOST || 'localhost',
        port: Number(process.env.PGPORT || 5432),
        database: process.env.PGDATABASE || 'agatha_db',
        ...overrides,
      });

  pool.on('connect', (client) => {
    client.query("SET TIME ZONE 'UTC'").catch(() => {});
  });
  return pool;
}

/**
 * @param {import('pg').Pool} pool
 */
export async function verifyPgDateParser(pool) {
  const client = await pool.connect();
  try {
    await assertPgDateWireFormat(client);
  } finally {
    client.release();
  }
}

/**
 * Process zone for tick / ops logs (TZ-7 diagnostic field).
 */
export function nodeProcessTimeZone() {
  if (process.env.TZ) return process.env.TZ;
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch {
    return 'unknown';
  }
}
