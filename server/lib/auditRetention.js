import {
  AUDIT_COLD_DAYS,
  AUDIT_HOT_DAYS,
  AUDIT_PSEUDONYM_SALT,
  AUDIT_WARM_DAYS,
} from '../config/observability.js';

/**
 * Apply hot → warm → cold → purge retention transitions.
 * Returns counts of rows affected at each stage.
 */
export async function runAuditRetention(pool) {
  const hotToWarm = await pool.query(
    `UPDATE audit_events
     SET retention_tier = 'warm',
         actor_pseudonym = CASE
           WHEN actor_user_id IS NOT NULL THEN md5(actor_user_id::text || $1)
           ELSE actor_pseudonym
         END,
         actor_user_id = NULL,
         ip_address = NULL,
         user_agent = NULL
     WHERE retention_tier = 'hot'
       AND occurred_at < NOW() - make_interval(days => $2)
     RETURNING id`,
    [AUDIT_PSEUDONYM_SALT, AUDIT_HOT_DAYS]
  );

  const warmToCold = await pool.query(
    `UPDATE audit_events
     SET retention_tier = 'cold',
         actor_pseudonym = NULL,
         metadata = '{}'::jsonb
     WHERE retention_tier = 'warm'
       AND occurred_at < NOW() - make_interval(days => $1)
     RETURNING id`,
    [AUDIT_WARM_DAYS]
  );

  const coldPurge = await pool.query(
    `DELETE FROM audit_events
     WHERE retention_tier = 'cold'
       AND occurred_at < NOW() - make_interval(days => $1)
     RETURNING id`,
    [AUDIT_COLD_DAYS]
  );

  return {
    hotToWarm: hotToWarm.rowCount,
    warmToCold: warmToCold.rowCount,
    coldPurge: coldPurge.rowCount,
  };
}
