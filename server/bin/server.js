import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Database connection pool
const pool = new Pool({
  user: process.env.PGUSER || 'user',
  password: process.env.PGPASSWORD || 'password',
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
  database: process.env.PGDATABASE || 'agatha_db',
});

// Health check
app.get('/backend/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

// FIXED: Prefix ALL routes with /backend
app.get('/backend/', (req, res) => {
  res.json({ message: 'Backend alive!' });
});

// GET /api/pets - List all pets
app.get('/backend/api/pets', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM pets');
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching pets:', err);
    res.status(500).json({ error: `Error fetching pets: ${err.message}` });
  }
});

// GET /api/pets/:id - Get pet by ID
app.get('/backend/api/pets/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM pets WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pet not found' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching pet:', err);
    res.status(500).json({ error: `Error fetching pet: ${err.message}` });
  }
});

// POST /api/pets - Create a new pet
app.post('/backend/api/pets', async (req, res) => {
  try {
    const id = uuidv4();
    const { user_id, name, species, breed = '', age, date_of_birth, weight, gender } = req.body;
    
    const result = await pool.query(
      'INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *',
      [id, user_id, name, species, breed, age, date_of_birth, weight, gender]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating pet:', err);
    res.status(500).json({ error: `Error creating pet: ${err.message}` });
  }
});

// PUT /api/pets/:id - Update a pet
app.put('/backend/api/pets/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, species, breed = '', age, date_of_birth, weight, gender } = req.body;
    
    const result = await pool.query(
      'UPDATE pets SET name = $1, species = $2, breed = $3, age = $4, date_of_birth = $5, weight = $6, gender = $7, updated_at = NOW() WHERE id = $8 RETURNING *',
      [name, species, breed, age, date_of_birth, weight, gender, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pet not found' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating pet:', err);
    res.status(500).json({ error: `Error updating pet: ${err.message}` });
  }
});

// DELETE /api/pets/:id - Delete a pet
app.delete('/backend/api/pets/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM pets WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pet not found' });
    }
    
    res.json({ message: 'Pet deleted successfully', pet: result.rows[0] });
  } catch (err) {
    console.error('Error deleting pet:', err);
    res.status(500).json({ error: `Error deleting pet: ${err.message}` });
  }
});

// ADD after pets routes:

// POST /backend/api/auth/login
app.post('/backend/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    // Add your auth logic (check users table, JWT)
    res.json({ token: 'fake-jwt-token', user: { id: '1', email } });
  } catch (err) {
    res.status(500).json({ error: 'Login failed' });
  }
});

// POST /backend/api/auth/signup
app.post('/backend/api/auth/signup', async (req, res) => {
  try {
    const { email, password } = req.body;
    const id = uuidv4();
    // Hash password, INSERT users table
    await pool.query(
      "INSERT INTO users (id, email, password_hash) VALUES ($1, $2, $3)",
      [id, email, 'hashed:' + password]  // Use bcrypt!
    );
    res.status(201).json({ message: 'User created', userId: id });
  } catch (err) {
    res.status(500).json({ error: 'Signup failed' });
  }
});


// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
  console.log(`Database: ${process.env.PGDATABASE || 'agatha_db'} on ${process.env.PGHOST || 'localhost'}:${process.env.PGPORT || 5432}`);
});
