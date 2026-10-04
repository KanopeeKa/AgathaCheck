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

    const isolatedDb = process.env.SCHEMA_EQUIV_DATABASE || 'agatha_schema_equiv_ci';
    const pgEnv = {
      ...process.env,
      RESET_DB: 'true',
      PGUSER: process.env.PGUSER || 'user',
      PGPASSWORD: process.env.PGPASSWORD || 'password',
      PGHOST: process.env.PGHOST || 'localhost',
      PGPORT: process.env.PGPORT || '5432',
      PGDATABASE: isolatedDb,
    };
    const prep = spawnSync(
      'bash',
      ['-c', `psql -v ON_ERROR_STOP=1 -tc "SELECT 1 FROM pg_database WHERE datname = '${isolatedDb}'" | grep -q 1 || createdb "${isolatedDb}"`],
      { cwd: repoRoot, env: pgEnv, encoding: 'utf8' },
    );
    if (prep.status !== 0) {
      // eslint-disable-next-line no-console
      console.error(prep.stdout);
      // eslint-disable-next-line no-console
      console.error(prep.stderr);
    }
    expect(prep.status).toBe(0);

    const result = spawnSync('bash', [`${repoRoot}/scripts/db/check-schema-equivalence.sh`], {
      cwd: repoRoot,
      env: pgEnv,
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
