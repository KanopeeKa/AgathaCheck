import { publicError } from '../../config/security.js';
import { createNotification, userDisplayName } from '../../lib/notificationHelper.js';
import {
  CARER_ROLE,
  CO_PARENT_ROLE,
  PET_ACCESS_ROLES,
  userCanSharePet,
  userIsOwnerOrCoParent,
  userOwnsPet,
} from '../../lib/petAccess.js';
import { extractUserId, withOptionalTransaction } from '../pets/shared.js';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');

export function registerPetAccessRoutes(router, pool) {
  router.get('/:id/share-links', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      if (!(await userCanSharePet(pool, id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const seesAllLinks = await userIsOwnerOrCoParent(pool, id, userId);
      const linkParams = [id];
      let createdByFilter = '';
      if (!seesAllLinks) {
        createdByFilter = ' AND sl.created_by = $2';
        linkParams.push(userId);
      }
      const result = await pool.query(
        `SELECT sl.id, sl.code, sl.status, sl.created_at, sl.claimed_at,
                sl.claimed_by, sl.expires_at, sl.access_role,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) as claimed_by_name
         FROM pet_share_links sl
         LEFT JOIN users u ON u.id = sl.claimed_by
         WHERE sl.pet_id = $1${createdByFilter}
         ORDER BY sl.created_at DESC`,
        linkParams
      );
      res.json(result.rows.map((row) => ({
        id: row.id,
        code: row.code,
        status: row.status || 'pending',
        created_at: row.created_at,
        claimed_at: row.claimed_at,
        expires_at: row.expires_at
          ? (row.expires_at.toISOString?.() || String(row.expires_at))
          : null,
        claimed_by: row.claimed_by,
        claimed_by_name: row.claimed_by_name?.trim() || null,
        access_role: row.access_role || CARER_ROLE,
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/follow', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      const petResult = await pool.query('SELECT name, user_id FROM pets WHERE id = $1', [id]);
      const pet = petResult.rows[0];
      if (!pet) {
        return res.status(404).json({ error: 'Pet not found' });
      }

      const deleteResult = await pool.query(
        `DELETE FROM pet_access
         WHERE pet_id = $1 AND user_id = $2 AND role IN (${PET_ACCESS_ROLES_SQL})
         RETURNING id`,
        [id, userId]
      );
      if (deleteResult.rows.length === 0) {
        return res.status(404).json({ error: 'Shared access not found' });
      }

      const followerResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId]
      );
      const followerName = userDisplayName(followerResult.rows[0] || {});

      await createNotification(pool, {
        userId: pet.user_id,
        petId: id,
        petName: pet.name,
        title: 'Stopped following',
        message: `${followerName} stopped following ${pet.name}.`,
        type: 'general',
      });

      res.json({ message: 'Stopped following pet' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/access', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      if (!(await userCanSharePet(pool, id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT pa.*,
                u.first_name, u.last_name, u.category, u.bio, u.photo_url
         FROM pet_access pa
         JOIN users u ON u.id = pa.user_id
         WHERE pa.pet_id = $1 AND pa.role IN (${PET_ACCESS_ROLES_SQL})
         ORDER BY pa.created_at`,
        [id]
      );
      const access = result.rows.map((row) => ({
        id: row.id,
        pet_id: row.pet_id,
        user_id: row.user_id,
        role: row.role,
        invited_by: row.invited_by || null,
        created_at: row.created_at,
        user: {
          first_name: row.first_name || '',
          last_name: row.last_name || '',
          category: row.category || 'pet_carer',
          bio: row.bio || '',
          photo_url: row.photo_url || '',
        },
      }));
      res.json(access);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id/access/:targetUserId/role', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id, targetUserId } = req.params;
    const nextRole = req.body?.role || req.body?.access_role;
    if (![CARER_ROLE, CO_PARENT_ROLE].includes(nextRole)) {
      return res.status(400).json({ error: 'role must be carer or co_parent' });
    }
    try {
      if (!(await userCanSharePet(pool, id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `UPDATE pet_access
         SET role = $1, updated_at = NOW()
         WHERE pet_id = $2 AND user_id = $3 AND role IN (${PET_ACCESS_ROLES_SQL})
         RETURNING id, role`,
        [nextRole, id, targetUserId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Access not found' });
      }
      res.json({ user_id: targetUserId, role: result.rows[0].role });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/access/:targetUserId', async (req, res) => {
    const actorId = extractUserId(req);
    if (!actorId) return res.status(401).json({ error: 'Unauthorized' });
    const { id, targetUserId } = req.params;
    try {
      if (!(await userCanSharePet(pool, id, actorId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      await withOptionalTransaction(pool, async (db) => {
        const petResult = await db.query('SELECT name FROM pets WHERE id = $1', [id]);
        const petName = petResult.rows[0]?.name || 'the pet';

        const actorResult = await db.query(
          'SELECT first_name, last_name, email FROM users WHERE id = $1',
          [actorId]
        );
        const actorName = userDisplayName(actorResult.rows[0] || {});

        const deleteResult = await db.query(
          `DELETE FROM pet_access
           WHERE pet_id = $1 AND user_id = $2 AND role IN (${PET_ACCESS_ROLES_SQL})
           RETURNING id`,
          [id, targetUserId]
        );
        if (deleteResult.rows.length === 0) {
          const err = new Error('Access not found');
          err.status = 404;
          throw err;
        }

        await createNotification(db, {
          userId: targetUserId,
          petId: id,
          petName,
          title: 'Sharing ended',
          message: `${actorName} stopped sharing ${petName} with you.`,
          type: 'general',
        });
      });
      res.json({ message: 'Access removed' });
    } catch (err) {
      if (err.status === 404) {
        return res.status(404).json({ error: 'Access not found' });
      }
      res.status(500).json({ error: publicError(err) });
    }
  });
}
