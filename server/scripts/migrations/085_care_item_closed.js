/**
 * Migration 085 — care item Closed status (CARE-STATUS-R-009, R-013 items).
 * Adds `care_closed_reason`, migrates `completed` → `closed` with ended / stopped_by_user.
 *
 * @param {import('pg').PoolClient} client
 */
export async function migrateCareItemClosed(client) {
  await client.query(`
    ALTER TABLE health_entries
      ADD COLUMN IF NOT EXISTS care_closed_reason VARCHAR(50);
  `);

  await client.query(`
    ALTER TABLE health_entries
      DROP CONSTRAINT IF EXISTS health_entries_status_check;
  `);

  await client.query(`
    ALTER TABLE health_entries
      DROP CONSTRAINT IF EXISTS health_entries_care_closed_reason_check;
  `);

  const hasAudit = await client.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = current_schema() AND table_name = 'audit_events'`,
  );

  if (hasAudit.rows.length > 0) {
    await client.query(`
      UPDATE health_entries he
      SET status = 'closed',
          care_closed_reason = 'stopped_by_user',
          updated_at = NOW()
      WHERE he.status = 'completed'
        AND EXISTS (
          SELECT 1 FROM audit_events ae
          WHERE ae.action = 'health_entry.closed'
            AND ae.resource_id = he.id::text
        );
    `);
  }

  await client.query(`
    UPDATE health_entries
    SET status = 'closed',
        care_closed_reason = 'ended',
        updated_at = NOW()
    WHERE status = 'completed';
  `);

  await client.query(`
    ALTER TABLE health_entries
      ADD CONSTRAINT health_entries_status_check CHECK (
        status IN ('active', 'paused', 'closed')
      );
  `);

  await client.query(`
    ALTER TABLE health_entries
      ADD CONSTRAINT health_entries_care_closed_reason_check CHECK (
        care_closed_reason IS NULL
        OR care_closed_reason IN ('ended', 'stopped_by_user')
      );
  `);

  await client.query(`
    ALTER TABLE health_entries
      DROP CONSTRAINT IF EXISTS health_entries_closed_reason_required;
  `);

  await client.query(`
    ALTER TABLE health_entries
      ADD CONSTRAINT health_entries_closed_reason_required CHECK (
        status <> 'closed' OR care_closed_reason IS NOT NULL
      );
  `);
}
