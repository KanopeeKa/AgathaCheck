import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { Pool } from 'pg';
import dotenv from 'dotenv';
import petsRoutes from '../routes/pets.js';
import authRoutes from '../routes/auth.js';
import notificationsRoutes from '../routes/notifications.js';
import weightEntriesRoutes from '../routes/weightEntries.js';
import healthEntriesRoutes from '../routes/healthEntries.js';
import healthIssuesRoutes from '../routes/healthIssues.js';
import organizationsRoutes from '../routes/organizations.js';
import vetsRoutes from '../routes/vets.js';
import sharingRoutes from '../routes/sharing.js';

dotenv.config();

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

  app.use('/api/auth', authRoutes(pool, comparePassword));
  app.use('/api/pets', petsRoutes(pool));
  app.use('/api/vets', vetsRoutes(pool));
  app.use('/api/organizations', organizationsRoutes(pool));
  app.use('/api/notifications', notificationsRoutes(pool));
  app.use('/api/weight-entries', weightEntriesRoutes(pool));
  app.use('/api/health-entries', healthEntriesRoutes(pool));
  app.use('/api/health-issues', healthIssuesRoutes(pool));
  app.use('/api/share', sharingRoutes(pool));
  app.use('/api/archived-pets', (req, res) => {
    res.json([]);
  });

  app.use('/backend/api/auth', authRoutes(pool, comparePassword));
  app.use('/backend/api/pets', petsRoutes(pool));
  app.use('/backend/api/vets', vetsRoutes(pool));
  app.use('/backend/api/organizations', organizationsRoutes(pool));
  app.use('/backend/api/notifications', notificationsRoutes(pool));
  app.use('/backend/api/weight-entries', weightEntriesRoutes(pool));
  app.use('/backend/api/health-entries', healthEntriesRoutes(pool));
  app.use('/backend/api/health-issues', healthIssuesRoutes(pool));
  app.use('/backend/api/share', sharingRoutes(pool));

  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK' });
  });

  app.get('/backend/health', (req, res) => {
    res.status(200).json({ status: 'OK' });
  });

  app.get('/backend/', (req, res) => {
    res.json({ message: 'Backend alive!' });
  });

  return app;
}

const app = createApp();
export default app;
