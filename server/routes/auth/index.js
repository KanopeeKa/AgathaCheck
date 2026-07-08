import express from 'express';
import bcrypt from 'bcrypt';

import { createApiLimiter, createAuthLimiter } from '../../config/rateLimit.js';
import { registerSessionRoutes } from './sessionRouter.js';
import { registerProfileRoutes } from './profileRouter.js';
import { registerPasswordRoutes } from './passwordRouter.js';

export default function authRoutes(pool, comparePassword) {
  const router = express.Router();
  router.use(createApiLimiter());
  const deps = {
    comparePassword: comparePassword || bcrypt.compare,
    authLimiter: createAuthLimiter(),
  };

  registerSessionRoutes(router, pool, deps);
  registerProfileRoutes(router, pool, deps);
  registerPasswordRoutes(router, pool, deps);

  return router;
}
