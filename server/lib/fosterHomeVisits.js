import { v4 as uuidv4 } from 'uuid';

import { logAuditEventSafe } from './audit.js';
import { dateToIsoDate, normalizeCalendarDateInput } from './calendarDate.js';
import { hasPermissionForUser } from './orgPermissions.js';

export const HOME_VISIT_RESOURCE = 'foster_home_visit';
export const VISIT_STATUS_SCHEDULED = 'scheduled';
export const VISIT_STATUS_CANCELLED = 'cancelled';
export const VISIT_STATUS_VALIDATED = 'validated';
export const OUTCOME_YES = 'yes';
export const OUTCOME_NO = 'no';
export const AUDIT_VISIT_SCHEDULED = 'FOSTER_HOME_VISIT_SCHEDULED';
export const AUDIT_VISIT_RESCHEDULED = 'FOSTER_HOME_VISIT_RESCHEDULED';
export const AUDIT_VISIT_CANCELLED = 'FOSTER_HOME_VISIT_CANCELLED';
export const AUDIT_VISIT_VALIDATED = 'FOSTER_HOME_VISIT_VALIDATED';

const VALID_OUTCOMES = new Set([OUTCOME_YES, OUTCOME_NO]);
const TIME_PATTERN = /^([01][0-9]|2[0-3]):[0-5][0-9]$/;

export const DEFAULT_HOME_VISIT_CHECKLIST = Object.freeze([
  { id: 'HV01', label: 'Property access and entry confirmed' },
  { id: 'HV02', label: 'Home safety assessment completed' },
  { id: 'HV03', label: 'Pet accommodation reviewed' },
  { id: 'HV04', label: 'Household members present and interviewed' },
  { id: 'HV05', label: 'Foster agreement expectations discussed' },
]);

function defaultChecklistItems() {
  return DEFAULT_HOME_VISIT_CHECKLIST.map((item) => ({
    id: item.id, label: item.label, checked: false, note: '',
  }));
}

function parseChecklistItems(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : defaultChecklistItems();
    } catch { return defaultChecklistItems(); }
  }
  return defaultChecklistItems();
}

export function visitToMap(row, { includeAddress = true } = {}) {
  const map = {
    id: row.id,
    organization_id: row.organization_id,
    org_foster_parent_id: row.org_foster_parent_id,
    status: row.status,
    visit_date: dateToIsoDate(row.visit_date),
    visit_time: row.visit_time || null,
    notes: row.notes || '',
    checklist_items: parseChecklistItems(row.checklist_items),
    outcome: row.outcome || null,
    outcome_reason: row.outcome_reason || '',
    scheduled_by: row.scheduled_by || null,
    validated_by: row.validated_by || null,
    validated_at: row.validated_at || null,
    cancelled_by: row.cancelled_by || null,
    cancelled_at: row.cancelled_at || null,
    cancel_reason: row.cancel_reason || '',
    created_at: row.created_at || null,
    updated_at: row.updated_at || null,
  };
  if (includeAddress) map.address = row.address || '';
  if (row.attendees) {
    map.attendees = row.attendees.map((a) => ({
      id: a.id, user_id: a.user_id || null, display_name: a.display_name || '',
    }));
  }
  if (row.photos) {
    map.photos = row.photos.map((p) => ({
      id: p.id, storage_path: p.storage_path, caption: p.caption || '',
      uploaded_by: p.uploaded_by || null, created_at: p.created_at || null,
    }));
  }
  return map;
}

export function visitToExportMap(row) {
  return visitToMap(row, { includeAddress: false });
}

function auditVisit(pool, event) {
  logAuditEventSafe(pool, { resourceType: HOME_VISIT_RESOURCE, ...event });
}

function normaliseVisitTime(value) {
  const raw = String(value || '').trim();
  if (!raw) return '09:00';
  return TIME_PATTERN.test(raw) ? raw : null;
}

function normaliseAttendees(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.map((entry) => ({
    user_id: (entry.user_id || entry.userId || '').trim() || null,
    display_name: (entry.display_name || entry.displayName || '').trim(),
  })).filter((entry) => entry.user_id || entry.display_name);
}

