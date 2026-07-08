import { errorDetails } from '../../config/security.js';
import { listFosterContactsForUser } from '../../lib/orgPeople.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { deletePostHogPerson } from '../../lib/posthogServer.js';
import {
  buildUserDataExport,
  exportAuditMetadata,
} from '../../lib/gdprUserExport.js';
import { extractToken, userRowToMap, verifyToken } from './shared.js';

export function registerProfileRoutes(router, pool, { comparePassword }) {
  router.get('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const user = userRowToMap(userResult.rows[0]);
      res.status(200).json(user);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired token', ...errorDetails(err) });
    }
  });

  router.get('/me/foster-contacts', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const contacts = await listFosterContactsForUser(pool, payload.id);
      res.status(200).json(contacts);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired token', ...errorDetails(err) });
    }
  });

  router.put('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const body = req.body;
      const updates = [];
      const values = [];
      let idx = 1;

      for (const field of ['first_name', 'last_name', 'category', 'bio', 'locale', 'photo_url']) {
        if (body[field] !== undefined) {
          updates.push(`${field} = $${idx}`);
          values.push(body[field]);
          idx++;
        }
      }
      if (updates.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }
      updates.push('updated_at = NOW()');
      values.push(payload.id);

      const result = await pool.query(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
        values
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const changedFields = updates
        .filter((clause) => !clause.startsWith('updated_at'))
        .map((clause) => clause.split('=')[0].trim());
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'user.profile_updated',
        resourceType: 'user',
        resourceId: payload.id,
        metadata: { fields: changedFields },
        req,
      });
      res.status(200).json(userRowToMap(result.rows[0]));
    } catch (err) {
      return res.status(500).json({ error: 'Update failed', ...errorDetails(err) });
    }
  });

  router.post('/me/photo', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const photoUrl = `/uploads/photos/${payload.id}_${Date.now()}.jpg`;
      const result = await pool.query(
        'UPDATE users SET photo_url = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
        [photoUrl, payload.id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'user.photo_updated',
        resourceType: 'user',
        resourceId: payload.id,
        req,
      });
      res.status(200).json(userRowToMap(result.rows[0]));
    } catch (err) {
      return res.status(500).json({ error: 'Photo upload failed', ...errorDetails(err) });
    }
  });

  router.delete('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const { password } = req.body;
      if (!password) {
        return res.status(400).json({ error: 'Password is required' });
      }
      const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const valid = await comparePassword(password, userResult.rows[0].password_hash);
      if (!valid) {
        return res.status(400).json({ error: 'Password is incorrect' });
      }
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'auth.account_deletion_requested',
        resourceType: 'user',
        resourceId: payload.id,
        req,
      });
      await deletePostHogPerson(payload.id);
      await pool.query('DELETE FROM users WHERE id = $1', [payload.id]);
      logAuditEventSafe(pool, {
        actorType: 'system',
        action: 'auth.account_deleted',
        resourceType: 'user',
        resourceId: payload.id,
        req,
      });
      res.status(200).json({ message: 'Account deleted successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Account deletion failed', ...errorDetails(err) });
    }
  });

  router.get('/me/export', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const user = userRowToMap(userResult.rows[0]);
      const exportData = await buildUserDataExport(pool, payload.id);
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'auth.data_export',
        resourceType: 'user',
        resourceId: payload.id,
        metadata: exportAuditMetadata(exportData),
        req,
      });
      res.status(200).json({
        user,
        ...exportData,
        exported_at: new Date().toISOString(),
      });
    } catch (err) {
      return res.status(500).json({ error: 'Data export failed', ...errorDetails(err) });
    }
  });
}
