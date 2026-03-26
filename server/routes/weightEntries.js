import express from 'express';

export default function weightEntriesRoutes() {
  const router = express.Router();

  // POST /backend/api/weight-entries
  router.post('/', (req, res) => {
    // Accepts { pet_id, weight, date }
    res.status(201).json({ created: true, entry: req.body });
  });

  // GET /backend/api/weight-entries/latest
  router.get('/latest', (req, res) => {
    // Returns latest entry (mock)
    res.status(200).json({ pet_id: 'mock-pet', weight: 5.2, date: '2026-03-26' });
  });

  return router;
}
