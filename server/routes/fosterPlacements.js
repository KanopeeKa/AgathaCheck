import express from 'express';
import jwt from 'jsonwebtoken';

import { createApiLimiter } from '../config/rateLimit.js';
import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import { normalizeCalendarDateInput } from '../lib/calendarDate.js';
import { createNotification, userDisplayName } from '../lib/notificationHelper.js';
import {
  completeAdoptionTransfer,
  grantFosterPetAccess,
  placementToMap,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  revokeFosterPetAccess,
} from '../lib/fosterPlacements.js';
import { setFosterCare } from '../lib/petCustody.js';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

export default function fosterPlacementsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.get('/pending', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT fp.*,
                p.name AS pet_name,
                p.species AS pet_species,
                o.name AS organization_name,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
                u.email AS foster_email
         FROM foster_placements fp
         JOIN pets p ON p.id = fp.pet_id
         JOIN organizations o ON o.id = fp.organization_id
         JOIN users u ON u.id = fp.foster_user_id
         WHERE fp.foster_user_id = $1
           AND fp.status = $2
         ORDER BY fp.created_at DESC`,
        [userId, PLACEMENT_STATUS_PENDING],
      );
      res.json(result.rows.map((row) => placementToMap(row)));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/pending-adoptions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT fp.*,
                p.name AS pet_name,
                p.species AS pet_species,
                o.name AS organization_name,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
                u.email AS foster_email
         FROM foster_placements fp
         JOIN pets p ON p.id = fp.pet_id
         JOIN organizations o ON o.id = fp.organization_id
         JOIN users u ON u.id = fp.foster_user_id
         WHERE fp.foster_user_id = $1
           AND fp.status = $2
         ORDER BY fp.created_at DESC`,
        [userId, PLACEMENT_STATUS_WAITING_ADOPTION],
      );
      res.json(result.rows.map((row) => placementToMap(row)));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const placementId = req.params.id;
    try {
      const placementResult = await pool.query(
        'SELECT * FROM foster_placements WHERE id = $1',
        [placementId],
      );
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      if (placement.foster_user_id !== userId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      if (placement.status !== PLACEMENT_STATUS_PENDING) {
        return res.status(400).json({ error: 'Placement is not pending' });
      }

      const petResult = await pool.query(
        'SELECT name FROM pets WHERE id = $1',
        [placement.pet_id],
      );
      const petName = petResult.rows[0]?.name || 'Pet';

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1,
             start_date = COALESCE(start_date, CURRENT_DATE),
             responded_at = NOW(),
             updated_at = NOW()
         WHERE id = $2
         RETURNING *`,
        [PLACEMENT_STATUS_IN_PROGRESS, placementId],
      );
      const updated = updateResult.rows[0];

      await grantFosterPetAccess(
        pool,
        placement.pet_id,
        userId,
        placement.created_by,
      );
      await setFosterCare(
        pool,
        placement.pet_id,
        userId,
        placement.organization_id,
      );

      const fosterResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId],
      );
      const fosterName = userDisplayName(fosterResult.rows[0] || {});

      if (placement.created_by) {
        await createNotification(pool, {
          userId: placement.created_by,
          petId: placement.pet_id,
          petName,
          title: 'Foster placement accepted',
          message: `${fosterName} accepted the foster placement for ${petName}.`,
          type: 'general',
        });
      }

      res.json(placementToMap(updated, { pet_name: petName }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/decline', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const placementId = req.params.id;
    try {
      const placementResult = await pool.query(
        'SELECT * FROM foster_placements WHERE id = $1',
        [placementId],
      );
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      if (placement.foster_user_id !== userId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      if (placement.status !== PLACEMENT_STATUS_PENDING) {
        return res.status(400).json({ error: 'Placement is not pending' });
      }

      const petResult = await pool.query(
        'SELECT name FROM pets WHERE id = $1',
        [placement.pet_id],
      );
      const petName = petResult.rows[0]?.name || 'Pet';

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1, responded_at = NOW(), updated_at = NOW()
         WHERE id = $2
         RETURNING *`,
        [PLACEMENT_STATUS_NOT_IN_FOSTER, placementId],
      );

      const fosterResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId],
      );
      const fosterName = userDisplayName(fosterResult.rows[0] || {});

      if (placement.created_by) {
        await createNotification(pool, {
          userId: placement.created_by,
          petId: placement.pet_id,
          petName,
          title: 'Foster placement declined',
          message: `${fosterName} declined the foster placement for ${petName}.`,
          type: 'general',
        });
      }

      res.json(placementToMap(updateResult.rows[0], { pet_name: petName }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/confirm-adoption', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const placementId = req.params.id;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const placementResult = await client.query(
        'SELECT * FROM foster_placements WHERE id = $1 FOR UPDATE',
        [placementId],
      );
      if (placementResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      if (placement.foster_user_id !== userId) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Forbidden' });
      }
      if (placement.status !== PLACEMENT_STATUS_WAITING_ADOPTION) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Placement is not awaiting adoption confirmation' });
      }

      const petResult = await client.query(
        'SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1',
        [placement.pet_id],
      );
      if (petResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Pet not found' });
      }
      const pet = petResult.rows[0];

      const updated = await completeAdoptionTransfer(client, placement, pet);
      await revokeFosterPetAccess(client, placement.pet_id, userId);

      const fosterResult = await client.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId],
      );
      const fosterName = userDisplayName(fosterResult.rows[0] || {});

      if (placement.created_by) {
        await createNotification(client, {
          userId: placement.created_by,
          petId: placement.pet_id,
          petName: pet.name,
          title: 'Adoption confirmed',
          message: `${fosterName} adopted ${pet.name}. The pet has left organisation custody.`,
          type: 'general',
        });
      }

      await createNotification(client, {
        userId,
        petId: placement.pet_id,
        petName: pet.name,
        title: 'Adoption complete',
        message: `You are now the owner of ${pet.name}.`,
        type: 'general',
      });

      await client.query('COMMIT');
      res.json({
        ...placementToMap(updated, { pet_name: pet.name }),
        adopted: true,
        new_owner_id: userId,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      res.status(500).json({ error: publicError(err) });
    } finally {
      client.release();
    }
  });

  return router;
}
