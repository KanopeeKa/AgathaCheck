import { withTransaction } from '../../db/withTransaction.js';
import {
  SUPPORT_SCREENSHOT_RETENTION_SQL,
  SUPPORT_TICKET_RETENTION_SQL,
} from './constants.js';
import { enqueueSupportAttachmentDelete } from './enqueueAttachmentDelete.js';
import { purgeSupportTickets } from './purgeTickets.js';

/**
 * Daily retention (D-007): screenshots 90 days, tickets 12 months.
 *
 * @param {import('pg').Pool} pool
 * @param {{ batchLimit?: number }} [options]
 */
export async function runSupportRetentionSweep(pool, { batchLimit = 200 } = {}) {
  const stats = { screenshotsPurged: 0, ticketsPurged: 0 };

  const oldAttachments = await pool.query(
    `SELECT id, storage_key FROM support_attachments
     WHERE created_at < ${SUPPORT_SCREENSHOT_RETENTION_SQL}
     ORDER BY created_at ASC
     LIMIT $1`,
    [batchLimit],
  );

  if (oldAttachments.rows.length > 0) {
    await withTransaction(pool, async (client) => {
      for (const row of oldAttachments.rows) {
        await enqueueSupportAttachmentDelete(client, row.storage_key, null);
        await client.query('DELETE FROM support_attachments WHERE id = $1', [row.id]);
        stats.screenshotsPurged += 1;
      }
    });
  }

  const expiredTickets = await pool.query(
    `SELECT id FROM support_tickets
     WHERE created_at < ${SUPPORT_TICKET_RETENTION_SQL}
     ORDER BY created_at ASC
     LIMIT $1`,
    [batchLimit],
  );
  const ticketIds = expiredTickets.rows.map((row) => row.id);
  if (ticketIds.length > 0) {
    await withTransaction(pool, async (client) => {
      const result = await purgeSupportTickets(client, ticketIds, null);
      stats.ticketsPurged = result.ticketIds.length;
    });
  }

  return stats;
}
