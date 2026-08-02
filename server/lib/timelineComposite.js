import { dateToIsoDate } from './calendarDate.js';
import { userDisplayName } from './notificationHelper.js';
import { userOwnsPet } from './petAccess.js';
import { userCanAccessOrgPetOperational } from './orgPetViewAccess.js';
import { orgPetViewerRolesSql } from './orgRoles.js';

function isoDate(value) {
  if (!value) return null;
  return dateToIsoDate(value);
}

function dateOnlyMs(value) {
  if (!value) return null;
  const iso = isoDate(value);
  return iso ? Date.parse(`${iso}T00:00:00Z`) : null;
}

async function viewerCanSeeGuardianName(pool, petId, viewerId, guardianUserId) {
  if (!guardianUserId) return false;
  if (String(guardianUserId) === String(viewerId)) return true;
  if (await userOwnsPet(pool, petId, viewerId)) return true;
  const orgAdmin = await pool.query(
    `SELECT 1 FROM pets p
     JOIN organization_users ou ON ou.organization_id = p.organization_id
     WHERE p.id = $1 AND ou.user_id = $2
       AND ou.role IN (${orgPetViewerRolesSql()})
     LIMIT 1`,
    [petId, viewerId],
  );
  return orgAdmin.rows.length > 0;
}

async function loadCustodySegments(pool, petId, viewerId) {
  const result = await pool.query(
    `SELECT ct.*,
            TRIM(COALESCE(tu.first_name, '') || ' ' || COALESCE(tu.last_name, '')) AS to_user_name,
            tu.email AS to_user_email
     FROM custody_transfers ct
     LEFT JOIN users tu ON tu.id = ct.to_user_id
     WHERE ct.pet_id = $1 AND ct.status = 'accepted'
     ORDER BY COALESCE(ct.responded_at, ct.created_at) ASC`,
    [petId],
  );

  const segments = [];
  for (const row of result.rows) {
    const start = isoDate(row.responded_at || row.created_at);
    const showName = row.to_user_id
      ? await viewerCanSeeGuardianName(pool, petId, viewerId, row.to_user_id)
      : false;
    segments.push({
      kind: 'custody',
      id: row.id,
      start_date: start,
      end_date: null,
      title: 'Custody transfer',
      description: (row.notes || '').trim(),
      guardian_name: showName
        ? (row.to_user_name?.trim() || userDisplayName({ email: row.to_user_email }))
        : null,
      foster_name: null,
      fillable: false,
    });
  }
  return segments;
}

async function loadFosteringSessions(pool, petId) {
  const result = await pool.query(
    `SELECT fp.id,
            fp.start_date,
            fp.end_date,
            fp.notes,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
            u.email AS foster_email
     FROM foster_placements fp
     LEFT JOIN users u ON u.id = fp.foster_user_id
     WHERE fp.pet_id = $1
       AND fp.start_date IS NOT NULL
     ORDER BY fp.start_date ASC`,
    [petId],
  );

  return result.rows.map((row) => ({
    kind: 'fostering_session',
    id: row.id,
    start_date: isoDate(row.start_date),
    end_date: isoDate(row.end_date),
    title: 'Fostering session',
    description: (row.notes || '').trim(),
    guardian_name: null,
    foster_name: row.foster_name?.trim() || userDisplayName({ email: row.foster_email }),
    fillable: false,
  }));
}

async function loadManualEntries(pool, petId) {
  const result = await pool.query(
    `SELECT id, title, description, start_date, end_date
     FROM pet_timeline_entries
     WHERE pet_id = $1
     ORDER BY start_date ASC`,
    [petId],
  );

  return result.rows.map((row) => ({
    kind: 'manual',
    id: row.id,
    start_date: isoDate(row.start_date),
    end_date: isoDate(row.end_date),
    title: row.title || '',
    description: (row.description || '').trim(),
    guardian_name: null,
    foster_name: null,
    fillable: false,
  }));
}

function mergeSegmentRanges(segments) {
  return segments
    .filter((s) => s.start_date)
    .map((s) => ({
      ...s,
      _startMs: dateOnlyMs(s.start_date),
      _endMs: dateOnlyMs(s.end_date || s.start_date),
    }))
    .sort((a, b) => a._startMs - b._startMs);
}

function buildGapSegments(coveredRanges, timelineStartMs, timelineEndMs) {
  const gaps = [];
  if (timelineStartMs == null || timelineEndMs == null) return gaps;

  const merged = [];
  for (const range of coveredRanges) {
    if (range._startMs == null) continue;
    const end = range._endMs ?? range._startMs;
    if (merged.length === 0) {
      merged.push({ start: range._startMs, end });
      continue;
    }
    const last = merged[merged.length - 1];
    if (range._startMs <= last.end + 86400000) {
      last.end = Math.max(last.end, end);
    } else {
      merged.push({ start: range._startMs, end });
    }
  }

  let cursor = timelineStartMs;
  for (const block of merged) {
    if (block.start > cursor) {
      gaps.push({
        kind: 'gap',
        id: `gap-${cursor}-${block.start}`,
        start_date: dateToIsoDate(new Date(cursor)),
        end_date: dateToIsoDate(new Date(block.start - 86400000)),
        title: '',
        description: '',
        guardian_name: null,
        foster_name: null,
        fillable: true,
      });
    }
    cursor = Math.max(cursor, block.end + 86400000);
  }

  if (cursor <= timelineEndMs) {
    gaps.push({
      kind: 'gap',
      id: `gap-${cursor}-${timelineEndMs}`,
      start_date: dateToIsoDate(new Date(cursor)),
      end_date: dateToIsoDate(new Date(timelineEndMs)),
      title: '',
      description: '',
      guardian_name: null,
      foster_name: null,
      fillable: true,
    });
  }

  return gaps;
}

/**
 * Build chronological pet timeline: custody + fostering + manual + gap placeholders.
 */
export async function buildPetTimeline(pool, petId, viewerId) {
  if (!(await userCanAccessOrgPetOperational(pool, petId, viewerId))) {
    const err = new Error('Forbidden');
    err.statusCode = 403;
    throw err;
  }

  const petResult = await pool.query(
    'SELECT id, created_at, date_of_birth FROM pets WHERE id = $1',
    [petId],
  );
  if (petResult.rows.length === 0) {
    const err = new Error('Pet not found');
    err.statusCode = 404;
    throw err;
  }
  const pet = petResult.rows[0];

  const [custody, sessions, manual] = await Promise.all([
    loadCustodySegments(pool, petId, viewerId),
    loadFosteringSessions(pool, petId),
    loadManualEntries(pool, petId),
  ]);

  const dataSegments = mergeSegmentRanges([...custody, ...sessions, ...manual]);
  const timelineStartMs = dateOnlyMs(pet.date_of_birth)
    ?? dateOnlyMs(pet.created_at)
    ?? Date.now();
  const timelineEndMs = Date.now();

  const gaps = dataSegments.length === 0
    ? [{
        kind: 'gap',
        id: `gap-empty-${petId}`,
        start_date: dateToIsoDate(new Date(timelineStartMs)),
        end_date: dateToIsoDate(new Date(timelineEndMs)),
        title: '',
        description: '',
        guardian_name: null,
        foster_name: null,
        fillable: true,
      }]
    : buildGapSegments(dataSegments, timelineStartMs, timelineEndMs);

  const combined = [...dataSegments, ...gaps]
    .map(({ _startMs, _endMs, ...rest }) => rest)
    .sort((a, b) => dateOnlyMs(a.start_date) - dateOnlyMs(b.start_date));

  return { segments: combined };
}
