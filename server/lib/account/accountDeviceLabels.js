import { v4 as uuidv4 } from 'uuid';

import { emitAccountNewSignIn } from './accountSecurityNotifications.js';
import {
  PREF_DEVICE_SECURITY_INTRO_PENDING,
  upsertNotificationPreference,
} from '../notificationPreferences.js';

const NINETY_DAYS_MS = 90 * 24 * 60 * 60 * 1000;

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} userId
 */
async function countDeviceLabels(db, userId) {
  const result = await db.query(
    'SELECT COUNT(*)::int AS count FROM account_device_labels WHERE user_id = $1',
    [userId],
  );
  return result.rows[0]?.count ?? 0;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} userId
 * @param {string} label
 */
async function findDeviceLabel(db, userId, label) {
  const result = await db.query(
    `SELECT id, label, first_seen_at, last_seen_at, session_family_id
       FROM account_device_labels
      WHERE user_id = $1 AND label = $2`,
    [userId, label],
  );
  return result.rows[0] ?? null;
}

/**
 * Record sign-in device label and emit A1 when rules match (FR-ACC-3).
 * @param {import('pg').Pool} pool
 * @param {{
 *   userId: string,
 *   email: string,
 *   label: string,
 *   sessionFamilyId?: string | null,
 *   isSignupSession?: boolean,
 *   excludeSessionFamilyIdForPush?: string | null,
 * }} params
 */
export async function recordAccountDeviceSignIn(pool, {
  userId,
  email,
  label,
  sessionFamilyId = null,
  isSignupSession = false,
  excludeSessionFamilyIdForPush = null,
}) {
  const existingBefore = await findDeviceLabel(pool, userId, label);
  const hadAnyLabels = (await countDeviceLabels(pool, userId)) > 0;

  const now = new Date();
  if (existingBefore) {
    await pool.query(
      `UPDATE account_device_labels
          SET last_seen_at = $1,
              session_family_id = COALESCE($2, session_family_id)
        WHERE id = $3`,
      [now, sessionFamilyId, existingBefore.id],
    );
  } else {
    await pool.query(
      `INSERT INTO account_device_labels (id, user_id, label, first_seen_at, last_seen_at, session_family_id)
       VALUES ($1, $2, $3, $4, $4, $5)`,
      [uuidv4(), userId, label, now, sessionFamilyId],
    );
  }

  const legacySilentBootstrap =
    !isSignupSession && !hadAnyLabels && !existingBefore;
  if (legacySilentBootstrap) {
    await upsertNotificationPreference(
      pool,
      userId,
      PREF_DEVICE_SECURITY_INTRO_PENDING,
      'true',
    );
  }

  if (isSignupSession || !hadAnyLabels) {
    return { emittedA1: false, legacySilentBootstrap };
  }

  const lastSeen = existingBefore?.last_seen_at
    ? new Date(existingBefore.last_seen_at)
    : null;
  const seenWithin90Days = lastSeen && (now.getTime() - lastSeen.getTime()) < NINETY_DAYS_MS;
  if (existingBefore && seenWithin90Days) {
    return { emittedA1: false, legacySilentBootstrap: false };
  }

  await emitAccountNewSignIn(pool, {
    userId,
    email,
    deviceLabel: label,
    signedInAt: now,
    excludeSessionFamilyId: excludeSessionFamilyIdForPush ?? sessionFamilyId,
  });
  return { emittedA1: true, legacySilentBootstrap: false };
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} client
 * @param {string} userId
 */
export async function deleteAccountDeviceLabelsForUser(client, userId) {
  await client.query('DELETE FROM account_device_labels WHERE user_id = $1', [userId]);
}
