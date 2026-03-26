

import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { Pool } from 'pg';
import dotenv from 'dotenv';
import petsRoutes from '../routes/pets.js';
import authRoutes from '../routes/auth.js';
import notificationsRoutes from '../routes/notifications.js';

dotenv.config();

// Factory function to create app with injected pool

// Allow injection of custom comparePassword for testing
export function createApp(customPool, comparePassword) {

  const app = express();
  const pool = customPool || new Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: process.env.PGPORT || 5432,
    database: process.env.PGDATABASE || 'agatha_db',
  });

  app.use(cors());
  app.use(bodyParser.json());

  // Mount pets, auth, and notifications routes
  app.use('/backend/api/pets', petsRoutes(pool));
  app.use('/backend/api/auth', authRoutes(pool, comparePassword));
  app.use('/backend/api/notifications', notificationsRoutes());

  // Health check
  app.get('/backend/health', (req, res) => {
    res.status(200).json({ status: 'OK' });
  });

  // Backend alive route
  app.get('/backend/', (req, res) => {
    res.json({ message: 'Backend alive!' });
  });

  return app;
}


const app = createApp();
export default app;
