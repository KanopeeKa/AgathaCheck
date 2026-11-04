/**
 * Legacy UAT seeds still insert `status = completed`. After migration 085 the
 * check constraint allows only `closed`. Relax within the seed transaction so
 * DDL rolls back with the test (PostgreSQL transactional DDL).
 *
 * @param {import('pg').PoolClient} client
 */
export async function relaxHealthEntryStatusForLegacySeeds(client) {
  const col = await client.query(
    `SELECT 1 FROM information_schema.columns
     WHERE table_name = 'health_entries' AND column_name = 'care_closed_reason'`,
  );
  if (col.rows.length === 0) return;
  await client.query('ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_status_check');
  await client.query(`
    ALTER TABLE health_entries ADD CONSTRAINT health_entries_status_check CHECK (
      status IN ('active', 'paused', 'closed', 'completed')
    )`);
}
