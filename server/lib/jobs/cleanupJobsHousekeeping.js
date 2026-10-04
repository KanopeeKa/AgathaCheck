/**
 * Retention for succeeded cleanup jobs: clear payloads and purge after 30 days.
 */

const RETENTION_DAYS = 30;

export async function runCleanupJobsHousekeeping(db) {
  const nulled = await db.query(
    `UPDATE cleanup_jobs
     SET payload = NULL, updated_at = now()
     WHERE status = 'succeeded' AND payload IS NOT NULL`,
  );
  const purged = await db.query(
    `DELETE FROM cleanup_jobs
     WHERE status = 'succeeded'
       AND completed_at IS NOT NULL
       AND completed_at < now() - ($1::text || ' days')::interval`,
    [String(RETENTION_DAYS)],
  );
  return {
    payloadsCleared: nulled.rowCount ?? 0,
    succeededPurged: purged.rowCount ?? 0,
  };
}
