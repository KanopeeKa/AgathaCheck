/**
 * One transaction and one row lock per care command (D-CSM-033, INV-6).
 */

import { withTransaction } from '../../db/withTransaction.js';

class CareItemNotFoundForLock extends Error {
  constructor() {
    super('care item not found for lock');
    this.name = 'CareItemNotFoundForLock';
  }
}

/**
 * Run `fn(db, entry)` inside a transaction holding `SELECT … FOR UPDATE` on
 * the care item. Returns `null` when the item does not exist.
 *
 * @template T
 * @param {import('pg').Pool} pool
 * @param {string} entryId
 * @param {(db: import('pg').PoolClient, entry: object) => Promise<T>} fn
 * @param {{ beforeLock?: (db: import('pg').PoolClient) => Promise<void> }} [options]
 *   `beforeLock` runs inside the transaction first (e.g. the INSERT of a new item)
 * @returns {Promise<T|null>}
 */
export async function withCareItemLock(pool, entryId, fn, { beforeLock = null } = {}) {
  if (!pool || typeof pool.connect !== 'function') {
    throw new Error('withCareItemLock requires a pg.Pool with connect()');
  }
  try {
    return await withTransaction(pool, async (client) => {
      if (beforeLock) await beforeLock(client);
      const locked = await client.query(
        'SELECT * FROM health_entries WHERE id = $1 FOR UPDATE',
        [entryId],
      );
      const entry = locked.rows[0];
      if (!entry) throw new CareItemNotFoundForLock();
      return fn(client, entry);
    });
  } catch (err) {
    if (err instanceof CareItemNotFoundForLock) return null;
    throw err;
  }
}
