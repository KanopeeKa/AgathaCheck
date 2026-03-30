import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

function petRowToMap(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    species: row.species,
    breed: row.breed || '',
    age: row.age,
    dateOfBirth: row.date_of_birth ? row.date_of_birth.toISOString?.() || String(row.date_of_birth) : null,
    date_of_birth: row.date_of_birth ? row.date_of_birth.toISOString?.() || String(row.date_of_birth) : null,
    weight: row.weight,
    gender: row.gender,
    bio: row.bio || '',
    insurance: row.insurance || '',
    neuteredDate: row.neutered_date ? row.neutered_date.toISOString?.() || String(row.neutered_date) : null,
    neuterDismissed: row.neuter_dismissed || false,
    chipId: row.chip_id || '',
    chipDismissed: row.chip_dismissed || false,
    photoPath: row.photo_path,
    vetId: row.vet_id ? String(row.vet_id) : null,
    colorValue: row.color_index,
    passedAway: row.passed_away || false,
    organization_id: row.organization_id,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export default function petsRoutes(pool) {
  const router = express.Router();

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

  router.get('/all', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT * FROM pets WHERE user_id = $1 ORDER BY created_at',
        [userId]
      );
      res.json(result.rows.map(petRowToMap));
    } catch (err) {
      res.status(500).json({ error: `Error fetching pets: ${err.message}` });
    }
  });

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT * FROM pets WHERE user_id = $1 ORDER BY created_at',
        [userId]
      );
      res.json(result.rows.map(petRowToMap));
    } catch (err) {
      res.status(500).json({ error: `Error fetching pets: ${err.message}` });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({ error: 'Invalid pet ID' });
    }
    try {
      const result = await pool.query('SELECT * FROM pets WHERE id = $1 AND user_id = $2', [id, userId]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      res.json(petRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: `Error fetching pet: ${err.message}` });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const id = req.body.id || uuidv4();
      const {
        name, species, breed = '', age, weight, gender,
        bio = '', insurance = '',
        neuterDismissed = false, chipId = '', chipDismissed = false,
        photoPath, vetId, colorValue, passedAway = false,
        organization_id
      } = req.body;
      const dateOfBirth = req.body.dateOfBirth || req.body.date_of_birth || null;
      const neuteredDate = req.body.neuteredDate || null;
      const result = await pool.query(
        `INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender,
          bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed,
          photo_path, vet_id, color_index, passed_away, organization_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20) RETURNING *`,
        [id, userId, name, species, breed, age, dateOfBirth, weight, gender,
         bio, insurance, neuteredDate, neuterDismissed, chipId, chipDismissed,
         photoPath || null, vetId || null, colorValue != null ? colorValue : null,
         passedAway, organization_id || null]
      );
      res.status(201).json(petRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: `Error creating pet: ${err.message}` });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { id } = req.params;
      const {
        name, species, breed = '', age, weight, gender,
        bio = '', insurance = '',
        neuterDismissed = false, chipId = '', chipDismissed = false,
        photoPath, vetId, colorValue, passedAway = false,
        organization_id
      } = req.body;
      const dateOfBirth = req.body.dateOfBirth || req.body.date_of_birth || null;
      const neuteredDate = req.body.neuteredDate || null;
      const result = await pool.query(
        `UPDATE pets SET name=$1, species=$2, breed=$3, age=$4, date_of_birth=$5, weight=$6, gender=$7,
          bio=$8, insurance=$9, neutered_date=$10, neuter_dismissed=$11, chip_id=$12, chip_dismissed=$13,
          photo_path=$14, vet_id=$15, color_index=$16, passed_away=$17, organization_id=$18,
          updated_at=NOW()
         WHERE id=$19 AND user_id=$20 RETURNING *`,
        [name, species, breed, age, dateOfBirth, weight, gender,
         bio, insurance, neuteredDate, neuterDismissed, chipId, chipDismissed,
         photoPath || null, vetId || null, colorValue != null ? colorValue : null,
         passedAway, organization_id || null, id, userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      res.json(petRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: `Error updating pet: ${err.message}` });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { id } = req.params;
      const result = await pool.query('DELETE FROM pets WHERE id = $1 AND user_id = $2 RETURNING *', [id, userId]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      res.json({ message: 'Pet deleted successfully', pet: petRowToMap(result.rows[0]) });
    } catch (err) {
      res.status(500).json({ error: `Error deleting pet: ${err.message}` });
    }
  });

  return router;
}
