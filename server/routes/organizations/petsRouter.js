import { v4 as uuidv4 } from 'uuid';
import { dateToIsoDate, normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import {
  maybeCreateWeightEntryFromPetPayload,
  refreshPetWeightCache,
} from '../../lib/petWeightSync.js';
import { OPEN_PLACEMENT_STATUSES } from '../../lib/fosterPlacements.js';
import { transferOrgPetToUser } from '../../lib/orgPetTransfer.js';
import {
  requestCustodyTransfer,
  TRANSFER_INDIVIDUAL,
  TRANSFER_ORG_TO_ORG,
  TRANSFER_RETURN,
} from '../../lib/custodyTransfers.js';
import { petIsFosteredByOrg, setOrgGuardianAndCare } from '../../lib/petCustody.js';
import { extractUserId, requirePermission } from './shared.js';
import { publicError } from '../../config/security.js';

export function registerPetsRoutes(router, pool) {
    router.get('/:orgId/pets', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requirePermission(pool, res, req.params.orgId, userId, 'manage_pets'))) return;
        const result = await pool.query(
          `SELECT p.*, o.name AS organization_name,
            (SELECT fp.end_date
             FROM foster_placements fp
             WHERE fp.pet_id = p.id
               AND fp.status = ANY($2::text[])
             ORDER BY fp.created_at DESC
             LIMIT 1) AS foster_end_date,
            (SELECT fp.status
             FROM foster_placements fp
             WHERE fp.pet_id = p.id
               AND fp.status = ANY($2::text[])
             ORDER BY fp.created_at DESC
             LIMIT 1) AS foster_placement_status,
            (SELECT NULLIF(TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')), '')
             FROM foster_placements fp
             LEFT JOIN users u ON u.id = fp.foster_user_id
             WHERE fp.pet_id = p.id
               AND fp.status = ANY($2::text[])
             ORDER BY fp.created_at DESC
             LIMIT 1) AS foster_name
           FROM pets p
           LEFT JOIN organizations o ON o.id = p.organization_id
           WHERE p.organization_id = $1
           ORDER BY p.created_at`,
          [req.params.orgId, OPEN_PLACEMENT_STATUSES]
        );
        res.json(result.rows.map(r => ({
          id: r.id,
          name: r.name,
          species: r.species,
          breed: r.breed,
          photo_path: r.photo_path || null,
          passed_away: r.passed_away || false,
          organization_id: r.organization_id,
          organization_name: r.organization_name || null,
          foster_placement_status: r.foster_placement_status || null,
          foster_name: r.foster_name || null,
          foster_end_date: r.foster_end_date ? dateToIsoDate(r.foster_end_date) : null,
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
        if (!(await requirePermission(pool, res, orgId, userId, 'manage_pets'))) return;

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
        await setOrgGuardianAndCare(pool, id, orgId);
        await maybeCreateWeightEntryFromPetPayload(pool, {
          petId: id,
          userId,
          weight: data.weight,
        });
        await refreshPetWeightCache(pool, id);
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
        if (!(await requirePermission(pool, res, orgId, userId, 'transfer_pet_ownership'))) return;

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
        res.status(201).json(result);
      } catch (err) {
        if (err.statusCode === 404) return res.status(404).json({ error: err.message });
        if (err.statusCode === 400) return res.status(400).json({ error: err.message });
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/pets/:petId/custody-transfers', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, petId } = req.params;
      const data = req.body || {};
      const transferKind = (data.transfer_kind || data.transferKind || '').trim();
      const toOrgId = data.to_org_id || data.toOrgId || null;
      const toUserId = data.to_user_id || data.toUserId || null;
      const notes = (data.notes || '').trim();

      if (![TRANSFER_INDIVIDUAL, TRANSFER_ORG_TO_ORG, TRANSFER_RETURN].includes(transferKind)) {
        return res.status(400).json({ error: 'Invalid transfer_kind' });
      }

      try {
        if (transferKind === TRANSFER_RETURN) {
          if (!toOrgId) {
            return res.status(400).json({ error: 'to_org_id is required' });
          }
        } else if (!(await requirePermission(pool, res, orgId, userId, 'transfer_pet_ownership'))) {
          return;
        }

        const result = await requestCustodyTransfer(pool, {
          petId,
          transferKind,
          requestedByUserId: userId,
          requestingOrgId: transferKind === TRANSFER_RETURN ? null : orgId,
          toUserId,
          toOrgId,
          notes,
        });
        res.status(201).json(result);
      } catch (err) {
        if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.put('/:orgId/pets/:petId/home-hidden', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, petId } = req.params;
      const hidden = req.body?.hidden ?? req.body?.home_hidden ?? true;

      try {
        if (!(await requirePermission(pool, res, orgId, userId, 'manage_pets'))) return;
        if (!(await petIsFosteredByOrg(pool, petId, orgId))) {
          return res.status(400).json({ error: 'Only fostered org pets can be hidden from the home list' });
        }

        if (hidden) {
          await pool.query(
            `INSERT INTO org_pet_home_hidden (user_id, pet_id, organization_id)
             VALUES ($1, $2, $3)
             ON CONFLICT (user_id, pet_id) DO UPDATE SET organization_id = $3`,
            [userId, petId, orgId],
          );
        } else {
          await pool.query(
            'DELETE FROM org_pet_home_hidden WHERE user_id = $1 AND pet_id = $2',
            [userId, petId],
          );
        }
        res.json({ hidden: Boolean(hidden) });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/home-hidden', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId } = req.params;
      try {
        if (!(await requirePermission(pool, res, orgId, userId, 'manage_pets'))) return;
        const result = await pool.query(
          `SELECT oh.pet_id, p.name AS pet_name, oh.created_at
           FROM org_pet_home_hidden oh
           JOIN pets p ON p.id = oh.pet_id
           WHERE oh.user_id = $1 AND oh.organization_id = $2
           ORDER BY oh.created_at DESC`,
          [userId, orgId],
        );
        res.json(result.rows);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/archived', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requirePermission(pool, res, req.params.orgId, userId, 'manage_pets'))) return;
        const result = await pool.query('SELECT * FROM archived_pets WHERE organization_id = $1 ORDER BY created_at DESC', [req.params.orgId]);
        res.json(result.rows);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });
}
