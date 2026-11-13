import { v4 as uuidv4 } from 'uuid';

import { withTransaction } from '../../db/withTransaction.js';
import { normalizeSupportReporterEmail } from './normalizeReporterEmail.js';
import { generateSupportTicketReference } from './reference.js';
import { checkSupportSubmitRateLimits } from './rateLimit.js';

/**
 * @param {import('pg').Pool} pool
 * @param {{
 *   signedIn: boolean,
 *   userId: string | null,
 *   accountEmail: string | null,
 *   body: object,
 *   clientIp: string,
 * }} input
 */
export async function createSupportTicket(pool, input) {
  const reporterEmail = input.signedIn ? input.accountEmail : input.body.email;
  const emailNormalized = normalizeSupportReporterEmail(reporterEmail);

  return withTransaction(pool, async (client) => {
    const rate = await checkSupportSubmitRateLimits(client, {
      signedIn: input.signedIn,
      userId: input.userId,
      emailNormalized,
      clientIp: input.clientIp,
    });
    if (rate.limited) {
      return { error: 'rate_limited', retryAfter: rate.retryAfter };
    }

    let reference = generateSupportTicketReference();
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const ticketId = uuidv4();
      try {
        await client.query(
          `INSERT INTO support_tickets (
            id, reference, user_id, reporter_email, reporter_email_normalised,
            signed_in, submit_ip, category, title, description,
            expected, actual, steps, frequency, context, locale
          ) VALUES (
            $1, $2, $3, $4, $5,
            $6, $7, $8, $9, $10,
            $11, $12, $13, $14, $15::jsonb, $16
          )`,
          [
            ticketId,
            reference,
            input.signedIn ? input.userId : null,
            reporterEmail,
            emailNormalized,
            input.signedIn,
            input.signedIn ? null : input.clientIp,
            input.body.category,
            input.body.title,
            input.body.description,
            input.body.expected,
            input.body.actual,
            input.body.steps,
            input.body.frequency,
            JSON.stringify(input.body.context),
            input.body.locale,
          ],
        );

        const receiptId = uuidv4();
        const issueId = uuidv4();
        await client.query(
          `INSERT INTO support_outbox (id, ticket_id, kind, status)
           VALUES ($1, $2, 'receipt', 'pending'),
                  ($3, $2, 'github_issue', 'pending')`,
          [receiptId, ticketId, issueId],
        );

        return { reference };
      } catch (err) {
        if (err?.code === '23505' && String(err.constraint || '').includes('reference')) {
          reference = generateSupportTicketReference();
          continue;
        }
        throw err;
      }
    }
    throw new Error('Could not allocate support ticket reference');
  });
}
