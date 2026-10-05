#!/usr/bin/env node
/**
 * Read-only SQL helper for host ops (DC-7). SQL from stdin; uses backend .env.
 */
import { createInterface } from 'node:readline';

import { createAppPool } from '../../lib/db/createPool.js';
import { loadBackendEnv } from '../lib/loadBackendEnv.js';

loadBackendEnv();

const WRITE_RE = /\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|GRANT|REVOKE)\b/i;

async function readStdin() {
  const rl = createInterface({ input: process.stdin, terminal: false });
  const lines = [];
  for await (const line of rl) lines.push(line);
  return lines.join('\n').trim();
}

const sql = await readStdin();
if (!sql) {
  console.error('sql_readonly: empty SQL on stdin');
  process.exit(1);
}
if (WRITE_RE.test(sql)) {
  console.error('sql_readonly: write statements are not allowed');
  process.exit(1);
}

const pool = createAppPool();
const client = await pool.connect();
try {
  await client.query('BEGIN READ ONLY');
  const result = await client.query(sql);
  await client.query('ROLLBACK');
  console.log(JSON.stringify(result.rows, null, 2));
} catch (err) {
  try {
    await client.query('ROLLBACK');
  } catch {
    // ignore
  }
  console.error('sql_readonly failed', err.message);
  process.exit(1);
} finally {
  client.release();
  await pool.end();
}
