import bcrypt from 'bcrypt';

import { errorDetails } from '../../config/security.js';
import { isStrongPassword, MIN_PASSWORD_LENGTH } from '../../config/validation.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import {
  readRefreshTokenFromRequest,
  setRefreshTokenCookie,
} from '../../lib/authCookies.js';
import {
  emitAccountPasswordChanged,
  resolveAccountNewSignInNotifications,
} from '../../lib/account/accountSecurityNotifications.js';
import {
  lookupRefreshSessionFromToken,
  revokeOtherUserRefreshSessions,
} from '../../lib/refreshSessions.js';
import { verifyAccessToken } from '../../lib/auth/tokens.js';
import { extractToken } from './shared.js';

export function registerSecureAccountRoutes(router, pool, { comparePassword, authLimiter }) {
  router.post('/secure-account', authLimiter, async (req, res) => {
    const accessToken = extractToken(req);
    const refreshToken = readRefreshTokenFromRequest(req);
    if (!accessToken || !refreshToken) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    try {
      const accessPayload = verifyAccessToken(accessToken);
      const lookup = await lookupRefreshSessionFromToken(pool, refreshToken);
      if (!lookup || lookup.session.revoked_at) {
        return res.status(401).json({ error: 'Invalid or expired refresh token' });
      }
      if (lookup.payload.id !== accessPayload.id) {
        return res.status(401).json({ error: 'Session mismatch' });
      }

      const { newPassword, currentPassword, notification_id: notificationId } = req.body;
      if (!newPassword || !currentPassword) {
        return res.status(400).json({ error: 'Current and new passwords are required' });
      }
      if (!isStrongPassword(newPassword)) {
        return res.status(400).json({
          error: `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`,
        });
      }

      const userResult = await pool.query(
        'SELECT password_hash, email FROM users WHERE id = $1',
        [accessPayload.id],
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const { password_hash: passwordHash, email } = userResult.rows[0];
      const valid = await comparePassword(currentPassword, passwordHash);
      if (!valid) {
        return res.status(400).json({ error: 'Current password is incorrect' });
      }

      const familyId = lookup.session.family_id;
      await revokeOtherUserRefreshSessions(pool, accessPayload.id, familyId);

      const newHash = await bcrypt.hash(newPassword, 10);
      await pool.query(
        'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
        [newHash, accessPayload.id],
      );

      await resolveAccountNewSignInNotifications(
        pool,
        accessPayload.id,
        notificationId || null,
      );

      await emitAccountPasswordChanged(pool, {
        userId: accessPayload.id,
        email,
      });

      logAuditEventSafe(pool, {
        actorUserId: accessPayload.id,
        action: 'auth.secure_account_completed',
        resourceType: 'user',
        resourceId: accessPayload.id,
        req,
      });

      setRefreshTokenCookie(res, refreshToken);
      res.status(200).json({ message: 'Account secured successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Secure account failed', ...errorDetails(err) });
    }
  });
}