function parseVisitDateTime(visitDate, visitTime, fallbackRow = null) {
  const normalisedDate = normalizeCalendarDateInput(
    visitDate ?? fallbackRow?.visit_date,
  );
  if (!normalisedDate) {
    return { error: 'visit_date is required (YYYY-MM-DD)', status: 400 };
  }
  const normalisedTime = normaliseVisitTime(visitTime ?? fallbackRow?.visit_time);
  if (!normalisedTime) {
    return { error: 'visit_time must be HH:MM (24h)', status: 400 };
  }
  return { normalisedDate, normalisedTime };
}

export async function assertFosterParentInOrg(pool, orgId, fosterParentId) {
  const result = await pool.query(
    'SELECT id FROM org_foster_parents WHERE organization_id = $1 AND id = $2',
    [orgId, fosterParentId],
  );
  if (result.rows.length === 0) {
    return { error: 'Foster parent not found', status: 404 };
  }
  return { ok: true };
}

async function assertNoActiveScheduledVisit(pool, orgId, fosterParentId) {
  const result = await pool.query(
    `SELECT id FROM foster_home_visits
     WHERE organization_id = $1 AND org_foster_parent_id = $2 AND status = $3
     LIMIT 1`,
    [orgId, fosterParentId, VISIT_STATUS_SCHEDULED],
  );
  if (result.rows.length > 0) {
    return { error: 'An active scheduled home visit already exists', status: 409 };
  }
  return { ok: true };
}

async function replaceAttendees(client, visitId, attendees) {
  await client.query('DELETE FROM foster_home_visit_attendees WHERE home_visit_id = $1', [visitId]);
  for (const attendee of attendees) {
    await client.query(
      `INSERT INTO foster_home_visit_attendees (id, home_visit_id, user_id, display_name)
       VALUES ($1, $2, $3, $4)`,
      [uuidv4(), visitId, attendee.user_id, attendee.display_name],
    );
  }
}

async function loadVisitExtras(client, visitId) {
  const [attendees, photos] = await Promise.all([
    client.query(
      `SELECT id, user_id, display_name FROM foster_home_visit_attendees
       WHERE home_visit_id = $1 ORDER BY created_at ASC`,
      [visitId],
    ),
    client.query(
      `SELECT id, storage_path, caption, uploaded_by, created_at
       FROM foster_home_visit_photos WHERE home_visit_id = $1 ORDER BY created_at ASC`,
      [visitId],
    ),
  ]);
  return { attendees: attendees.rows, photos: photos.rows };
}

async function loadVisitById(pool, orgId, visitId) {
  const result = await pool.query(
    'SELECT * FROM foster_home_visits WHERE id = $1 AND organization_id = $2',
    [visitId, orgId],
  );
  if (result.rows.length === 0) {
    return { error: 'Home visit not found', status: 404 };
  }
  const extras = await loadVisitExtras(pool, visitId);
  return { row: { ...result.rows[0], ...extras } };
}

async function requireScheduledVisit(pool, orgId, visitId) {
  const loaded = await loadVisitById(pool, orgId, visitId);
  if (loaded.error) return loaded;
  if (loaded.row.status !== VISIT_STATUS_SCHEDULED) {
    return { error: 'Only scheduled visits can be modified', status: 409 };
  }
  return loaded;
}

export async function hasValidatedHomeVisitYes(pool, orgId, fosterParentId) {
  if (!fosterParentId) return false;
  const result = await pool.query(
    `SELECT 1 FROM foster_home_visits
     WHERE organization_id = $1 AND org_foster_parent_id = $2
       AND status = $3 AND outcome = $4 LIMIT 1`,
    [orgId, fosterParentId, VISIT_STATUS_VALIDATED, OUTCOME_YES],
  );
  return result.rows.length > 0;
}

