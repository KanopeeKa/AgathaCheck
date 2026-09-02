import { publicError } from '../../config/security.js';
import { createNotification, userDisplayName } from '../../lib/notificationHelper.js';
import { userCanSharePet, userOwnsPet } from '../../lib/petAccess.js';
import { extractUserId } from './shared.js';

export function registerAccessRoutes(router, pool) {
  router.get('/:id/share-links', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      if (!(await userCanSharePet(pool, id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const isOwner = await userOwnsPet(pool, id, userId);
      const linkParams = [id];
      let createdByFilter = '';
      if (!isOwner) {
        createdByFilter = ' AND sl.created_by = $2';
        linkParams.push(userId);
      }
      const result = await pool.query(
        `SELECT sl.id, sl.code, sl.status, sl.created_at, sl.claimed_at,
                sl.claimed_by,
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
        claimed_by: row.claimed_by,
        claimed_by_name: row.claimed_by_name?.trim() || null,
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
        "DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2 AND role = 'shared' RETURNING id",
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
      if (!(await userOwnsPet(pool, id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT pa.*,
                u.first_name, u.last_name, u.category, u.bio, u.photo_url
         FROM pet_access pa
         JOIN users u ON u.id = pa.user_id
         WHERE pa.pet_id = $1 AND pa.role IN ('shared', 'guardian')
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

  router.put('/:id/access/:userId/role', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    return res.status(501).json({ error: 'Not implemented' });
  });

  router.delete('/:id/access/:userId', async (req, res) => {
    const ownerId = extractUserId(req);
    if (!ownerId) return res.status(401).json({ error: 'Unauthorized' });
    const { id, userId: targetUserId } = req.params;
    try {
      if (!(await userOwnsPet(pool, id, ownerId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const petResult = await pool.query('SELECT name FROM pets WHERE id = $1', [id]);
      const petName = petResult.rows[0]?.name || 'the pet';

      const ownerResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [ownerId]
      );
      const ownerName = userDisplayName(ownerResult.rows[0] || {});

      const deleteResult = await pool.query(
        "DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2 AND role IN ('shared', 'guardian', 'pending_shared') RETURNING id",
        [id, targetUserId]
      );
      if (deleteResult.rows.length === 0) {
        return res.status(404).json({ error: 'Access not found' });
      }

      await createNotification(pool, {
        userId: targetUserId,
        petId: id,
        petName,
        title: 'Sharing ended',
        message: `${ownerName} stopped sharing ${petName} with you.`,
        type: 'general',
      });

      res.json({ message: 'Access removed' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
