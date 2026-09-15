/**
 * Run fn inside a transaction when pool supports connect(); otherwise run fn(pool) directly.
 *
 * @template T
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {(client: import('pg').Pool|import('pg').PoolClient) => Promise<T>} fn
 * @returns {Promise<T>}
 */
export async function withOptionalTransaction(pool, fn) {
  if (typeof pool.connect === 'function') {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (err) {
      try {
        await client.query('ROLLBACK');
      } catch (_) {
        /* ignore */
      }
      throw err;
    } finally {
      client.release();
    }
  }
  return fn(pool);
}
