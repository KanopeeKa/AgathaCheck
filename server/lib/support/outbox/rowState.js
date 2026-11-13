import { v4 as uuidv4 } from 'uuid';

import {
  SUPPORT_OUTBOX_MAX_ATTEMPTS,
  supportOutboxNextAttemptAt,
} from './backoff.js';
import { safeOutboxError } from './safeError.js';

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 */
export async function markOutboxRowSent(db, rowId) {
  await db.query(
    `UPDATE support_outbox
     SET status = 'sent',
         last_error = NULL,
         updated_at = now()
     WHERE id = $1`,
    [rowId],
  );
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 */
export async function markOutboxRowSkipped(db, rowId) {
  await markOutboxRowSent(db, rowId);
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 */
export async function failOutboxRow(db, rowId, attempts, { retryable, message }) {
  const nextAttempts = attempts + 1;
  const terminal = !retryable || nextAttempts >= SUPPORT_OUTBOX_MAX_ATTEMPTS;
  const nextAttemptAt = terminal
    ? new Date('2099-01-01T00:00:00.000Z')
    : supportOutboxNextAttemptAt(nextAttempts);
  await db.query(
    `UPDATE support_outbox
     SET status = 'failed',
         attempts = $2,
         next_attempt_at = COALESCE($3::timestamptz, next_attempt_at),
         last_error = $4,
         updated_at = now()
     WHERE id = $1`,
  [
    rowId,
    nextAttempts,
    nextAttemptAt,
    safeOutboxError(message),
  ],
  );
}

/**
 * @param {import('pg').PoolClient} client
 * @param {number} issueNumber
 */
export async function enqueueGithubIssueDelete(client, issueNumber) {
  const id = uuidv4();
  await client.query(
    `INSERT INTO support_outbox (id, ticket_id, kind, github_issue_number, status)
     VALUES ($1, NULL, 'github_issue_delete', $2, 'pending')
     ON CONFLICT (kind, github_issue_number)
       WHERE kind = 'github_issue_delete'
     DO NOTHING`,
    [id, issueNumber],
  );
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} ticketId
 * @param {number} issueNumber
 * @returns {Promise<boolean>} true when the ticket row still exists
 */
export async function writeGithubIssueNumber(client, ticketId, issueNumber) {
  const updated = await client.query(
    `UPDATE support_tickets
     SET github_issue_number = $1
     WHERE id = $2`,
    [issueNumber, ticketId],
  );
  if (updated.rowCount === 0) {
    await enqueueGithubIssueDelete(client, issueNumber);
    return false;
  }
  return true;
}
