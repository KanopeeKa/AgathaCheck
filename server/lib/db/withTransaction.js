/**
 * Mandatory checked-out-client transaction runner.
 * Acquire once; begin/commit/rollback/release once. No pool.query fallback.
 */
export class TransactionAbortedError extends Error {
  constructor(message = 'Transaction was rolled back before commit') {
    super(message);
    this.name = 'TransactionAbortedError';
  }
}

/**
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
    const commitResult = await client.query('COMMIT');
    if (commitResult.command !== 'COMMIT') {
      throw new TransactionAbortedError();
    }
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
