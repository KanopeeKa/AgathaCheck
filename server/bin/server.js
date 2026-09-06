import '../config/loadEnv.js';
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import path from 'path';
import { fileURLToPath } from 'url';
import { Pool } from 'pg';
import petsRoutes from '../routes/pets.js';
import authRoutes from '../routes/auth.js';
import notificationsRoutes from '../routes/notifications.js';
import weightEntriesRoutes from '../routes/weightEntries.js';
import healthEntriesRoutes from '../routes/healthEntries.js';
import healthIssuesRoutes from '../routes/healthIssues.js';
import organizationsRoutes from '../routes/organizations.js';
import vetsRoutes from '../routes/vets.js';
import sharingRoutes from '../routes/sharing.js';
import fosterPlacementsRoutes from '../routes/fosterPlacements.js';
import custodyTransfersRoutes from '../routes/custodyTransfers.js';
import uploadsRoutes from '../routes/uploads.js';
import healthFilesRoutes from '../routes/healthFiles.js';
import { REFRESH_COOKIE_NAME, getCookieValue } from '../lib/authCookies.js';
import { corsOptions } from '../config/security.js';
import { securityHeadersMiddleware } from '../config/securityHeaders.js';
import { createStaticUploadLimiter } from '../config/rateLimit.js';
import { logPublicAccessModeOnce } from '../config/publicAccess.js';
import { requestContextMiddleware } from '../middleware/requestContext.js';
import { publicAccessGate } from '../middleware/publicAccessGate.js';

function getServerDir() {
  try {
    return path.dirname(fileURLToPath(import.meta.url));
  } catch (e) {
    return __dirname || path.resolve('.');
  }
}

function createPool() {
  const databaseUrl = process.env.DATABASE_URL;
  const pool = databaseUrl
    ? new Pool({ connectionString: databaseUrl })
    : new Pool({
        user: process.env.PGUSER || 'user',
        password: process.env.PGPASSWORD || 'password',
        host: process.env.PGHOST || 'localhost',
        port: process.env.PGPORT || 5432,
        database: process.env.PGDATABASE || 'agatha_db',
      });
  // Calendar DATE/TIMESTAMPTZ round-trips must not depend on the host TZ.
  pool.on('connect', (client) => {
    client.query("SET TIME ZONE 'UTC'").catch(() => {});
  });
  return pool;
}

export function createApp(customPool, comparePassword) {
  const app = express();
  const pool = customPool || createPool();
  // Expose the pool so the startup wrapper can close it on graceful shutdown.
  app.locals.pool = pool;

  logPublicAccessModeOnce();

  app.set('trust proxy', 1);
  app.use(securityHeadersMiddleware());
  app.use(requestContextMiddleware);
  app.use(publicAccessGate);
  app.use(cors(corsOptions()));
  app.use((req, res, next) => {
    const refreshToken = getCookieValue(req.headers.cookie, REFRESH_COOKIE_NAME);
    req.cookies = refreshToken ? { [REFRESH_COOKIE_NAME]: refreshToken } : {};
    next();
  });
  app.use(bodyParser.json());

  const blockSensitiveUploadPaths = (req, res, next) => {
    const normalized = req.path.replace(/\\/g, '/');
    if (
      normalized.startsWith('/health_documents/')
      || normalized.startsWith('/health_photos/')
      || normalized.startsWith('/private_health/')
      || normalized === '/health_documents'
      || normalized === '/health_photos'
      || normalized === '/private_health'
    ) {
      return res.status(404).json({ error: 'Not found' });
    }
    return next();
  };

  const staticUploadLimiter = createStaticUploadLimiter();

  app.use('/uploads', staticUploadLimiter);
  app.use('/backend/uploads', staticUploadLimiter);
  app.use('/uploads', blockSensitiveUploadPaths);
  app.use('/backend/uploads', blockSensitiveUploadPaths);
  app.use('/uploads', express.static(path.resolve(process.cwd(), 'uploads')));
  app.use('/backend/uploads', express.static(path.resolve(process.cwd(), 'uploads')));

  app.use('/api/uploads', uploadsRoutes());
  app.use('/backend/api/uploads', uploadsRoutes());
  app.use('/api/health-files', healthFilesRoutes(pool));
  app.use('/backend/api/health-files', healthFilesRoutes(pool));

  app.use('/api/auth', authRoutes(pool, comparePassword));
  app.use('/api/pets', petsRoutes(pool));
  app.use('/api/vets', vetsRoutes(pool));
  app.use('/api/organizations', organizationsRoutes(pool));
  app.use('/api/notifications', notificationsRoutes(pool));
  app.use('/api/weight-entries', weightEntriesRoutes(pool));
  app.use('/api/health-entries', healthEntriesRoutes(pool));
  app.use('/api/health-issues', healthIssuesRoutes(pool));
  app.use('/api/share', sharingRoutes(pool));
  app.use('/api/foster-placements', fosterPlacementsRoutes(pool));
  app.use('/api/custody-transfers', custodyTransfersRoutes(pool));
  app.use('/api/archived-pets', (req, res) => {
    res.json([]);
  });
  app.use('/backend/api/archived-pets', (req, res) => {
    res.json([]);
  });

  app.use('/backend/api/auth', authRoutes(pool, comparePassword));
  app.use('/server/api/auth', authRoutes(pool, comparePassword));
  app.use('/backend/api/pets', petsRoutes(pool));
  app.use('/backend/api/vets', vetsRoutes(pool));
  app.use('/backend/api/organizations', organizationsRoutes(pool));
  app.use('/backend/api/notifications', notificationsRoutes(pool));
  app.use('/backend/api/weight-entries', weightEntriesRoutes(pool));
  app.use('/backend/api/health-entries', healthEntriesRoutes(pool));
  app.use('/backend/api/health-issues', healthIssuesRoutes(pool));
  app.use('/backend/api/share', sharingRoutes(pool));
  app.use('/backend/api/foster-placements', fosterPlacementsRoutes(pool));
  app.use('/backend/api/custody-transfers', custodyTransfersRoutes(pool));

  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK' });
  });

  app.get('/backend/health', (req, res) => {
    res.status(200).json({ status: 'OK' });
  });

  app.get('/backend/', (req, res) => {
    res.json({ message: 'Backend alive!' });
  });

  const flutterWebDir = path.resolve(getServerDir(), '../../flutter_app/build/web');
  app.use(express.static(flutterWebDir));
  app.get('*', (req, res) => {
    res.sendFile(path.join(flutterWebDir, 'index.html'), (err) => {
      if (err) {
        res.status(404).json({ error: 'Not found' });
      }
    });
  });

  return app;
}

const app = createApp();
export default app;
