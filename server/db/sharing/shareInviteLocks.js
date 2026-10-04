import crypto from 'crypto';

/**
 * Transaction-scoped advisory lock key for invite creation per (inviter, invitee email).
 * @param {string} inviterUserId
 * @param {string} inviteeEmail normalized lower-case email
 * @returns {bigint}
 */
export function shareInviteCreateLockKey(inviterUserId, inviteeEmail) {
  const digest = crypto
    .createHash('sha256')
    .update(`${inviterUserId}\0${String(inviteeEmail).toLowerCase()}`)
    .digest();
  return digest.readBigInt64BE(0);
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} inviterUserId
 * @param {string} inviteeEmail
 */
export async function lockShareInviteCreate(client, inviterUserId, inviteeEmail) {
  const key = shareInviteCreateLockKey(inviterUserId, inviteeEmail);
  await client.query('SELECT pg_advisory_xact_lock($1::bigint)', [key.toString()]);
}
