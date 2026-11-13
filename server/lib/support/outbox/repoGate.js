import { logger } from '../../logger.js';
import { isGithubOutboxEnabled } from './config.js';
import { fetchGithubRepoPrivacy } from './githubApi.js';

let lastGateCheckAt = 0;
const GATE_TTL_MS = 60_000;

/** @internal test helper */
export function resetSupportGithubRepoGateCacheForTests() {
  lastGateCheckAt = 0;
}

/**
 * Sync create-issue row statuses with GitHub repo configuration and privacy.
 *
 * @param {import('pg').Pool} pool
 */
export async function refreshSupportGithubRepoGate(pool) {
  const now = Date.now();
  if (now - lastGateCheckAt < GATE_TTL_MS) {
    return;
  }
  lastGateCheckAt = now;

  if (!isGithubOutboxEnabled()) {
    const disabled = await pool.query(
      `UPDATE support_outbox
       SET status = 'disabled', updated_at = now()
       WHERE kind = 'github_issue'
         AND status IN ('pending', 'failed', 'blocked')`,
    );
    if (disabled.rowCount > 0) {
      logger.info({ count: disabled.rowCount }, 'support outbox: github_issue rows disabled (no repo)');
    }
    return;
  }

  const privacy = await fetchGithubRepoPrivacy();
  if (!privacy.ok) {
    const blocked = await pool.query(
      `UPDATE support_outbox
       SET status = 'blocked',
           last_error = $1,
           updated_at = now()
       WHERE kind = 'github_issue'
         AND status IN ('pending', 'failed')`,
      [privacy.reason],
    );
    if (blocked.rowCount > 0) {
      logger.warn(
        { count: blocked.rowCount, reason: privacy.reason },
        'support outbox: create-issue rows blocked',
      );
    }
    return;
  }

  const unblocked = await pool.query(
    `UPDATE support_outbox
     SET status = 'pending',
         next_attempt_at = now(),
         last_error = NULL,
         updated_at = now()
     WHERE kind = 'github_issue'
       AND status = 'blocked'`,
  );
  if (unblocked.rowCount > 0) {
    logger.info({ count: unblocked.rowCount }, 'support outbox: blocked create-issue rows returned to pending');
  }
}
