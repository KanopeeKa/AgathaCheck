import { resolveEmailLocale } from '../../email/locale.js';
import { sendSupportReceiptEmail } from '../../../services/mailService.js';
import { getSupportReplyTo } from '../../../config/mail.js';
import {
  buildGithubIssueBody,
  buildGithubIssueLabels,
  buildGithubIssueTitle,
} from './issueContent.js';
import {
  createGithubSupportIssue,
  redactGithubSupportIssue,
} from './githubApi.js';
import { withTransaction } from '../../db/withTransaction.js';
import {
  failOutboxRow,
  markOutboxRowSent,
  markOutboxRowSkipped,
  writeGithubIssueNumber,
} from './rowState.js';

/**
 * @param {import('pg').Pool} pool
 * @param {*} row outbox row
 */
export async function processSupportOutboxRow(pool, row) {
  if (row.kind === 'receipt') {
    await processReceiptRow(pool, row);
    return;
  }
  if (row.kind === 'github_issue') {
    await processGithubIssueRow(pool, row);
    return;
  }
  if (row.kind === 'github_issue_delete') {
    await processRedactRow(pool, row);
    return;
  }
  await failOutboxRow(pool, row.id, row.attempts, {
    retryable: false,
    message: `unknown outbox kind ${row.kind}`,
  });
}

async function loadTicket(pool, ticketId) {
  const res = await pool.query(
    `SELECT id, reference, reporter_email, category, title, description,
            expected, actual, steps, frequency, context, locale
     FROM support_tickets
     WHERE id = $1`,
    [ticketId],
  );
  return res.rows[0] || null;
}

async function processReceiptRow(pool, row) {
  const ticket = await loadTicket(pool, row.ticket_id);
  if (!ticket) {
    await markOutboxRowSkipped(pool, row.id);
    return;
  }
  const locale = resolveEmailLocale(ticket.locale, null);
  try {
    await sendSupportReceiptEmail({
      to: ticket.reporter_email,
      locale,
      reference: ticket.reference,
      replyTo: getSupportReplyTo(),
    });
    await markOutboxRowSent(pool, row.id);
  } catch (err) {
    await failOutboxRow(pool, row.id, row.attempts, {
      retryable: true,
      message: err?.message || 'receipt send failed',
    });
  }
}

async function processGithubIssueRow(pool, row) {
  if (row.status === 'blocked' || row.status === 'disabled') {
    return;
  }
  const ticket = await loadTicket(pool, row.ticket_id);
  if (!ticket) {
    await markOutboxRowSkipped(pool, row.id);
    return;
  }
  const outcome = await createGithubSupportIssue({
    title: buildGithubIssueTitle(ticket),
    body: buildGithubIssueBody(ticket),
    labels: buildGithubIssueLabels(ticket),
  });
  if (!outcome.ok) {
    await failOutboxRow(pool, row.id, row.attempts, {
      retryable: outcome.retryable,
      message: outcome.message,
    });
    return;
  }

  try {
    await withTransaction(pool, async (client) => {
      const exists = await writeGithubIssueNumber(client, ticket.id, outcome.number);
      if (!exists) {
        // Ticket vanished while GitHub succeeded — redact row queued in writeGithubIssueNumber.
      }
      await client.query(
        `UPDATE support_outbox
         SET status = 'sent', last_error = NULL, updated_at = now()
         WHERE id = $1`,
        [row.id],
      );
    });
  } catch (err) {
    await failOutboxRow(pool, row.id, row.attempts, {
      retryable: true,
      message: err?.message || 'issue number write-back failed',
    });
  }
}

async function processRedactRow(pool, row) {
  const issueNumber = Number(row.github_issue_number);
  if (!Number.isFinite(issueNumber)) {
    await failOutboxRow(pool, row.id, row.attempts, {
      retryable: false,
      message: 'redact row missing issue number',
    });
    return;
  }
  const outcome = await redactGithubSupportIssue(issueNumber);
  if (!outcome.ok) {
    await failOutboxRow(pool, row.id, row.attempts, {
      retryable: outcome.retryable,
      message: outcome.message,
    });
    return;
  }
  await markOutboxRowSent(pool, row.id);
}
