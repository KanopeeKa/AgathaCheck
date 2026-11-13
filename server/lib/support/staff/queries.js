import {
  mapStaffAttachment,
  mapStaffOutboxRow,
  mapStaffTicketDetail,
  mapStaffTicketSummary,
} from './ticketMaps.js';

const LIST_LIMIT = 200;

/**
 * @param {import('pg').Pool} pool
 */
export async function listSupportStaffTickets(pool) {
  const ticketsResult = await pool.query(
    `SELECT id, reference, category, title, signed_in, reporter_email,
            created_at, github_issue_number
     FROM support_tickets
     ORDER BY created_at DESC
     LIMIT $1`,
    [LIST_LIMIT],
  );

  const ticketIds = ticketsResult.rows.map((r) => r.id);
  /** @type {Map<string, { kind: string, status: string }[]>} */
  const alertsByTicket = new Map();
  if (ticketIds.length > 0) {
    const outboxResult = await pool.query(
      `SELECT ticket_id, kind, status
       FROM support_outbox
       WHERE ticket_id = ANY($1::uuid[])
         AND status IN ('blocked', 'failed')`,
      [ticketIds],
    );
    for (const row of outboxResult.rows) {
      const list = alertsByTicket.get(row.ticket_id) || [];
      list.push({ kind: row.kind, status: row.status });
      alertsByTicket.set(row.ticket_id, list);
    }
  }

  return ticketsResult.rows.map((row) =>
    mapStaffTicketSummary({
      ...row,
      outbox_alerts: alertsByTicket.get(row.id) || [],
    }),
  );
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} ticketId
 */
export async function getSupportStaffTicketDetail(pool, ticketId) {
  const ticketResult = await pool.query(
    `SELECT id, reference, user_id, reporter_email, reporter_email_normalised,
            signed_in, submit_ip, category, title, description,
            expected, actual, steps, frequency, context, locale,
            created_at, github_issue_number
     FROM support_tickets
     WHERE id = $1`,
    [ticketId],
  );
  if (ticketResult.rows.length === 0) {
    return null;
  }

  const [attachmentsResult, outboxResult] = await Promise.all([
    pool.query(
      `SELECT id, mime, bytes, created_at
       FROM support_attachments
       WHERE ticket_id = $1
       ORDER BY created_at`,
      [ticketId],
    ),
    pool.query(
      `SELECT id, kind, status, attempts, github_issue_number, last_error,
              created_at, updated_at
       FROM support_outbox
       WHERE ticket_id = $1
       ORDER BY created_at`,
      [ticketId],
    ),
  ]);

  return {
    ticket: mapStaffTicketDetail(ticketResult.rows[0]),
    attachments: attachmentsResult.rows.map(mapStaffAttachment),
    outbox: outboxResult.rows.map(mapStaffOutboxRow),
  };
}
