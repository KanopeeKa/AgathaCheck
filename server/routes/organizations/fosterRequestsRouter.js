import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from '../../lib/audit.js';
import {
  assertPetsInOrg,
  loadEligibleTargets,
  loadRequestDetail,
  requestToMap,
  validateCreatePayload,
  validateResponsePayload,
} from '../../lib/fosterRequests.js';
import { extractUserId, requireMember, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

async function insertRequestChildren(client, requestId, petIds, targetIds) {
  for (const petId of petIds) {
    await client.query(
      `INSERT INTO foster_request_pets (id, foster_request_id, pet_id)
       VALUES ($1, $2, $3)`,
      [uuidv4(), requestId, petId],
    );
  }

  for (const targetId of targetIds) {
    await client.query(
      `INSERT INTO foster_request_targets (id, foster_request_id, org_foster_parent_id)
       VALUES ($1, $2, $3)`,
      [uuidv4(), requestId, targetId],
    );
  }
}

async function createPendingResponses(client, requestId, targetIds) {
  for (const targetId of targetIds) {
    await client.query(
      `INSERT INTO foster_request_responses (
         id, foster_request_id, org_foster_parent_id, response
       ) VALUES ($1, $2, $3, 'pending')`,
      [uuidv4(), requestId, targetId],
    );
  }
}

async function sendRequest(client, {
  requestId,
  orgId,
  actorUserId,
  req,
  pool,
}) {
  const eligibleTargets = await client.query(
    `SELECT frt.org_foster_parent_id
     FROM foster_request_targets frt
     JOIN org_foster_parents fp ON fp.id = frt.org_foster_parent_id
     WHERE frt.foster_request_id = $1
       AND fp.organization_id = $2
       AND fp.approval_state = 'approved'
       AND fp.opt_out_at IS NULL`,
    [requestId, orgId],
  );

  if (eligibleTargets.rows.length === 0) {
    return { error: 'No eligible foster parent targets remain for this request', status: 400 };
  }

  const targetIds = eligibleTargets.rows.map((row) => row.org_foster_parent_id);
  await createPendingResponses(client, requestId, targetIds);

  const updateResult = await client.query(
    `UPDATE foster_requests
     SET status = 'sent',
         sent_at = NOW(),
         updated_at = NOW()
     WHERE id = $1 AND organization_id = $2 AND status = 'draft'
     RETURNING *`,
    [requestId, orgId],
  );

  if (!updateResult.rows.length) {
    return { error: 'Foster request not found or already sent', status: 404 };
  }

  logAuditEventSafe(pool, {
    actorUserId,
    action: 'foster_request_sent',
    resourceType: 'foster_request',
    resourceId: requestId,
    orgId,
    metadata: { target_count: targetIds.length },
    req,
  });

  return { row: updateResult.rows[0] };
}

export function registerFosterRequestsRoutes(router, pool) {
  router.get('/:orgId/foster-requests', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `SELECT fr.*,
                COALESCE(
                  (
                    SELECT json_agg(frp.pet_id ORDER BY p.name)
                    FROM foster_request_pets frp
                    JOIN pets p ON p.id = frp.pet_id
                    WHERE frp.foster_request_id = fr.id
                  ),
                  '[]'::json
                ) AS pet_ids,
                (
                  SELECT COUNT(*)::int
                  FROM foster_request_targets frt
                  WHERE frt.foster_request_id = fr.id
                ) AS target_count,
                (
                  SELECT COUNT(*) FILTER (WHERE frr.response = 'pending')::int
                  FROM foster_request_responses frr
                  WHERE frr.foster_request_id = fr.id
                ) AS pending_count,
                (
                  SELECT COUNT(*) FILTER (WHERE frr.response = 'can_help')::int
                  FROM foster_request_responses frr
                  WHERE frr.foster_request_id = fr.id
                ) AS can_help_count,
                (
                  SELECT COUNT(*) FILTER (WHERE frr.response = 'cannot_help')::int
                  FROM foster_request_responses frr
                  WHERE frr.foster_request_id = fr.id
                ) AS cannot_help_count
         FROM foster_requests fr
         WHERE fr.organization_id = $1
         ORDER BY fr.created_at DESC`,
        [orgId],
      );

      res.json(result.rows.map((row) => requestToMap(row, {
        pets: (row.pet_ids || []).map((petId) => ({ pet_id: petId, pet_name: '' })),
        targets: [],
        responses: [],
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-requests', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const validation = validateCreatePayload(req.body || {});

    if (validation.error) {
      return res.status(400).json({ error: validation.error });
    }

    const { message, petIds, targetIds, sendNow } = validation;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        const foundPetIds = await assertPetsInOrg(client, orgId, petIds);
        if (foundPetIds.length !== petIds.length) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: 'One or more pets were not found for this organization' });
        }

        const eligibleTargets = await loadEligibleTargets(client, orgId, targetIds);
        if (eligibleTargets.length !== targetIds.length) {
          await client.query('ROLLBACK');
          return res.status(400).json({
            error: 'One or more foster parent targets are not approved or have opted out',
          });
        }

        const requestId = uuidv4();
        const insertResult = await client.query(
          `INSERT INTO foster_requests (
             id, organization_id, message, status, created_by
           ) VALUES ($1, $2, $3, 'draft', $4)
           RETURNING *`,
          [requestId, orgId, message, userId],
        );

        await insertRequestChildren(
          client,
          requestId,
          petIds,
          eligibleTargets.map((row) => row.org_foster_parent_id),
        );

        if (sendNow) {
          const sendResult = await sendRequest(client, {
            requestId,
            orgId,
            actorUserId: userId,
            req,
            pool,
          });
          if (sendResult.error) {
            await client.query('ROLLBACK');
            return res.status(sendResult.status).json({ error: sendResult.error });
          }
        }

        await client.query('COMMIT');

        const detail = await loadRequestDetail(client, requestId, orgId);
        res.status(201).json(detail);
      } catch (txErr) {
        try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
        throw txErr;
      } finally {
        client.release();
      }
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-requests/:id/send', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: requestId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        const existing = await client.query(
          `SELECT id, status
           FROM foster_requests
           WHERE id = $1 AND organization_id = $2`,
          [requestId, orgId],
        );
        if (!existing.rows.length) {
          await client.query('ROLLBACK');
          return res.status(404).json({ error: 'Foster request not found' });
        }
        if (existing.rows[0].status !== 'draft') {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: 'Only draft foster requests can be sent' });
        }

        const sendResult = await sendRequest(client, {
          requestId,
          orgId,
          actorUserId: userId,
          req,
          pool,
        });
        if (sendResult.error) {
          await client.query('ROLLBACK');
          return res.status(sendResult.status).json({ error: sendResult.error });
        }

        await client.query('COMMIT');
        const detail = await loadRequestDetail(client, requestId, orgId);
        res.json(detail);
      } catch (txErr) {
        try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
        throw txErr;
      } finally {
        client.release();
      }
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/foster-requests/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: requestId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const detail = await loadRequestDetail(pool, requestId, orgId);
      if (!detail) {
        return res.status(404).json({ error: 'Foster request not found' });
      }
      res.json(detail);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-requests/:id/responses', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: requestId } = req.params;
    const validation = validateResponsePayload(req.body || {});

    if (validation.error) {
      return res.status(400).json({ error: validation.error });
    }

    const { response, message, earliestAvailability } = validation;

    try {
      if (!(await requireMember(pool, res, orgId, userId))) return;

      const targetResult = await pool.query(
        `SELECT fr.id AS foster_request_id,
                fr.status,
                frt.org_foster_parent_id
         FROM foster_requests fr
         JOIN foster_request_targets frt ON frt.foster_request_id = fr.id
         JOIN org_foster_parents fp ON fp.id = frt.org_foster_parent_id
         WHERE fr.id = $1
           AND fr.organization_id = $2
           AND fr.status = 'sent'
           AND fp.user_id = $3`,
        [requestId, orgId, userId],
      );

      if (!targetResult.rows.length) {
        return res.status(404).json({ error: 'Foster request not found for this foster parent' });
      }

      const orgFosterParentId = targetResult.rows[0].org_foster_parent_id;
      const responseId = uuidv4();
      const capacityConfirmedAt = response === 'can_help' ? new Date() : null;

      const updateResult = await pool.query(
        `UPDATE foster_request_responses
         SET response = $1,
             message = $2,
             earliest_availability = $3,
             capacity_confirmed_at = $4,
             responded_at = NOW(),
             updated_at = NOW()
         WHERE foster_request_id = $5
           AND org_foster_parent_id = $6
         RETURNING *`,
        [
          response,
          message,
          earliestAvailability,
          capacityConfirmedAt,
          requestId,
          orgFosterParentId,
        ],
      );

      let responseRow;
      if (updateResult.rows.length) {
        responseRow = updateResult.rows[0];
      } else {
        const insertResult = await pool.query(
          `INSERT INTO foster_request_responses (
             id, foster_request_id, org_foster_parent_id, response, message,
             earliest_availability, capacity_confirmed_at, responded_at
           ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
           RETURNING *`,
          [
            responseId,
            requestId,
            orgFosterParentId,
            response,
            message,
            earliestAvailability,
            capacityConfirmedAt,
          ],
        );
        responseRow = insertResult.rows[0];
      }

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'foster_request_response_received',
        resourceType: 'foster_request_response',
        resourceId: responseRow.id,
        orgId,
        metadata: {
          foster_request_id: requestId,
          response,
          org_foster_parent_id: orgFosterParentId,
        },
        req,
      });

      const detail = await loadRequestDetail(pool, requestId, orgId);
      res.json(detail);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
