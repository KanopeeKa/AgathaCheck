import { randomUUID } from 'crypto';

import { applyMigrationForRunner } from '../../scripts/migrate.js';

import { openStrictHarness } from './helpers/careHarness.js';

describe('migrate runner transaction', () => {
  it('rolls back DDL when apply fails after SQL', async () => {
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
          `CREATE TABLE ${probeTable} (n int);`,
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

  it('strips standalone COMMIT so it cannot end the runner transaction', async () => {
    const { pool } = await openStrictHarness();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const txBefore = (
        await client.query('SELECT txid_current()::text AS tx')
      ).rows[0].tx;
      await applyMigrationForRunner(client, '999_commit_only.sql', 'COMMIT;\nSELECT 1;');
      const txAfter = (
        await client.query('SELECT txid_current()::text AS tx')
      ).rows[0].tx;
      expect(txAfter).toBe(txBefore);
      await client.query('ROLLBACK');
    } finally {
      client.release();
    }
  });

  it('accepts DO $$ BEGIN … END $$ blocks', async () => {
    const { pool } = await openStrictHarness();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await applyMigrationForRunner(
        client,
        '999_do_block.sql',
        'DO $$\nBEGIN\n  PERFORM 1;\nEND\n$$;',
      );
      await client.query('ROLLBACK');
    } finally {
      client.release();
    }
  });

  it('accepts zero-row UPDATE migrations before xid assignment', async () => {
    const { pool } = await openStrictHarness();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await applyMigrationForRunner(
        client,
        '999_noop_update.sql',
        'UPDATE _migrations SET name = name WHERE false;',
      );
      await client.query('ROLLBACK');
    } finally {
      client.release();
    }
  });

  it('rejects a hook that COMMITs', async () => {
    const { pool } = await openStrictHarness();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await expect(
        applyMigrationForRunner(client, '999_hook_commit.sql', 'SELECT 1;', {
          runHook: async (db) => {
            await db.query('COMMIT');
          },
        }),
      ).rejects.toThrow(/runner transaction/);
      await client.query('ROLLBACK');
    } finally {
      client.release();
    }
  });
});
