import { randomUUID } from 'crypto';

import { applyMigrationForRunner } from '../../scripts/migrate.js';

import { openStrictHarness } from '../db/helpers/careHarness.js';

describe('migrate runner transaction', () => {
  it('rolls back DDL and ledger when apply fails after SQL', async () => {
    const { pool } = await openStrictHarness();
    const probeTable = `mig_runner_probe_${randomUUID().replace(/-/g, '')}`;
    const migrationName = `999_${probeTable}.sql`;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      try {
        await applyMigrationForRunner(
          client,
          migrationName,
          `BEGIN;\nCOMMIT;\nCREATE TABLE ${probeTable} (n int);`,
        );
        throw new Error('simulated migration hook failure');
      } catch (err) {
        await client.query('ROLLBACK');
        if (!/simulated migration hook failure/.test(err.message)) throw err;
      }
      const table = await pool.query(
        `SELECT 1 FROM information_schema.tables WHERE table_name = $1`,
        [probeTable],
      );
      expect(table.rows).toHaveLength(0);
      const ledger = await pool.query(
        'SELECT 1 FROM _migrations WHERE name = $1',
        [migrationName],
      );
      expect(ledger.rows).toHaveLength(0);
    } finally {
      client.release();
    }
  });
});
