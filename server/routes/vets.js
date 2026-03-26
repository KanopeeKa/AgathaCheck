import express from 'express';

export default function vetsRoutes() {
  const router = express.Router();

  // GET /backend/api/vets
  router.get('/', (req, res) => {
    res.status(200).json([]); // Return empty array or mock data
  });

  // POST /backend/api/vets
  router.post('/', (req, res) => {
    res.status(201).json({ created: true, vet: req.body });
  });

  return router;
}
