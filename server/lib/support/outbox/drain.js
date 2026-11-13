import { logger } from '../../logger.js';
import { SUPPORT_OUTBOX_MAX_ATTEMPTS } from './backoff.js';
import { refreshSupportGithubRepoGate } from './repoGate.js';
import { processSupportOutboxRow } from './processRow.js';

const TABLE_MISSING = '42P01';

/**
 * @param {import('pg').Pool} pool
 * @param {{ limit?: number }} [options]
 */
export async function drainSupportOutbox(pool, { limit = 10 } = {}) {
  await refreshSupportGithubRepoGate(pool);

  let rows;
  try {
    rows = await pool.query(
      `SELECT id, ticket_id, kind, github_issue_number, status, attempts
       FROM support_outbox
       WHERE status IN ('pending', 'failed')
         AND next_attempt_at <= now()
         AND attempts < $2
       ORDER BY next_attempt_at ASC, created_at ASC
       LIMIT $1`,
      [limit, SUPPORT_OUTBOX_MAX_ATTEMPTS],
    );
  } catch (err) {
    if (err?.code === TABLE_MISSING) {
      return { processed: 0 };
    }
    throw err;
  }

  let processed = 0;
  for (const row of rows.rows) {
    if (row.kind === 'github_issue' && (row.status === 'blocked' || row.status === 'disabled')) {
      continue;
    }
    try {
      await processSupportOutboxRow(pool, row);
      processed += 1;
    } catch (err) {
      logger.error({ err, outboxId: row.id, kind: row.kind }, 'support outbox row failed');
    }
  }

  if (processed > 0) {
    logger.info({ processed }, 'support outbox drain finished');
  }
  return { processed };
}
