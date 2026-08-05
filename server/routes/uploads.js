import { Router } from 'express';
import { sendPublicUpload } from '../lib/servePublicUpload.js';

export default function uploadsRoutes() {
  const router = Router();

  router.get('/:subdir/:filename', (req, res) => {
    sendPublicUpload(`${req.params.subdir}/${req.params.filename}`, res);
  });

  router.get('/:filename', (req, res) => {
    sendPublicUpload(req.params.filename, res);
  });

  return router;
}
