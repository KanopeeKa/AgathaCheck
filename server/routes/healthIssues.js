import express from 'express';

export default function healthIssuesRoutes() {
  const router = express.Router();

  // GET /backend/api/health-issues
  router.get('/', (req, res) => {
    res.status(200).json([]); // Return empty array or mock data
  });

  // POST /backend/api/health-issues
  router.post('/', (req, res) => {
    res.status(201).json({ created: true, issue: req.body });
  });

  return router;
}
