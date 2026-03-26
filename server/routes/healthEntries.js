import express from 'express';

export default function healthEntriesRoutes() {
  const router = express.Router();

  // GET /backend/api/health-entries
  router.get('/', (req, res) => {
    res.status(200).json([]); // Return empty array or mock data
  });

  // POST /backend/api/health-entries
  router.post('/', (req, res) => {
    res.status(201).json({ created: true, entry: req.body });
  });

  return router;
}
