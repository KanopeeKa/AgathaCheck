import { isSmtpConfigured } from '../../config/mail.js';
import { isProduction } from '../auth/runtime.js';
import { sendTransactionalEmail } from '../../services/mailService.js';
import {
  NOTIFICATION_KIND_ACCOUNT,
  NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
  NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
  NOTIFICATION_TYPE_ACCOUNT_SESSIONS_REVOKED,
} from '../notificationKind.js';
import { createNotification } from '../notificationHelper.js';
import { maskEmailForNotice } from './maskEmail.js';
import { sendAccountSecurityPushToOtherDevices } from './accountSecurityPush.js';

/** FR-ACC / spec §3.5 — A2 optional inline Secure my account window. */
export const ACCOUNT_PASSWORD_CHANGED_INLINE_DAYS = 7;

function formatSignInTime(date) {
  return date.toISOString().replace('T', ' ').slice(0, 16);
}

function buildNewSignInCopy(deviceLabel, signedInAt) {
  const when = formatSignInTime(signedInAt);
  return {
    title: 'New sign-in to your account',
    message: `New sign-in to your account: ${deviceLabel}, ${when}`,
  };
}

/**
 * @param {import('pg').Pool} pool
 */
export async function emitAccountNewSignIn(pool, {
  userId,
  email,
  deviceLabel,
  signedInAt = new Date(),
  excludeSessionFamilyId = null,
}) {
  const copy = buildNewSignInCopy(deviceLabel, signedInAt);
  await createNotification(pool, {
    userId,
    title: copy.title,
    message: copy.message,
    type: NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
    kind: NOTIFICATION_KIND_ACCOUNT,
  });

  const masked = maskEmailForNotice(email);
  const emailSubject = copy.title;
  const emailText = `${copy.message}\n\nAccount: ${masked}\n\nOpen the AgathaTrack app to review this sign-in. Do not use links in email to sign in.`;
  const emailHtml = `<p>${copy.message}</p><p>Account: ${masked}</p><p>Open the AgathaTrack app to review this sign-in.</p>`;
  await sendAccountSecurityEmail(email, emailSubject, emailText, emailHtml);

  await sendAccountSecurityPushToOtherDevices({
    userId,
    title: copy.title,
    body: copy.message,
    excludeSessionFamilyId,
  });
}

export async function emitAccountPasswordChanged(pool, { userId, email }) {
  const title = 'Your password was changed';
  const message = 'Your password was changed';
  await createNotification(pool, {
    userId,
    title,
    message,
    type: NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
    kind: NOTIFICATION_KIND_ACCOUNT,
  });
  const masked = maskEmailForNotice(email);
  await sendAccountSecurityEmail(
    email,
    title,
    `${message}\n\nAccount: ${masked}\n\nIf you did not make this change, open the app and use Secure my account.`,
    `<p>${message}</p><p>Account: ${masked}</p>`,
  );
}

export async function emitAccountSessionsRevoked(pool, { userId, email }) {
  const title = 'For your security, we signed you out on all devices';
  const message = title;
  await createNotification(pool, {
    userId,
    title,
    message,
    type: NOTIFICATION_TYPE_ACCOUNT_SESSIONS_REVOKED,
    kind: NOTIFICATION_KIND_ACCOUNT,
  });
  const masked = maskEmailForNotice(email);
  await sendAccountSecurityEmail(
    email,
    title,
    `${message}\n\nAccount: ${masked}`,
    `<p>${message}</p><p>Account: ${masked}</p>`,
  );
}

/** A6 — email only; no inbox row (FR-ACC-9). */
export async function emitAccountDeletionRequestedEmail({ email }) {
  const title = 'Your account and data will be deleted';
  const message = 'Your account and data will be deleted. This can\'t be undone.';
  const masked = maskEmailForNotice(email);
  await sendAccountSecurityEmail(
    email,
    title,
    `${message}\n\nAccount: ${masked}`,
    `<p>${message}</p><p>Account: ${masked}</p>`,
  );
}

async function sendAccountSecurityEmail(to, subject, text, html) {
  if (!to) return;
  if (!isProduction() && !isSmtpConfigured()) {
    return;
  }
  try {
    await sendTransactionalEmail({ to, subject, text, html });
  } catch (_) {
    // Email failure must not block auth flows.
  }
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @param {string} notificationId
 * @param {'this_was_me' | 'start_secure_flow'} action
 */
function isWithinPasswordChangedInlineWindow(createdAt) {
  if (!createdAt) return false;
  const created = createdAt instanceof Date ? createdAt : new Date(createdAt);
  const ageMs = Date.now() - created.getTime();
  return ageMs >= 0 && ageMs <= ACCOUNT_PASSWORD_CHANGED_INLINE_DAYS * 24 * 60 * 60 * 1000;
}

export async function applyAccountSecurityFeedback(pool, userId, notificationId, action) {
  const result = await pool.query(
    `SELECT id, type, kind, resolved_at, created_at
       FROM notifications
      WHERE id = $1 AND user_id = $2 AND archived_at IS NULL`,
    [notificationId, userId],
  );
  if (result.rows.length === 0) {
    return { status: 404, error: 'Notification not found' };
  }
  const row = result.rows[0];
  if (row.kind !== NOTIFICATION_KIND_ACCOUNT) {
    return { status: 400, error: 'Not an account security notification' };
  }
  const allowedTypes = new Set([
    NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
    NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
  ]);
  if (!allowedTypes.has(row.type)) {
    return { status: 400, error: 'Notification does not support this action' };
  }
  if (row.type === NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED) {
    if (action === 'this_was_me') {
      return { status: 400, error: 'Action not supported for this notification' };
    }
    if (!isWithinPasswordChangedInlineWindow(row.created_at)) {
      return { status: 400, error: 'Secure my account is no longer available for this notice' };
    }
  }
  if (action === 'this_was_me') {
    if (!row.resolved_at) {
      await pool.query(
        'UPDATE notifications SET resolved_at = NOW() WHERE id = $1 AND user_id = $2',
        [notificationId, userId],
      );
    }
    return { status: 200, body: { success: true, action } };
  }
  if (action === 'start_secure_flow') {
    return { status: 200, body: { success: true, action, secure_account: true } };
  }
  return { status: 400, error: 'Invalid action' };
}

/**
 * Resolve open A1 rows after secure-account completes.
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @param {string | null} notificationId
 */
export async function resolveAccountNewSignInNotifications(pool, userId, notificationId = null) {
  await resolveAccountSecurityNotificationsOnSecureAccount(pool, userId, notificationId);
}

/**
 * Resolve triggering A1/A2 rows after secure-account completes (AC-ACS-3).
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @param {string | null} notificationId
 */
export async function resolveAccountSecurityNotificationsOnSecureAccount(
  pool,
  userId,
  notificationId = null,
) {
  const types = [
    NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
    NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
  ];
  if (notificationId) {
    await pool.query(
      `UPDATE notifications
          SET resolved_at = NOW()
        WHERE id = $1 AND user_id = $2 AND type = ANY($3::text[]) AND resolved_at IS NULL`,
      [notificationId, userId, types],
    );
    return;
  }
  await pool.query(
    `UPDATE notifications
        SET resolved_at = NOW()
      WHERE user_id = $1 AND type = ANY($2::text[]) AND resolved_at IS NULL`,
    [userId, types],
  );
}
