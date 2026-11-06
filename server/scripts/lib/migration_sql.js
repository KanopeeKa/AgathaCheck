/**
 * Helpers for the Node migration runner: keep incremental SQL inside the runner's
 * outer transaction (NNN_*.sql files must not COMMIT early).
 */

/**
 * Remove top-level BEGIN;/COMMIT; wrappers from incremental migration SQL.
 * Does not strip BEGIN/COMMIT inside dollar-quoted bodies or PL/pgSQL blocks.
 *
 * @param {string} sql
 * @returns {string}
 */
export function stripTopLevelTransactionWrappers(sql) {
  const lines = String(sql || '').split('\n');
  const out = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (/^BEGIN;?\s*(--.*)?$/i.test(trimmed)) continue;
    if (/^COMMIT;?\s*(--.*)?$/i.test(trimmed)) continue;
    out.push(line);
  }
  return out.join('\n').trim();
}

/**
 * @param {import('pg').PoolClient} client
 * @throws {Error} when the client is not inside a transaction (e.g. nested COMMIT).
 */
export async function assertClientInTransaction(client) {
  const { rows } = await client.query('SELECT txid_current_if_assigned() AS tx');
  if (rows[0]?.tx == null) {
    throw new Error(
      'migration left the runner transaction (remove BEGIN/COMMIT from NNN_*.sql or fix the hook)',
    );
  }
}