export async function loadHomeVisitsForFosterParent(pool, orgId, fosterParentId) {
  const parentCheck = await assertFosterParentInOrg(pool, orgId, fosterParentId);
  if (parentCheck.error) return parentCheck;
  const result = await pool.query(
    `SELECT * FROM foster_home_visits
     WHERE organization_id = $1 AND org_foster_parent_id = $2
     ORDER BY visit_date DESC, visit_time DESC, created_at DESC`,
    [orgId, fosterParentId],
  );
  const visits = await Promise.all(result.rows.map(async (row) => ({
    ...row,
    ...(await loadVisitExtras(pool, row.id)),
  })));
  return { visits };
}

export async function scheduleHomeVisit(pool, {
  orgId, fosterParentId, visitDate, visitTime, address = '', notes = '',
  attendees = [], actorUserId, req = null,
}) {
  const parentCheck = await assertFosterParentInOrg(pool, orgId, fosterParentId);
  if (parentCheck.error) return parentCheck;
  const parsed = parseVisitDateTime(visitDate, visitTime);
  if (parsed.error) return parsed;
  const activeCheck = await assertNoActiveScheduledVisit(pool, orgId, fosterParentId);
  if (activeCheck.error) return activeCheck;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const id = uuidv4();
    await client.query(
      `INSERT INTO foster_home_visits (
         id, organization_id, org_foster_parent_id, status,
         visit_date, visit_time, address, notes, checklist_items, scheduled_by
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10)`,
      [
        id, orgId, fosterParentId, VISIT_STATUS_SCHEDULED,
        parsed.normalisedDate, parsed.normalisedTime,
        String(address || '').trim(), String(notes || '').trim(),
        JSON.stringify(defaultChecklistItems()), actorUserId || null,
      ],
    );
    await replaceAttendees(client, id, normaliseAttendees(attendees));
    await client.query('COMMIT');
    auditVisit(pool, {
      actorUserId, action: AUDIT_VISIT_SCHEDULED, resourceId: id, orgId, req,
      metadata: {
        org_foster_parent_id: fosterParentId,
        visit_date: parsed.normalisedDate,
        visit_time: parsed.normalisedTime,
      },
    });
    const loaded = await loadVisitById(pool, orgId, id);
    return { visit: loaded.row, status: 201 };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export async function rescheduleHomeVisit(pool, {
  orgId, visitId, visitDate, visitTime, address, notes, attendees, actorUserId, req = null,
}) {
  const loaded = await requireScheduledVisit(pool, orgId, visitId);
  if (loaded.error) return loaded;
  const parsed = parseVisitDateTime(visitDate, visitTime, loaded.row);
  if (parsed.error) return parsed;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `UPDATE foster_home_visits SET visit_date = $1, visit_time = $2,
         address = COALESCE($3, address), notes = COALESCE($4, notes), updated_at = NOW()
       WHERE id = $5 AND organization_id = $6`,
      [
        parsed.normalisedDate, parsed.normalisedTime,
        address != null ? String(address).trim() : null,
        notes != null ? String(notes).trim() : null,
        visitId, orgId,
      ],
    );
    if (attendees != null) {
      await replaceAttendees(client, visitId, normaliseAttendees(attendees));
    }
    await client.query('COMMIT');
    auditVisit(pool, {
      actorUserId, action: AUDIT_VISIT_RESCHEDULED, resourceId: visitId, orgId, req,
      metadata: { visit_date: parsed.normalisedDate, visit_time: parsed.normalisedTime },
    });
    const refreshed = await loadVisitById(pool, orgId, visitId);
    return { visit: refreshed.row, status: 200 };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export async function cancelHomeVisit(pool, {
  orgId, visitId, cancelReason = '', actorUserId, req = null,
}) {
  const loaded = await requireScheduledVisit(pool, orgId, visitId);
  if (loaded.error) return loaded;
  await pool.query(
    `UPDATE foster_home_visits SET status = $1, cancel_reason = $2, cancelled_by = $3,
       cancelled_at = NOW(), updated_at = NOW()
     WHERE id = $4 AND organization_id = $5`,
    [VISIT_STATUS_CANCELLED, String(cancelReason || '').trim(), actorUserId, visitId, orgId],
  );
  auditVisit(pool, {
    actorUserId, action: AUDIT_VISIT_CANCELLED, resourceId: visitId, orgId, req,
    metadata: { cancel_reason: String(cancelReason || '').trim() },
  });
  const refreshed = await loadVisitById(pool, orgId, visitId);
  return { visit: refreshed.row, status: 200 };
}

export async function updateHomeVisitChecklist(pool, {
  orgId, visitId, checklistItems, notes,
}) {
  const loaded = await requireScheduledVisit(pool, orgId, visitId);
  if (loaded.error) return loaded;
  if (!Array.isArray(checklistItems)) {
    return { error: 'checklist_items must be an array', status: 400 };
  }
  await pool.query(
    `UPDATE foster_home_visits SET checklist_items = $1::jsonb,
       notes = COALESCE($2, notes), updated_at = NOW()
     WHERE id = $3 AND organization_id = $4`,
    [JSON.stringify(checklistItems), notes != null ? String(notes).trim() : null, visitId, orgId],
  );
  const refreshed = await loadVisitById(pool, orgId, visitId);
  return { visit: refreshed.row, status: 200 };
}

export async function addHomeVisitPhoto(pool, {
  orgId, visitId, storagePath, caption = '', actorUserId,
}) {
  const loaded = await loadVisitById(pool, orgId, visitId);
  if (loaded.error) return loaded;
  if (loaded.row.status === VISIT_STATUS_CANCELLED) {
    return { error: 'Cannot add photos to a cancelled visit', status: 409 };
  }
  const path = String(storagePath || '').trim();
  if (!path) return { error: 'storage_path is required', status: 400 };
  await pool.query(
    `INSERT INTO foster_home_visit_photos (id, home_visit_id, storage_path, caption, uploaded_by)
     VALUES ($1, $2, $3, $4, $5)`,
    [uuidv4(), visitId, path, String(caption || '').trim(), actorUserId || null],
  );
  const refreshed = await loadVisitById(pool, orgId, visitId);
  return { visit: refreshed.row, status: 201 };
}

export async function validateHomeVisit(pool, {
  orgId, visitId, outcome, outcomeReason = '', actorUserId, req = null,
}) {
  const normalisedOutcome = String(outcome || '').trim().toLowerCase();
  if (!VALID_OUTCOMES.has(normalisedOutcome)) {
    return { error: 'outcome must be yes or no', status: 400 };
  }
  if (normalisedOutcome === OUTCOME_NO && !String(outcomeReason || '').trim()) {
    return { error: 'outcome_reason is required when outcome is no', status: 400 };
  }
  if (!(await hasPermissionForUser(pool, actorUserId, orgId, 'home_visits'))) {
    return { error: 'Forbidden', status: 403 };
  }
  const loaded = await requireScheduledVisit(pool, orgId, visitId);
  if (loaded.error) return loaded;
  await pool.query(
    `UPDATE foster_home_visits SET status = $1, outcome = $2, outcome_reason = $3,
       validated_by = $4, validated_at = NOW(), updated_at = NOW()
     WHERE id = $5 AND organization_id = $6`,
    [
      VISIT_STATUS_VALIDATED, normalisedOutcome, String(outcomeReason || '').trim(),
      actorUserId, visitId, orgId,
    ],
  );
  auditVisit(pool, {
    actorUserId, action: AUDIT_VISIT_VALIDATED, resourceId: visitId, orgId, req,
    metadata: { outcome: normalisedOutcome, org_foster_parent_id: loaded.row.org_foster_parent_id },
  });
  const refreshed = await loadVisitById(pool, orgId, visitId);
  return { visit: refreshed.row, status: 200 };
}

export async function requireHomeVisitsPermission(pool, res, orgId, userId) {
  if (await hasPermissionForUser(pool, userId, orgId, 'home_visits')) return true;
  res.status(403).json({ error: 'Forbidden' });
  return false;
}
