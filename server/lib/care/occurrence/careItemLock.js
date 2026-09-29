/**
 * One transaction and one row lock per care command (D-CSM-033, INV-6).
 */

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
  const client = typeof pool.connect === 'function' ? await pool.connect() : null;
  const db = client || pool;
  try {
    await db.query('BEGIN');
    if (beforeLock) await beforeLock(db);
    const locked = await db.query(
      'SELECT * FROM health_entries WHERE id = $1 FOR UPDATE',
      [entryId],
    );
    const entry = locked.rows[0];
    if (!entry) {
      await db.query('ROLLBACK');
      return null;
    }
    const result = await fn(db, entry);
    await db.query('COMMIT');
    return result;
  } catch (err) {
    try {
      await db.query('ROLLBACK');
    } catch {
      // connection already unusable; the original error matters
    }
    throw err;
  } finally {
    client?.release?.();
  }
}
