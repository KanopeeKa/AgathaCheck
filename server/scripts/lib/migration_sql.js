/**
 * Helpers for the Node migration runner: keep incremental SQL inside the runner's
 * outer transaction (NNN_*.sql files must not COMMIT early).
 */

/** @typedef {{ line: number, kind: string }} MigrationSqlTransactionViolation */

/**
 * Lines that end the runner-owned transaction (semicolon required).
 * Does not match PL/pgSQL `BEGIN` inside `DO $$ … $$` (no trailing semicolon on that line).
 */
const TOP_LEVEL_TX_LINE =
  /^(?:BEGIN\s*;|BEGIN\s+TRANSACTION\s*;|START\s+TRANSACTION\s*;|COMMIT\s*;|END\s+TRANSACTION\s*;)\s*(?:--.*)?$/i;

/**
 * @param {string} sql
 * @returns {MigrationSqlTransactionViolation[]}
 */
export function findTopLevelSqlTransactionViolations(sql) {
  const violations = [];
  let inDollarQuote = false;
  let dollarTag = null;

  const lines = String(sql || '').split('\n');
  for (let lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
    const line = lines[lineIndex];
    let rest = line;
    let col = 0;

    while (rest.length > 0) {
      if (inDollarQuote) {
        const closeIdx = rest.indexOf(dollarTag);
        if (closeIdx === -1) {
          break;
        }
        rest = rest.slice(closeIdx + dollarTag.length);
        col += closeIdx + dollarTag.length;
        inDollarQuote = false;
        dollarTag = null;
        continue;
      }

      const openMatch = rest.match(/\$([A-Za-z0-9_]*)\$/);
      if (openMatch && openMatch.index != null) {
        col += openMatch.index + openMatch[0].length;
        rest = rest.slice(openMatch.index + openMatch[0].length);
        dollarTag = openMatch[0];
        inDollarQuote = true;
        continue;
      }

      const trimmed = rest.trimStart();
      const leading = rest.length - trimmed.length;
      if (TOP_LEVEL_TX_LINE.test(trimmed)) {
        const kindMatch = trimmed.match(
          /^(BEGIN|COMMIT|START|END)(?:\s+TRANSACTION)?\s*;/i,
        );
        violations.push({
          line: lineIndex + 1,
          kind: kindMatch ? kindMatch[1].toUpperCase() : trimmed.split(/\s/)[0].toUpperCase(),
        });
      }
      break;
    }
  }

  return violations;
}

/**
 * @param {import('pg').PoolClient} client
 * @returns {Promise<string>}
 */
export async function captureRunnerTransactionId(client) {
  const { rows } = await client.query('SELECT txid_current()::text AS tx');
  return rows[0].tx;
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} txBefore from {@link captureRunnerTransactionId}
 * @throws {Error} when the client left or restarted the runner transaction
 */
export async function assertRunnerTransactionUnchanged(client, txBefore) {
  const { rows } = await client.query('SELECT txid_current()::text AS tx');
  const txAfter = rows[0]?.tx;
  if (txAfter !== txBefore) {
    throw new Error(
      'migration left the runner transaction (remove BEGIN/COMMIT from NNN_*.sql or fix the hook)',
    );
  }
}
