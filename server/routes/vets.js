import express from 'express';

import { createApiLimiter } from '../config/rateLimit.js';
import { publicError } from '../config/security.js';
import { extractUserId } from '../lib/requireAuth.js';
import {
  createCompatVet,
  deleteCompatVet,
  updateCompatVet,
} from '../lib/people/vetProjection.js';
import { userInOrg } from './pets/shared.js';

function vetRowToMap(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    clinic: row.clinic,
    phone: row.phone,
    email: row.email,
    website: row.website || '',
    address: row.address || '',
    notes: row.notes || '',
    organization_id: row.organization_id ?? null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

function resolveOrganizationId(body) {
  const raw = body.organization_id ?? body.organizationId;
  if (raw === undefined || raw === null || raw === '') return null;
  return raw;
}

async function assertCanUseOrganizationId(pool, organizationId, userId) {
  if (!organizationId) return true;
  return userInOrg(pool, organizationId, userId);
}

export default function vetsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const orgFilter = req.query.organization_id;
      let result;
      if (orgFilter === undefined || orgFilter === '') {
        result = await pool.query(
          'SELECT * FROM vets WHERE user_id = $1 ORDER BY name',
          [userId],
        );
      } else if (orgFilter === 'null' || orgFilter === 'personal') {
        result = await pool.query(
          'SELECT * FROM vets WHERE user_id = $1 AND organization_id IS NULL ORDER BY name',
          [userId],
        );
      } else {
        if (!(await assertCanUseOrganizationId(pool, orgFilter, userId))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        result = await pool.query(
          'SELECT * FROM vets WHERE user_id = $1 AND organization_id = $2 ORDER BY name',
          [userId, orgFilter],
        );
      }
      res.json(result.rows.map(vetRowToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM vets WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Vet not found' });
      res.json(vetRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const organizationId = resolveOrganizationId(req.body);
      if (!(await assertCanUseOrganizationId(pool, organizationId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const row = await createCompatVet(pool, userId, req.body || {});
      if (!row) return res.status(500).json({ error: 'Could not create vet' });
      res.status(201).json(row);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const organizationId = resolveOrganizationId(req.body);
      if (!(await assertCanUseOrganizationId(pool, organizationId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const row = await updateCompatVet(pool, userId, req.params.id, req.body || {});
      if (!row) return res.status(404).json({ error: 'Vet not found' });
      res.json(row);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const deleted = await deleteCompatVet(pool, userId, req.params.id);
      if (!deleted) return res.status(404).json({ error: 'Vet not found' });
      res.json({ message: 'Vet deleted' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
