import { v4 as uuidv4 } from 'uuid';
import {
  ORG_COUNT_SELECT,
  extractUserId,
  fetchOrgForUser,
  handleOrgImageUpload,
  loadPrimaryContact,
  orgRowToMap,
  requireOrgAdmin,
  requireSuperAdmin,
  saveOrgImage,
} from './shared.js';
import { publicError } from '../../config/security.js';
import { ORG_ROLE_SUPER_ADMIN, isOrgAdmin, normaliseRole } from '../../lib/orgRoles.js';

export function registerCoreRoutes(router, pool) {
    router.get('/', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const result = await pool.query(
          `SELECT o.*, ou.role,
            ${ORG_COUNT_SELECT}
           FROM organizations o
           JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = $1
           ORDER BY o.name`,
          [userId]
        );
        const orgs = await Promise.all(result.rows.map(async (row) => {
          const primaryContact = await loadPrimaryContact(pool, row.id, row.primary_contact_ref);
          return orgRowToMap({
            ...row,
            role: normaliseRole(row.role),
            primary_contact: primaryContact,
          });
        }));
        res.json(orgs);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:id', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const org = await fetchOrgForUser(pool, userId, req.params.id);
        if (!org) return res.status(404).json({ error: 'Organization not found' });
        res.json(org);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const { name, type, email, phone, address, website, bio, photo_url, logo_url } = req.body;
        const orgId = uuidv4();
        await pool.query(
          'INSERT INTO organizations (id, name, type, email, phone, address, website, bio, photo_url, logo_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)',
          [orgId, name || '', type || 'professional', email || null, phone || null, address || null, website || null, bio || '', photo_url || '', logo_url || '']
        );
        const ouId = uuidv4();
        await pool.query(
          `INSERT INTO organization_users (id, organization_id, user_id, role) VALUES ($1, $2, $3, '${ORG_ROLE_SUPER_ADMIN}')`,
          [ouId, orgId, userId]
        );
        const result = await pool.query(
          `SELECT o.*, '${ORG_ROLE_SUPER_ADMIN}' as role,
            1 as member_count, 0 as external_count, 0 as pet_count
           FROM organizations o WHERE o.id = $1`,
          [orgId]
        );
        res.status(201).json(orgRowToMap({ ...result.rows[0], primary_contact: null }));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.put('/:id', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireSuperAdmin(pool, res, req.params.id, userId))) return;
        const { name, type, email, phone, address, website, bio, photo_url, logo_url } = req.body;
        await pool.query(
          'UPDATE organizations SET name = $1, type = $2, email = $3, phone = $4, address = $5, website = $6, bio = $7, photo_url = $8, logo_url = $9, updated_at = NOW() WHERE id = $10',
          [name || '', type || 'professional', email || null, phone || null, address || null, website || null, bio || '', photo_url || '', logo_url || '', req.params.id]
        );
        const org = await fetchOrgForUser(pool, userId, req.params.id);
        if (!org) return res.status(404).json({ error: 'Organization not found' });
        res.json(org);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.delete('/:id', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireSuperAdmin(pool, res, req.params.id, userId))) return;
        const result = await pool.query('DELETE FROM organizations WHERE id = $1 RETURNING *', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Organization not found' });
        res.json({ deleted: true });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:id/photo', handleOrgImageUpload, async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireOrgAdmin(pool, res, req.params.id, userId))) return;
        if (!req.file) return res.status(400).json({ error: 'No image uploaded' });
        const photoUrl = saveOrgImage(req.file, req.params.id, 'org_photos');
        await pool.query(
          'UPDATE organizations SET photo_url = $1, updated_at = NOW() WHERE id = $2',
          [photoUrl, req.params.id],
        );
        const org = await fetchOrgForUser(pool, userId, req.params.id);
        if (!org) return res.status(404).json({ error: 'Organization not found' });
        res.json(org);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:id/logo', handleOrgImageUpload, async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireOrgAdmin(pool, res, req.params.id, userId))) return;
        if (!req.file) return res.status(400).json({ error: 'No image uploaded' });
        const logoUrl = saveOrgImage(req.file, req.params.id, 'org_logos');
        await pool.query(
          'UPDATE organizations SET logo_url = $1, updated_at = NOW() WHERE id = $2',
          [logoUrl, req.params.id],
        );
        const org = await fetchOrgForUser(pool, userId, req.params.id);
        if (!org) return res.status(404).json({ error: 'Organization not found' });
        res.json(org);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.put('/:orgId/primary-contact', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId } = req.params;
      const { kind, record_id: recordId, recordId: recordIdCamel } = req.body || {};
      const personKind = kind || 'member';
      const personRecordId = recordId || recordIdCamel;
      if (!personRecordId) {
        return res.status(400).json({ error: 'record_id is required' });
      }
      if (personKind !== 'member') {
        return res.status(400).json({ error: 'Primary contact must be a registered member' });
      }
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
        const memberResult = await pool.query(
          `SELECT ou.id, ou.role
           FROM organization_users ou
           WHERE ou.organization_id = $1 AND ou.id = $2`,
          [orgId, personRecordId],
        );
        if (!memberResult.rows.length) {
          return res.status(404).json({ error: 'Person not found' });
        }
        const role = normaliseRole(memberResult.rows[0].role);
        if (!isOrgAdmin(role) || role.startsWith('pending_')) {
          return res.status(400).json({ error: 'Primary contact must be an admin or super admin' });
        }
        const contactRef = `member:${personRecordId}`;
        await pool.query(
          'UPDATE organizations SET primary_contact_ref = $1, updated_at = NOW() WHERE id = $2',
          [contactRef, orgId],
        );
        const org = await fetchOrgForUser(pool, userId, orgId);
        if (!org) return res.status(404).json({ error: 'Organization not found' });
        res.json(org);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.delete('/:orgId/primary-contact', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId } = req.params;
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
        await pool.query(
          'UPDATE organizations SET primary_contact_ref = NULL, updated_at = NOW() WHERE id = $1',
          [orgId],
        );
        const org = await fetchOrgForUser(pool, userId, orgId);
        if (!org) return res.status(404).json({ error: 'Organization not found' });
        res.json(org);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });
}
