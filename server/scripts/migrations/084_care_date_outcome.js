/**
 * Migration 084 — care date outcome in place (CARE-STATUS-R-001, R-013, R-026).
 * Adds stored status `not_recorded`, backfills from skipped + close_reason, drops close_reason.
 *
 * Tests and dev call this hook directly; production pairs it with db/migrations ledger SQL.
 *
 * @param {import('pg').PoolClient} client
 */
export async function migrateCareDateOutcome(client) {
  const legacy = await client.query(
    `SELECT 1 FROM information_schema.columns
     WHERE table_schema = current_schema()
       AND table_name = 'health_occurrences' AND column_name = 'close_reason'`,
  );
  const hasCloseReason = legacy.rows.length > 0;

  await client.query(`
    ALTER TABLE health_occurrences
      DROP CONSTRAINT IF EXISTS health_occurrences_status_check;
  `);

  if (hasCloseReason) {
    await client.query(`
      UPDATE health_occurrences
      SET status = 'not_recorded', updated_at = NOW()
      WHERE status = 'skipped' AND close_reason = 'not_recorded';
    `);

    await client.query(`
      UPDATE health_occurrences
      SET status = 'not_recorded', updated_at = NOW()
      WHERE status = 'skipped'
        AND close_reason IN ('system', 'paused', 'covered')
        AND (
          scheduled_date < CURRENT_DATE
          OR (
            scheduled_date = CURRENT_DATE
            AND (
              scheduled_time IS NULL
              OR scheduled_time <= LOCALTIME
            )
          )
        );
    `);

    await client.query(`
      DELETE FROM health_occurrences
      WHERE status = 'skipped'
        AND close_reason IN ('system', 'paused', 'covered')
        AND NOT (
          scheduled_date < CURRENT_DATE
          OR (
            scheduled_date = CURRENT_DATE
            AND (
              scheduled_time IS NULL
              OR scheduled_time <= LOCALTIME
            )
          )
        );
    `);

    await client.query(`
      UPDATE health_occurrences
      SET close_reason = NULL, updated_at = NOW()
      WHERE status IN ('completed', 'skipped', 'not_recorded')
        AND close_reason IS NOT NULL;
    `);
  }

  await client.query(`
    ALTER TABLE health_occurrences
      ADD CONSTRAINT health_occurrences_status_check CHECK (
        status IN ('pending', 'completed', 'skipped', 'not_recorded')
      );
  `);

  await client.query(`
    ALTER TABLE health_occurrences
      DROP CONSTRAINT IF EXISTS health_occurrences_close_reason_check;
  `);
  await client.query(`
    ALTER TABLE health_occurrences
      DROP COLUMN IF EXISTS close_reason;
  `);
}
