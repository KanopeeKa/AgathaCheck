/**
 * F-04: share link expiry + revoke legacy unclaimed links (A7).
 * @param {import('pg').PoolClient} client
 */
export async function migrateShareLinkExpiry(client) {
  await client.query(`
    UPDATE pet_share_links
       SET status = 'revoked'
     WHERE status = 'pending'
       AND claimed_by IS NULL
       AND expires_at IS NULL
  `);
}
