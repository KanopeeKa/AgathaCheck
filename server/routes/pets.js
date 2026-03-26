import express from 'express';
import { v4 as uuidv4 } from 'uuid';

export default function petsRoutes(pool) {
  const router = express.Router();

  // --- Extended Pets Endpoints (stub implementations) ---
  router.post('/:id/transfer-to-org', (req, res) => {
    res.status(200).json({ status: 'transferred', pet_id: req.params.id });
  });

  router.get('/:id/family-events', (req, res) => {
    res.status(200).json([]);
  });

  router.post('/:id/family-events', (req, res) => {
    res.status(201).json({ event_id: 1 });
  });

  router.put('/:id/family-events/:eventId', (req, res) => {
    res.status(200).json({ updated: true, event_id: req.params.eventId });
  });

  router.delete('/:id/family-events/:eventId', (req, res) => {
    res.status(200).json({ deleted: true, event_id: req.params.eventId });
  });

  router.get('/:id/access', (req, res) => {
    res.status(200).json([]);
  });

  router.put('/:id/access/:userId/role', (req, res) => {
    res.status(200).json({ updated: true, user_id: req.params.userId });
  });

  router.delete('/:id/access/:userId', (req, res) => {
    res.status(200).json({ deleted: true, user_id: req.params.userId });
  });

  router.delete('/:id/data', (req, res) => {
    res.status(200).json({ deleted: true, pet_id: req.params.id });
  });

  router.post('/:id/passed-away', (req, res) => {
    res.status(200).json({ passed_away: true, pet_id: req.params.id });
  });

  // GET /api/pets - List all pets
  router.get('/', async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM pets');
      res.json(result.rows);
    } catch (err) {
      console.error('Error fetching pets:', err);
      res.status(500).json({ error: `Error fetching pets: ${err.message}` });
    }
  });

  // GET /api/pets/:id - Get pet by ID
  router.get('/:id', async (req, res) => {
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
  router.post('/', async (req, res) => {
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
  router.put('/:id', async (req, res) => {
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
  router.delete('/:id', async (req, res) => {
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

  return router;
}
