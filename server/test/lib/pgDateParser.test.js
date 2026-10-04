import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { describe, expect, it } from '@jest/globals';

import { createAppPool, verifyPgDateParser } from '../../lib/db/createPool.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';

const SERVER_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

describe('PG DATE parser (TZ-1)', () => {
  it('returns YYYY-MM-DD strings from PostgreSQL DATE', async () => {
    const pool = createAppPool();
    try {
      await verifyPgDateParser(pool);
      const { rows } = await pool.query("SELECT '2026-09-30'::date AS d");
      expect(rows[0].d).toBe('2026-09-30');
      expect(dateToIsoDate(rows[0].d)).toBe('2026-09-30');
    } finally {
      await pool.end();
    }
  });

  it('guard: raw pg Pool without createAppPool fails TZ-7 under Europe/Paris', () => {
    const script = `
      import pg from 'pg';
      import { assertPgDateWireFormat } from './lib/db/pgTypes.js';
      const pool = new pg.Pool({
        user: process.env.PGUSER || 'user',
        password: process.env.PGPASSWORD || 'password',
        host: process.env.PGHOST || 'localhost',
        port: Number(process.env.PGPORT || 5432),
        database: process.env.PGDATABASE || 'agatha_db',
      });
      const client = await pool.connect();
      try {
        await assertPgDateWireFormat(client);
        process.exit(0);
      } catch {
        process.exit(1);
      } finally {
        client.release();
        await pool.end();
      }
    `;
    const result = spawnSync(process.execPath, ['--input-type=module', '-e', script], {
      cwd: SERVER_ROOT,
      env: { ...process.env, TZ: 'Europe/Paris' },
    });
    expect(result.status).toBe(1);
  });
});
