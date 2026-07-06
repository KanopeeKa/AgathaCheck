import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { createNotification, userDisplayName } from '../../lib/notificationHelper.js';
import { transferPetToOrganization } from '../../lib/orgPetTransfer.js';
import { userOwnsPet } from '../../lib/petAccess.js';
import { extractUserId, petRowToMap, withOptionalTransaction } from './shared.js';

export function registerTransferRoutes(router, pool) {
  router.post('/:id/transfer-to-org', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    const data = req.body || {};
    const orgId = data.organization_id || data.organizationId;
    const transferType = (data.transfer_type || data.transferType || 'transfer').trim();
    const notes = (data.notes || '').trim();

    if (!orgId) {
      return res.status(400).json({ error: 'organization_id is required' });
    }

    try {
      const result = await transferPetToOrganization(pool, {
        petId,
        ownerId: userId,
        orgId,
        transferType,
        notes,
      });
      res.json(result);
    } catch (err) {
      if (err.statusCode === 404) return res.status(404).json({ error: err.message });
      if (err.statusCode === 400) return res.status(400).json({ error: err.message });
      if (err.statusCode === 403) return res.status(403).json({ error: err.message });
      res.status(500).json({ error: publicError(err) });
    }
  });

  async function withOptionalTransaction(pool, fn) {
    if (typeof pool.connect === 'function') {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const result = await fn(client);
        await client.query('COMMIT');
        return result;
      } catch (err) {
        try {
          await client.query('ROLLBACK');
        } catch (_) {
          /* ignore */
        }
        throw err;
      } finally {
        client.release();
      }
    }
    return fn(pool);
  }

  router.post('/:id/transfer', async (req, res) => {
    const ownerId = extractUserId(req);
    if (!ownerId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    const data = req.body || {};
    const recipientEmail = (data.recipient_email || data.recipientEmail || '').trim();
    const confirmationName = (data.confirmation_name || data.confirmationName || '').trim();

    if (!recipientEmail) {
      return res.status(400).json({ error: 'Recipient email is required' });
    }
    if (!confirmationName) {
      return res.status(400).json({ error: 'Confirmation name is required' });
    }

    try {
      if (!(await userOwnsPet(pool, petId, ownerId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }

      const petResult = await pool.query(
        'SELECT id, name, species, organization_id, user_id FROM pets WHERE id = $1',
        [petId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const pet = petResult.rows[0];
      if (pet.name.trim().toLowerCase() !== confirmationName.toLowerCase()) {
        return res.status(400).json({ error: 'Pet name confirmation does not match' });
      }

      const recipientResult = await pool.query(
        'SELECT id, email, first_name, last_name FROM users WHERE email = $1',
        [recipientEmail],
      );
      if (recipientResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const recipient = recipientResult.rows[0];
      if (recipient.id === ownerId) {
        return res.status(400).json({ error: 'Cannot transfer a pet to yourself' });
      }

      const ownerResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [ownerId],
      );
      const ownerName = userDisplayName(ownerResult.rows[0] || {});
      const recipientName = userDisplayName(recipient);

      const updatedPet = await withOptionalTransaction(pool, async (db) => {
        const updateResult = await db.query(
          'UPDATE pets SET user_id = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
          [recipient.id, petId],
        );

        await db.query(
          'DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2',
          [petId, recipient.id],
        );

        const formerAccessId = uuidv4();
        await db.query(
          `INSERT INTO pet_access (id, pet_id, user_id, role, invited_by, hidden)
           VALUES ($1, $2, $3, 'shared', $4, false)
           ON CONFLICT (pet_id, user_id)
           DO UPDATE SET role = 'shared', hidden = false, invited_by = $4, updated_at = NOW()`,
          [formerAccessId, petId, ownerId, recipient.id],
        );

        const archiveId = uuidv4();
        await db.query(
          `INSERT INTO archived_pets (
             id, organization_id, user_id, pet_id, pet_name, species,
             transfer_type, transferred_to_user_id, notes
           ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [
            archiveId,
            pet.organization_id || null,
            ownerId,
            petId,
            pet.name,
            pet.species || '',
            'user_to_user',
            recipient.id,
            '',
          ],
        );

        return updateResult.rows[0];
      });

      await createNotification(pool, {
        userId: recipient.id,
        petId,
        petName: pet.name,
        title: 'Pet ownership transferred',
        message: `${ownerName} transferred ownership of ${pet.name} to you.`,
        type: 'general',
      });

      await createNotification(pool, {
        userId: ownerId,
        petId,
        petName: pet.name,
        title: 'Pet transferred',
        message: `You transferred ${pet.name} to ${recipientName}. You can still view the pet as a shared follower.`,
        type: 'general',
      });

      res.json({
        transferred: true,
        pet_id: petId,
        new_owner_id: recipient.id,
        pet: petRowToMap(updatedPet),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
