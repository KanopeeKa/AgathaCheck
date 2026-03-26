import express from 'express';

export default function notificationsRoutes() {
  const router = express.Router();

  // GET /backend/api/notifications
  router.get('/', (req, res) => {
    res.status(200).json([]); // Return empty array or mock notifications
  });

  // GET /backend/api/notifications/preferences
  router.get('/preferences', (req, res) => {
    res.status(200).json({ email: true, sms: false, push: true }); // Example preferences
  });

  // POST /backend/api/notifications/check-due
  router.post('/check-due', (req, res) => {
    res.status(200).json({ checked: true, due: [] }); // Example response
  });

  return router;
}
