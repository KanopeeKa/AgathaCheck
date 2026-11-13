import { normalizeSupportReporterEmail } from '../submit/normalizeReporterEmail.js';
import { purgeSupportTickets } from './purgeTickets.js';

/**
 * Account erasure hook (R-019) — run inside the erasure transaction before the user row is deleted.
 *
 * @param {import('pg').PoolClient} client
 * @param {{ userId: string, userEmail: string, operationId: string }} params
 */
export async function purgeSupportTicketsForAccountErasure(client, { userId, userEmail, operationId }) {
  const emailNorm = normalizeSupportReporterEmail(userEmail);
  const found = await client.query(
    `SELECT id FROM support_tickets
     WHERE user_id = $1
        OR ($2 <> '' AND reporter_email_normalised = $2)`,
    [userId, emailNorm],
  );
  const ticketIds = found.rows.map((row) => row.id);
  return purgeSupportTickets(client, ticketIds, operationId);
}
