import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

import { errorDetails } from '../../config/security.js';
import { isStrongPassword, isValidEmail, MIN_PASSWORD_LENGTH } from '../../config/validation.js';
import { linkExternalFostersByEmail } from '../../lib/orgPeople.js';
import { normalizeTimezoneInput, resolveTimezoneOrDefault } from '../../lib/timezone.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import {
  clearRefreshTokenCookie,
  readRefreshTokenFromRequest,
  setRefreshTokenCookie,
} from '../../lib/authCookies.js';
import { captureDeviceLabelAfterAuth } from '../../lib/account/accountSecuritySession.js';
import { emitAccountSessionsRevoked } from '../../lib/account/accountSecurityNotifications.js';
import {
  issueTokenPair,
  RefreshSessionError,
  revokeAllUserRefreshSessions,
  rotateRefreshToken,
} from '../../lib/refreshSessions.js';
import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { ValidationError } from '../../lib/http/errors.js';
import { verifyAccessToken, verifyRefreshToken } from '../../lib/auth/tokens.js';
import { userRowToMap } from './shared.js';

export function registerSessionRoutes(router, pool, { comparePassword, authLimiter }) {
  router.post(
    '/signup',
    authLimiter,
    asyncHandler(
      async (req, res) => {
        const {
          email,
          password,
          first_name = '',
          last_name = '',
          category = 'pet_carer',
          bio = '',
          photo_url = '',
          locale = 'en',
          timezone: rawTimezone,
        } = req.body;
        if (!email || !password) {
          throw new ValidationError('Email and password are required.');
        }
        if (!isValidEmail(email)) {
          throw new ValidationError('Invalid email format.');
        }
        if (!isStrongPassword(password)) {
          throw new ValidationError(`Password must be at least ${MIN_PASSWORD_LENGTH} characters.`);
        }
        const id = uuidv4();
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);
        const timezone = resolveTimezoneOrDefault(rawTimezone);
        let result;
        try {
          result = await pool.query(
            'INSERT INTO users (id, email, password_hash, first_name, last_name, category, bio, photo_url, locale, timezone) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id',
            [id, email, password_hash, first_name, last_name, category, bio, photo_url, locale, timezone],
          );
        } catch (err) {
          if (err.code === '23505') {
            throw new ValidationError('Email already exists.');
          }
          throw err;
        }
        const user = {
          id: result.rows[0].id,
          email,
          first_name,
          last_name,
          category,
          bio,
          photo_url,
          locale,
        };
        await linkExternalFostersByEmail(pool, user.id, email);
        const { accessToken, refreshToken, familyId } = await issueTokenPair(pool, user.id, user.email);
        await captureDeviceLabelAfterAuth(pool, req, {
          userId: user.id,
          email: user.email,
          sessionFamilyId: familyId,
          isSignupSession: true,
        });
        logAuditEventSafe(pool, {
          actorUserId: user.id,
          action: 'auth.signup',
          resourceType: 'user',
          resourceId: user.id,
          req,
        });
        setRefreshTokenCookie(res, refreshToken);
        res.status(201).json({ user, access_token: accessToken, refresh_token: refreshToken });
      },
      { prodMessage: 'Signup failed' },
    ),
  );

  router.post(
    '/login',
    authLimiter,
    asyncHandler(
      async (req, res) => {
        const { email, password } = req.body;
        if (!email || !password) {
          throw new ValidationError('Email and password are required.');
        }
        const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
          logAuditEventSafe(pool, {
            action: 'auth.login_failed',
            resourceType: 'user',
            outcome: 'failure',
            metadata: { reason: 'unknown_email' },
            req,
          });
          return res.status(401).json({ error: 'Invalid email or password.' });
        }
        const userRow = userResult.rows[0];
        const valid = await comparePassword(password, userRow.password_hash);
        if (!valid) {
          logAuditEventSafe(pool, {
            actorUserId: userRow.id,
            action: 'auth.login_failed',
            resourceType: 'user',
            resourceId: userRow.id,
            outcome: 'failure',
            metadata: { reason: 'invalid_password' },
            req,
          });
          return res.status(401).json({ error: 'Invalid email or password.' });
        }
        const loginTimezone = normalizeTimezoneInput(req.body?.timezone);
        if (loginTimezone) {
          await pool.query(
            'UPDATE users SET timezone = $1, updated_at = NOW() WHERE id = $2',
            [loginTimezone, userRow.id],
          );
          userRow.timezone = loginTimezone;
        }
        const user = userRowToMap(userRow);
        await linkExternalFostersByEmail(pool, user.id, user.email);
        const { accessToken, refreshToken, familyId } = await issueTokenPair(pool, user.id, user.email);
        await captureDeviceLabelAfterAuth(pool, req, {
          userId: user.id,
          email: user.email,
          sessionFamilyId: familyId,
          isSignupSession: false,
        });
        logAuditEventSafe(pool, {
          actorUserId: user.id,
          action: 'auth.login',
          resourceType: 'user',
          resourceId: user.id,
          req,
        });
        setRefreshTokenCookie(res, refreshToken);
        res.status(200).json({ user, access_token: accessToken, refresh_token: refreshToken });
      },
      { prodMessage: 'Login failed' },
    ),
  );

  router.post(
    '/refresh',
    asyncHandler(async (req, res) => {
      const refresh_token = readRefreshTokenFromRequest(req);
      if (!refresh_token) {
        throw new ValidationError('refresh_token is required');
      }
      try {
        const prePayload = verifyRefreshToken(refresh_token);
        const userResult = await pool.query('SELECT id FROM users WHERE id = $1', [prePayload.id]);
        if (userResult.rows.length === 0) {
          return res.status(401).json({ error: 'Invalid or expired refresh token' });
        }
        const { accessToken, refreshToken, familyId } = await rotateRefreshToken(pool, refresh_token);
        const userEmailResult = await pool.query('SELECT email FROM users WHERE id = $1', [prePayload.id]);
        const email = userEmailResult.rows[0]?.email || prePayload.email;
        await captureDeviceLabelAfterAuth(pool, req, {
          userId: prePayload.id,
          email,
          sessionFamilyId: familyId,
          isSignupSession: false,
        });
        logAuditEventSafe(pool, {
          actorUserId: prePayload.id,
          action: 'auth.token_refresh',
          resourceType: 'user',
          resourceId: prePayload.id,
          req,
        });
        setRefreshTokenCookie(res, refreshToken);
        res.status(200).json({ access_token: accessToken, refresh_token: refreshToken });
      } catch (err) {
        if (err instanceof RefreshSessionError && err.code === 'reuse') {
          try {
            const prePayload = verifyRefreshToken(refresh_token);
            const reuseUserResult = await pool.query('SELECT email FROM users WHERE id = $1', [
              prePayload.id,
            ]);
            if (reuseUserResult.rows.length > 0) {
              await emitAccountSessionsRevoked(pool, {
                userId: prePayload.id,
                email: reuseUserResult.rows[0].email,
              });
            }
          } catch (_) {
            // Best-effort A3 while rejecting reuse.
          }
        }
        return res.status(401).json({ error: 'Invalid or expired refresh token', ...errorDetails(err) });
      }
    }),
  );

  router.post(
    '/logout',
    asyncHandler(async (req, res) => {
      const auth = req.headers['authorization'] || req.headers['Authorization'];
      const token = auth?.startsWith('Bearer ') ? auth.substring(7) : null;
      if (token) {
        try {
          const payload = verifyAccessToken(token);
          await revokeAllUserRefreshSessions(pool, payload.id);
          logAuditEventSafe(pool, {
            actorUserId: payload.id,
            action: 'auth.logout',
            resourceType: 'user',
            resourceId: payload.id,
            req,
          });
        } catch (_) {
          // Ignore invalid tokens on logout.
        }
      }
      clearRefreshTokenCookie(res);
      res.status(200).json({ message: 'Logged out' });
    }),
  );
}
