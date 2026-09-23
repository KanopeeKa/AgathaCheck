/**
 * Mandatory checked-out-client transaction runner.
 * Acquire once; begin/commit/rollback/release once. No pool.query fallback.
 *
 * @template T
 * @param {import('pg').Pool} pool
 * @param {(client: import('pg').PoolClient) => Promise<T>} fn
 * @returns {Promise<T>}
 */
export async function withTransaction(pool, fn) {
  if (!pool || typeof pool.connect !== 'function') {
    throw new Error('withTransaction requires a pg.Pool with connect()');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      if (err && typeof err === 'object') {
        err.rollbackError = rollbackErr;
      }
    }
    throw err;
  } finally {
    client.release();
  }
}
