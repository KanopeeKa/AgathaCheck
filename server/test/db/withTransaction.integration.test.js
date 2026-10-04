import { randomUUID } from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { TransactionAbortedError, withTransaction } from '../../lib/db/withTransaction.js';
import { createDbPool } from './helpers/careHarness.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/086_pet_lifecycle_notifications.sql');

let pool;

beforeAll(async () => {
  pool = createDbPool();
  await pool.query('SELECT 1');
}, 30000);

afterAll(async () => {
  await pool?.end();
});

describe('withTransaction (real PG)', () => {
  it('throws TransactionAbortedError when an in-transaction error is swallowed', async () => {
    await expect(
      withTransaction(pool, async (client) => {
        await client.query('SAVEPOINT swallowed');
        try {
          await client.query('SELECT 1 FROM definitely_missing_table_for_txn_test');
        } catch {
          // swallowed — transaction is aborted in PostgreSQL
        }
        await client.query('RELEASE SAVEPOINT swallowed').catch(() => {});
      }),
    ).rejects.toBeInstanceOf(TransactionAbortedError);
  });
});
