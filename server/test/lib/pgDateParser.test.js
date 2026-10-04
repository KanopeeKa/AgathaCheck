import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { describe, expect, it } from '@jest/globals';

const SERVER_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

describe('PG DATE parser guard (no live DB)', () => {
  it('raw pg Pool without createAppPool fails TZ-7 under Europe/Paris', () => {
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
