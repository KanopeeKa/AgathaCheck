import express from 'express';

export default function organizationsRoutes() {
  const router = express.Router();

  // GET /api/organizations
  router.get('/', (req, res) => {
    res.status(200).json([]); // Return empty array or mock data
  });

  // POST /api/organizations
  router.post('/', (req, res) => {
    res.status(201).json({ created: true, organization: req.body });
  });

  return router;
}
