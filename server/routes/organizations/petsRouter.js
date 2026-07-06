import { v4 as uuidv4 } from 'uuid';
import { dateToIsoDate, normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { transferOrgPetToUser } from '../../lib/orgPetTransfer.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

export function registerPetsRoutes(router, pool) {
    router.get('/:orgId/pets', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
        const result = await pool.query(
          `SELECT p.*, o.name AS organization_name
           FROM pets p
           LEFT JOIN organizations o ON o.id = p.organization_id
           WHERE p.organization_id = $1
           ORDER BY p.created_at`,
          [req.params.orgId]
        );
        res.json(result.rows.map(r => ({
          id: r.id,
          name: r.name,
          species: r.species,
          breed: r.breed,
          photo_path: r.photo_path || null,
          organization_id: r.organization_id,
          organization_name: r.organization_name || null,
        })));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/pets', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId } = req.params;
      const data = req.body || {};
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const id = data.id || uuidv4();
        const name = data.name;
        const species = data.species;
        if (!name || !species) {
          return res.status(400).json({ error: 'name and species are required' });
        }

        const dateOfBirth = normalizeCalendarDateInput(data.dateOfBirth || data.date_of_birth);
        const neuteredDate = normalizeCalendarDateInput(data.neuteredDate || data.neutered_date);
        const result = await pool.query(
          `INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender,
            bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed,
            photo_path, vet_id, color_index, passed_away, organization_id)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
           RETURNING *`,
          [
            id,
            userId,
            name,
            species,
            data.breed || '',
            data.age ?? null,
            dateOfBirth,
            data.weight ?? null,
            data.gender || null,
            data.bio || '',
            data.insurance || '',
            neuteredDate,
            data.neuterDismissed ?? data.neuter_dismissed ?? false,
            data.chipId || data.chip_id || '',
            data.chipDismissed ?? data.chip_dismissed ?? false,
            data.photoPath || data.photo_path || null,
            data.vetId || data.vet_id || null,
            data.colorValue ?? data.color_index ?? null,
            data.passedAway ?? data.passed_away ?? false,
            orgId,
          ],
        );
        const row = result.rows[0];
        res.status(201).json({
          id: row.id,
          name: row.name,
          species: row.species,
          breed: row.breed || '',
          organization_id: row.organization_id,
          date_of_birth: row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null,
        });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/pets/:petId/transfer', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, petId } = req.params;
      const data = req.body || {};
      const recipientEmail = (data.recipient_email || data.recipientEmail || '').trim();
      const transferType = (data.transfer_type || data.transferType || 'adoption').trim();
      const notes = (data.notes || '').trim();

      if (!recipientEmail) {
        return res.status(400).json({ error: 'Recipient email is required' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const recipientResult = await pool.query(
          'SELECT id FROM users WHERE email = $1',
          [recipientEmail],
        );
        if (recipientResult.rows.length === 0) {
          return res.status(404).json({ error: 'User not found' });
        }

        const result = await transferOrgPetToUser(pool, {
          orgId,
          petId,
          adminId: userId,
          recipientId: recipientResult.rows[0].id,
          transferType,
          notes,
        });
        res.json(result);
      } catch (err) {
        if (err.statusCode === 404) return res.status(404).json({ error: err.message });
        if (err.statusCode === 400) return res.status(400).json({ error: err.message });
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/archived', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
        const result = await pool.query('SELECT * FROM archived_pets WHERE organization_id = $1 ORDER BY created_at DESC', [req.params.orgId]);
        res.json(result.rows);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });
}
