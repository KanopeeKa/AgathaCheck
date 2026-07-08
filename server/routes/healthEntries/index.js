import express from 'express';

import { registerCrudRoutes } from './crudRouter.js';
import { registerCompletionRoutes } from './completionRouter.js';
import { registerDocumentsRoutes } from './documentsRouter.js';

export default function healthEntriesRoutes(pool) {
  const router = express.Router();

  registerCrudRoutes(router, pool);
  registerCompletionRoutes(router, pool);
  registerDocumentsRoutes(router, pool);

  return router;
}
