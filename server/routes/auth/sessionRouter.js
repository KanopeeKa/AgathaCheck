import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

import { errorDetails } from '../../config/security.js';
import { isStrongPassword, isValidEmail, MIN_PASSWORD_LENGTH } from '../../config/validation.js';
import { linkExternalFostersByEmail } from '../../lib/orgPeople.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { logger } from '../../lib/logger.js';
import {
  extractToken,
  signAccessToken,
  signRefreshToken,
  userRowToMap,
  verifyToken,
} from './shared.js';

export function registerSessionRoutes(router, pool, { comparePassword, authLimiter }) {
  router.post('/signup', authLimiter, async (req, res) => {
    try {
      const { email, password, first_name = '', last_name = '', category = 'pet_guardian', bio = '', photo_url = '', locale = 'en' } = req.body;
      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required.' });
      }
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: 'Invalid email format.' });
      }
      if (!isStrongPassword(password)) {
        return res.status(400).json({ error: `Password must be at least ${MIN_PASSWORD_LENGTH} characters.` });
      }
      const id = uuidv4();
      const saltRounds = 10;
      const password_hash = await bcrypt.hash(password, saltRounds);
      let result;
      try {
        result = await pool.query(
          'INSERT INTO users (id, email, password_hash, first_name, last_name, category, bio, photo_url, locale) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id',
          [id, email, password_hash, first_name, last_name, category, bio, photo_url, locale]
        );
      } catch (err) {
        if (err.code === '23505') {
          return res.status(400).json({ error: 'Email already exists.' });
        }
        throw err;
      }
      const user = { id: result.rows[0].id, email, first_name, last_name, category, bio, photo_url, locale };
      await linkExternalFostersByEmail(pool, user.id, email);
      const accessToken = signAccessToken(user.id, user.email);
      const refreshToken = signRefreshToken(user.id, user.email);
      logAuditEventSafe(pool, {
        actorUserId: user.id,
        action: 'auth.signup',
        resourceType: 'user',
        resourceId: user.id,
        req,
      });
      res.status(201).json({ user, access_token: accessToken, refresh_token: refreshToken });
    } catch (err) {
      logger.error({ err }, 'signup error');
      res.status(500).json({ error: 'Signup failed', ...errorDetails(err) });
    }
  });

  router.post('/login', authLimiter, async (req, res) => {
    try {
      const { email, password } = req.body;
      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required.' });
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
      const user = userRowToMap(userRow);
      await linkExternalFostersByEmail(pool, user.id, user.email);
      const accessToken = signAccessToken(user.id, user.email);
      const refreshToken = signRefreshToken(user.id, user.email);
      logAuditEventSafe(pool, {
        actorUserId: user.id,
        action: 'auth.login',
        resourceType: 'user',
        resourceId: user.id,
        req,
      });
      res.status(200).json({ user, access_token: accessToken, refresh_token: refreshToken });
    } catch (err) {
      logger.error({ err }, 'login error');
      res.status(500).json({ error: 'Login failed', ...errorDetails(err) });
    }
  });

  router.post('/refresh', async (req, res) => {
    const { refresh_token } = req.body;
    if (!refresh_token) {
      return res.status(400).json({ error: 'refresh_token is required' });
    }
    try {
      const payload = verifyToken(refresh_token);
      const userResult = await pool.query('SELECT id FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid or expired refresh token' });
      }
      const accessToken = signAccessToken(payload.id, payload.email);
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'auth.token_refresh',
        resourceType: 'user',
        resourceId: payload.id,
        req,
      });
      res.status(200).json({ access_token: accessToken });
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired refresh token', ...errorDetails(err) });
    }
  });

  router.post('/logout', (req, res) => {
    const token = extractToken(req);
    if (token) {
      try {
        const payload = verifyToken(token);
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
    res.status(200).json({ message: 'Logged out' });
  });
}
