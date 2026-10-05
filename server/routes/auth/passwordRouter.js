import bcrypt from 'bcrypt';
import { randomInt } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { isStrongPassword, MIN_PASSWORD_LENGTH } from '../../config/validation.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import { isSmtpConfigured } from '../../config/mail.js';
import { sendPasswordResetEmail } from '../../services/mailService.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { emitAccountPasswordChanged } from '../../lib/account/accountSecurityNotifications.js';
import { revokeAllUserRefreshSessions } from '../../lib/refreshSessions.js';
import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { NotFoundError, ValidationError } from '../../lib/http/errors.js';
import { requireAuth } from '../../lib/requireAuth.js';
import { FORGOT_PASSWORD_MESSAGE, isProduction } from './shared.js';

export function registerPasswordRoutes(router, pool, { comparePassword, authLimiter }) {
  router.post(
    '/change-password',
    requireAuth,
    asyncHandler(
      async (req, res) => {
        const userId = req.principal.id;
        const { currentPassword, newPassword } = req.body;
        if (!currentPassword || !newPassword) {
          throw new ValidationError('Current and new passwords are required');
        }
        if (!isStrongPassword(newPassword)) {
          throw new ValidationError(`Password must be at least ${MIN_PASSWORD_LENGTH} characters.`);
        }
        const userResult = await pool.query('SELECT password_hash, email FROM users WHERE id = $1', [
          userId,
        ]);
        if (userResult.rows.length === 0) {
          throw new NotFoundError('User not found');
        }
        const valid = await comparePassword(currentPassword, userResult.rows[0].password_hash);
        if (!valid) {
          throw new ValidationError('Current password is incorrect');
        }
        const newHash = await bcrypt.hash(newPassword, 10);
        await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [
          newHash,
          userId,
        ]);
        await emitAccountPasswordChanged(pool, {
          userId,
          email: userResult.rows[0].email,
        });
        await revokeAllUserRefreshSessions(pool, userId);
        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'auth.password_changed',
          resourceType: 'user',
          resourceId: userId,
          req,
        });
        res.status(200).json({ message: 'Password changed successfully' });
      },
      { prodMessage: 'Password change failed' },
    ),
  );

  router.post(
    '/forgot-password',
    authLimiter,
    asyncHandler(
      async (req, res) => {
        const { email } = req.body;
        if (!email) {
          throw new ValidationError('Email is required');
        }
        const userResult = await pool.query('SELECT id, locale FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
          return res.status(200).json({ message: FORGOT_PASSWORD_MESSAGE });
        }
        const forgotUserId = userResult.rows[0].id;
        const locale = resolveEmailLocale(
          userResult.rows[0].locale,
          req.headers['accept-language'],
        );
        const code = String(randomInt(100000, 1000000));
        const id = uuidv4();
        await pool.query(
          "INSERT INTO password_reset_tokens (id, user_id, code, expires_at) VALUES ($1, $2, $3, NOW() + INTERVAL '15 minutes')",
          [id, forgotUserId, code],
        );
        logAuditEventSafe(pool, {
          actorUserId: forgotUserId,
          action: 'auth.password_reset_requested',
          resourceType: 'user',
          resourceId: forgotUserId,
          req,
        });
        if (isProduction() || isSmtpConfigured()) {
          try {
            await sendPasswordResetEmail(email, code, locale);
          } catch (mailErr) {
            try {
              await pool.query('DELETE FROM password_reset_tokens WHERE id = $1', [id]);
            } catch (deleteErr) {
              console.error('Failed to remove password reset token after email failure.', deleteErr);
            }
            console.error('Password reset email failed.', mailErr);
            return res.status(200).json({ message: FORGOT_PASSWORD_MESSAGE });
          }
        }
        const body = { message: FORGOT_PASSWORD_MESSAGE };
        if (!isProduction()) {
          console.log(`Password reset code for ${email}: ${code}`);
          body.code = code;
        }
        res.status(200).json(body);
      },
      { prodMessage: 'Request failed' },
    ),
  );

  router.post(
    '/reset-password',
    authLimiter,
    asyncHandler(
      async (req, res) => {
        const { email, code, new_password } = req.body;
        if (!email || !code || !new_password) {
          throw new ValidationError('Email, code, and new_password are required');
        }
        if (!isStrongPassword(new_password)) {
          throw new ValidationError(`Password must be at least ${MIN_PASSWORD_LENGTH} characters.`);
        }
        const result = await pool.query(
          `SELECT prt.id, prt.user_id FROM password_reset_tokens prt
         JOIN users u ON u.id = prt.user_id
         WHERE u.email = $1 AND prt.code = $2 AND prt.used = false AND prt.expires_at > NOW()
         ORDER BY prt.created_at DESC LIMIT 1`,
          [email, code],
        );
        if (result.rows.length === 0) {
          throw new ValidationError('Invalid or expired reset code');
        }
        const { id: tokenId, user_id: resetUserId } = result.rows[0];
        const emailRow = await pool.query('SELECT email FROM users WHERE id = $1', [resetUserId]);
        const newHash = await bcrypt.hash(new_password, 10);
        await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [
          newHash,
          resetUserId,
        ]);
        if (emailRow.rows[0]?.email) {
          await emitAccountPasswordChanged(pool, {
            userId: resetUserId,
            email: emailRow.rows[0].email,
          });
        }
        await revokeAllUserRefreshSessions(pool, resetUserId);
        await pool.query('UPDATE password_reset_tokens SET used = true WHERE id = $1', [tokenId]);
        logAuditEventSafe(pool, {
          actorUserId: resetUserId,
          action: 'auth.password_reset_completed',
          resourceType: 'user',
          resourceId: resetUserId,
          req,
        });
        res.status(200).json({ message: 'Password has been reset successfully' });
      },
      { prodMessage: 'Reset failed' },
    ),
  );
}
