import express from 'express';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

export default function authRoutes(pool, comparePassword) {
  const router = express.Router();
  const _comparePassword = comparePassword || bcrypt.compare;

  // POST /backend/api/auth/login
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
      const user = {
        id: userRow.id,
        email: userRow.email,
        first_name: userRow.first_name,
        last_name: userRow.last_name,
        category: userRow.category,
        bio: userRow.bio,
        photo_url: userRow.photo_url,
        locale: userRow.locale
      };
      const jwtSecret = process.env.JWT_SECRET || 'default_secret';
      const payload = { id: user.id, email: user.email };
      const accessToken = jwt.sign(payload, jwtSecret, { expiresIn: '30m' });
      const refreshToken = jwt.sign(payload, jwtSecret, { expiresIn: '30d' });
      res.status(200).json({
        user,
        access_token: accessToken,
        refresh_token: refreshToken
      });
    } catch (err) {
      console.error('Login error:', err);
      res.status(500).json({ error: 'Login failed', details: err.message });
    }
  });

  // POST /backend/api/auth/signup
  router.post('/signup', async (req, res) => {
    try {
      const { email, password, first_name = '', last_name = '', category = 'pet_guardian', bio = '', photo_url = '', locale = 'en' } = req.body;
      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required.' });
      }
      const id = uuidv4();
      // Hash password, INSERT users table
      const saltRounds = 10;
      const password_hash = await bcrypt.hash(password, saltRounds);
      let result;
      try {
        result = await pool.query(
          `INSERT INTO users (id, email, password_hash, first_name, last_name, category, bio, photo_url, locale) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`,
          [id, email, password_hash, first_name, last_name, category, bio, photo_url, locale]
        );
      } catch (err) {
        // Handle duplicate email error (Postgres unique_violation)
        if (err.code === '23505') {
          return res.status(400).json({ error: 'Email already exists.' });
        }
        throw err;
      }
      // Compose user object for response
      const user = {
        id: result.rows[0].id,
        email,
        first_name,
        last_name,
        category,
        bio,
        photo_url,
        locale
      };
      // Generate JWT tokens
      const jwtSecret = process.env.JWT_SECRET || 'default_secret';
      const payload = { id: user.id, email: user.email };
      const accessToken = jwt.sign(payload, jwtSecret, { expiresIn: '30m' });
      const refreshToken = jwt.sign(payload, jwtSecret, { expiresIn: '30d' });
      res.status(201).json({
        user,
        access_token: accessToken,
        refresh_token: refreshToken
      });
    } catch (err) {
      console.error('Signup error:', err);
      res.status(500).json({ error: 'Signup failed', details: err.message });
    }
  });

  // GET /backend/api/auth/me - Get current user from JWT
  router.get('/me', async (req, res) => {
    const authHeader = req.headers['authorization'] || req.headers['Authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    const token = authHeader.split(' ')[1];
    const jwtSecret = process.env.JWT_SECRET || 'default_secret';
    try {
      const payload = jwt.verify(token, jwtSecret);
      // Fetch user from DB for up-to-date info
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const userRow = userResult.rows[0];
      const user = {
        id: userRow.id,
        email: userRow.email,
        first_name: userRow.first_name,
        last_name: userRow.last_name,
        category: userRow.category,
        bio: userRow.bio,
        photo_url: userRow.photo_url,
        locale: userRow.locale
      };
      res.status(200).json({ user });
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired token', details: err.message });
    }
  });

  return router;
}
