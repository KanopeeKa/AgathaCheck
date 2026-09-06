import bcrypt from 'bcrypt';
import { randomInt } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { errorDetails } from '../../config/security.js';
import { isStrongPassword, MIN_PASSWORD_LENGTH } from '../../config/validation.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import { isSmtpConfigured } from '../../config/mail.js';
import { sendPasswordResetEmail } from '../../services/mailService.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { revokeAllUserRefreshSessions } from '../../lib/refreshSessions.js';
import { extractToken, FORGOT_PASSWORD_MESSAGE, isProduction, verifyAccessToken } from './shared.js';

export function registerPasswordRoutes(router, pool, { comparePassword, authLimiter }) {
  router.post('/change-password', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyAccessToken(token);
      const { currentPassword, newPassword } = req.body;
      if (!currentPassword || !newPassword) {
        return res.status(400).json({ error: 'Current and new passwords are required' });
      }
      if (!isStrongPassword(newPassword)) {
        return res.status(400).json({ error: `Password must be at least ${MIN_PASSWORD_LENGTH} characters.` });
      }
      const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const valid = await comparePassword(currentPassword, userResult.rows[0].password_hash);
      if (!valid) {
        return res.status(400).json({ error: 'Current password is incorrect' });
      }
      const newHash = await bcrypt.hash(newPassword, 10);
      await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [newHash, payload.id]);
      await revokeAllUserRefreshSessions(pool, payload.id);
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'auth.password_changed',
        resourceType: 'user',
        resourceId: payload.id,
        req,
      });
      res.status(200).json({ message: 'Password changed successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Password change failed', ...errorDetails(err) });
    }
  });

  router.post('/forgot-password', authLimiter, async (req, res) => {
    try {
      const { email } = req.body;
      if (!email) {
        return res.status(400).json({ error: 'Email is required' });
      }
      const userResult = await pool.query('SELECT id, locale FROM users WHERE email = $1', [email]);
      if (userResult.rows.length === 0) {
        return res.status(200).json({ message: FORGOT_PASSWORD_MESSAGE });
      }
      const userId = userResult.rows[0].id;
      const locale = resolveEmailLocale(
        userResult.rows[0].locale,
        req.headers['accept-language']
      );
      const code = String(randomInt(100000, 1000000));
      const id = uuidv4();
      await pool.query(
        "INSERT INTO password_reset_tokens (id, user_id, code, expires_at) VALUES ($1, $2, $3, NOW() + INTERVAL '15 minutes')",
        [id, userId, code]
      );
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'auth.password_reset_requested',
        resourceType: 'user',
        resourceId: userId,
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
    } catch (err) {
      return res.status(500).json({ error: 'Request failed', ...errorDetails(err) });
    }
  });

  router.post('/reset-password', authLimiter, async (req, res) => {
    try {
      const { email, code, new_password } = req.body;
      if (!email || !code || !new_password) {
        return res.status(400).json({ error: 'Email, code, and new_password are required' });
      }
      if (!isStrongPassword(new_password)) {
        return res.status(400).json({ error: `Password must be at least ${MIN_PASSWORD_LENGTH} characters.` });
      }
      const result = await pool.query(
        `SELECT prt.id, prt.user_id FROM password_reset_tokens prt
         JOIN users u ON u.id = prt.user_id
         WHERE u.email = $1 AND prt.code = $2 AND prt.used = false AND prt.expires_at > NOW()
         ORDER BY prt.created_at DESC LIMIT 1`,
        [email, code]
      );
      if (result.rows.length === 0) {
        return res.status(400).json({ error: 'Invalid or expired reset code' });
      }
      const { id: tokenId, user_id: userId } = result.rows[0];
      const newHash = await bcrypt.hash(new_password, 10);
      await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [newHash, userId]);
      await revokeAllUserRefreshSessions(pool, userId);
      await pool.query('UPDATE password_reset_tokens SET used = true WHERE id = $1', [tokenId]);
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'auth.password_reset_completed',
        resourceType: 'user',
        resourceId: userId,
        req,
      });
      res.status(200).json({ message: 'Password has been reset successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Reset failed', ...errorDetails(err) });
    }
  });
}
