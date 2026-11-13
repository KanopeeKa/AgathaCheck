import { enqueueSupportAttachmentDelete, supportScreenshotFileDeleteJob } from './enqueueAttachmentDelete.js';
import { enqueueGithubIssueDelete } from '../outbox/rowState.js';

/**
 * Delete tickets, pending outbox rows, screenshot files, and queue GitHub redact rows.
 *
 * @param {import('pg').PoolClient} client
 * @param {string[]} ticketIds
 * @param {string | null} correlationId erasure operation id when invoked from account erasure
 * @returns {Promise<{ ticketIds: string[], issueNumbers: number[], attachmentPaths: string[] }>}
 */
export async function purgeSupportTickets(client, ticketIds, correlationId = null) {
  if (!ticketIds.length) {
    return { ticketIds: [], issueNumbers: [], attachmentPaths: [] };
  }

  const attachments = await client.query(
    `SELECT id, storage_key FROM support_attachments WHERE ticket_id = ANY($1::uuid[])`,
    [ticketIds],
  );
  const tickets = await client.query(
    `SELECT id, github_issue_number FROM support_tickets WHERE id = ANY($1::uuid[])`,
    [ticketIds],
  );

  const attachmentPaths = [];
  for (const row of attachments.rows) {
    const job = supportScreenshotFileDeleteJob(row.storage_key);
    if (job) {
      attachmentPaths.push(job.payload.relative_path);
      await enqueueSupportAttachmentDelete(client, row.storage_key, correlationId);
    }
  }

  const issueNumbers = [];
  for (const row of tickets.rows) {
    const n = Number(row.github_issue_number);
    if (Number.isFinite(n) && n > 0) {
      issueNumbers.push(n);
      await enqueueGithubIssueDelete(client, n);
    }
  }

  await client.query(
    `DELETE FROM support_outbox
     WHERE ticket_id = ANY($1::uuid[])
       AND kind IN ('receipt', 'github_issue')
       AND status = 'pending'`,
    [ticketIds],
  );

  await client.query(`DELETE FROM support_tickets WHERE id = ANY($1::uuid[])`, [ticketIds]);

  return { ticketIds, issueNumbers, attachmentPaths };
}
