import express from 'express';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { errorDetails } from '../config/security.js';

function signAccessToken(id, email) {
  return jwt.sign({ id, email }, JWT_SECRET, { expiresIn: '30m' });
}

function signRefreshToken(id, email) {
  return jwt.sign({ id, email }, JWT_SECRET, { expiresIn: '30d' });
}

function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

function extractToken(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
}

function userRowToMap(row) {
  return {
    id: row.id,
    email: row.email,
    first_name: row.first_name || '',
    last_name: row.last_name || '',
    category: row.category || 'pet_guardian',
    bio: row.bio || '',
    photo_url: row.photo_url || '',
    locale: row.locale || 'en',
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export default function authRoutes(pool, comparePassword) {
  const router = express.Router();
  const _comparePassword = comparePassword || bcrypt.compare;

  router.post('/signup', async (req, res) => {
    try {
      const { email, password, first_name = '', last_name = '', category = 'pet_guardian', bio = '', photo_url = '', locale = 'en' } = req.body;
      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required.' });
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
      const accessToken = signAccessToken(user.id, user.email);
      const refreshToken = signRefreshToken(user.id, user.email);
      res.status(201).json({ user, access_token: accessToken, refresh_token: refreshToken });
    } catch (err) {
      console.error('Signup error:', err);
      res.status(500).json({ error: 'Signup failed', ...errorDetails(err) });
    }
  });

  router.post('/login', async (req, res) => {
    try {
      const { email, password } = req.body;
      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required.' });
      }
      const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      if (userResult.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }
      const userRow = userResult.rows[0];
      const valid = await _comparePassword(password, userRow.password_hash);
      if (!valid) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }
      const user = userRowToMap(userRow);
      const accessToken = signAccessToken(user.id, user.email);
      const refreshToken = signRefreshToken(user.id, user.email);
      res.status(200).json({ user, access_token: accessToken, refresh_token: refreshToken });
    } catch (err) {
      console.error('Login error:', err);
      res.status(500).json({ error: 'Login failed', ...errorDetails(err) });
    }
  });

  router.post('/refresh', (req, res) => {
    const { refresh_token } = req.body;
    if (!refresh_token) {
      return res.status(400).json({ error: 'refresh_token is required' });
    }
    try {
      const payload = verifyToken(refresh_token);
      const accessToken = signAccessToken(payload.id, payload.email);
      res.status(200).json({ access_token: accessToken });
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired refresh token', ...errorDetails(err) });
    }
  });

  router.post('/logout', (req, res) => {
    res.status(200).json({ message: 'Logged out' });
  });

  router.get('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const user = userRowToMap(userResult.rows[0]);
      res.status(200).json(user);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired token', ...errorDetails(err) });
    }
  });

  router.put('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const body = req.body;
      const updates = [];
      const values = [];
      let idx = 1;

      for (const field of ['first_name', 'last_name', 'category', 'bio', 'locale', 'photo_url']) {
        if (body[field] !== undefined) {
          updates.push(`${field} = $${idx}`);
          values.push(body[field]);
          idx++;
        }
      }
      if (updates.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }
      updates.push('updated_at = NOW()');
      values.push(payload.id);

      const result = await pool.query(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
        values
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.status(200).json(userRowToMap(result.rows[0]));
    } catch (err) {
      return res.status(500).json({ error: 'Update failed', ...errorDetails(err) });
    }
  });

  router.post('/me/photo', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const photoUrl = `/uploads/photos/${payload.id}_${Date.now()}.jpg`;
      const result = await pool.query(
        'UPDATE users SET photo_url = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
        [photoUrl, payload.id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.status(200).json(userRowToMap(result.rows[0]));
    } catch (err) {
      return res.status(500).json({ error: 'Photo upload failed', ...errorDetails(err) });
    }
  });

  router.post('/change-password', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const { currentPassword, newPassword } = req.body;
      if (!currentPassword || !newPassword) {
        return res.status(400).json({ error: 'Current and new passwords are required' });
      }
      const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const valid = await _comparePassword(currentPassword, userResult.rows[0].password_hash);
      if (!valid) {
        return res.status(400).json({ error: 'Current password is incorrect' });
      }
      const newHash = await bcrypt.hash(newPassword, 10);
      await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [newHash, payload.id]);
      res.status(200).json({ message: 'Password changed successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Password change failed', ...errorDetails(err) });
    }
  });

  router.post('/forgot-password', async (req, res) => {
    try {
      const { email } = req.body;
      if (!email) {
        return res.status(400).json({ error: 'Email is required' });
      }
      const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
      if (userResult.rows.length === 0) {
        return res.status(200).json({ message: 'If that email exists, a reset code has been sent.' });
      }
      const userId = userResult.rows[0].id;
      const code = String(100000 + Math.floor(Math.random() * 900000));
      const id = uuidv4();
      await pool.query(
        "INSERT INTO password_reset_tokens (id, user_id, code, expires_at) VALUES ($1, $2, $3, NOW() + INTERVAL '15 minutes')",
        [id, userId, code]
      );
      console.log(`Password reset code for ${email}: ${code}`);
      res.status(200).json({ message: 'If that email exists, a reset code has been sent.', code });
    } catch (err) {
      return res.status(500).json({ error: 'Request failed', ...errorDetails(err) });
    }
  });

  router.post('/reset-password', async (req, res) => {
    try {
      const { email, code, new_password } = req.body;
      if (!email || !code || !new_password) {
        return res.status(400).json({ error: 'Email, code, and new_password are required' });
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
      await pool.query('UPDATE password_reset_tokens SET used = true WHERE id = $1', [tokenId]);
      res.status(200).json({ message: 'Password has been reset successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Reset failed', ...errorDetails(err) });
    }
  });

  router.delete('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const { password } = req.body;
      if (!password) {
        return res.status(400).json({ error: 'Password is required' });
      }
      const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const valid = await _comparePassword(password, userResult.rows[0].password_hash);
      if (!valid) {
        return res.status(400).json({ error: 'Password is incorrect' });
      }
      await pool.query('DELETE FROM users WHERE id = $1', [payload.id]);
      res.status(200).json({ message: 'Account deleted successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Account deletion failed', ...errorDetails(err) });
    }
  });

  router.get('/me/export', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const user = userRowToMap(userResult.rows[0]);
      const petsResult = await pool.query('SELECT * FROM pets WHERE user_id = $1', [payload.id]);
      const vetsResult = await pool.query('SELECT * FROM vets WHERE user_id = $1', [payload.id]);
      res.status(200).json({
        user,
        pets: petsResult.rows,
        vets: vetsResult.rows,
        exported_at: new Date().toISOString(),
      });
    } catch (err) {
      return res.status(500).json({ error: 'Data export failed', ...errorDetails(err) });
    }
  });

  return router;
}
