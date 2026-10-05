/**
 * PostgreSQL wire types that must not depend on the Node process time zone.
 */

import pg from 'pg';

const DATE_OID = 1082;
let registered = false;

/** Register parsers once per process (idempotent). */
export function registerPgCalendarTypes() {
  if (registered) return;
  registered = true;
  pg.types.setTypeParser(DATE_OID, (value) => value);
}

/**
 * TZ-7: fail fast when DATE columns are not returned as YYYY-MM-DD strings.
 *
 * @param {import('pg').PoolClient} client
 */
export async function assertPgDateWireFormat(client) {
  const result = await client.query("SELECT '2026-09-30'::date AS d");
  const d = result.rows[0]?.d;
  if (d !== '2026-09-30') {
    const err = new Error(
      `PG DATE parser misconfigured: expected "2026-09-30", got ${JSON.stringify(d)}`,
    );
    err.code = 'pg_date_parser_misconfigured';
    throw err;
  }
}
