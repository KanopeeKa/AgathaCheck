import { spawnSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

import { describe, expect, it } from '@jest/globals';

import { openHarness } from './helpers/careHarness.js';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');

describe('PostgreSQL schema equivalence (migrations vs canonical.sql)', () => {
  jest.setTimeout(300000);

  it('matches committed canonical snapshot via bootstrap path', async () => {
    const harness = await openHarness();
    if (!harness.pool) {
      // Local mock CI — suite skipped when Postgres is absent.
      return;
    }
    await harness.pool.end();

    const result = spawnSync('bash', [`${repoRoot}/scripts/db/check-schema-equivalence.sh`], {
      cwd: repoRoot,
      env: {
        ...process.env,
        RESET_DB: 'true',
        PGUSER: process.env.PGUSER || 'user',
        PGPASSWORD: process.env.PGPASSWORD || 'password',
        PGHOST: process.env.PGHOST || 'localhost',
        PGPORT: process.env.PGPORT || '5432',
        PGDATABASE: process.env.PGDATABASE || 'agatha_db',
      },
      encoding: 'utf8',
    });

    if (result.status !== 0) {
      // eslint-disable-next-line no-console
      console.error(result.stdout);
      // eslint-disable-next-line no-console
      console.error(result.stderr);
    }
    expect(result.status).toBe(0);
  });
});
