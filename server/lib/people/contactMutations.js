import { v4 as uuidv4 } from 'uuid';

import { CONTACT_KINDS, CONTACT_ROLES } from './constants.js';
import { userOwnsContact } from './authz.js';
import { ensurePersonalDirectory } from './directory.js';
import { loadContactForViewer } from './contactMapping.js';

function normalizeRoles(raw) {
  if (raw == null) return [];
  if (!Array.isArray(raw)) return { error: 'roles must be an array' };
  const roles = [...new Set(raw.map((r) => String(r).trim()).filter(Boolean))];
  const invalid = roles.find((r) => !CONTACT_ROLES.includes(r));
  if (invalid) return { error: `Invalid role: ${invalid}` };
  return { roles };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {object} body
 */
export async function createPersonalContact(pool, userId, body) {
  const kind = body.kind || 'person';
  if (!CONTACT_KINDS.includes(kind)) {
    return { error: 'Invalid kind' };
  }
  const name = (body.name || '').trim();
  if (!name) return { error: 'Name is required' };

  const roleResult = normalizeRoles(body.roles ?? []);
  if (roleResult.error) return { error: roleResult.error };
  const roles = roleResult.roles ?? [];

  const worksAtId = body.works_at_contact_id || body.worksAtContactId || null;
  if (worksAtId && !(await userOwnsContact(pool, worksAtId, userId))) {
    return { error: 'works_at_contact_id not found' };
  }

  const directoryId = await ensurePersonalDirectory(pool, userId);
  const id = uuidv4();
  await pool.query(
    `INSERT INTO people_contacts (
       id, directory_id, kind, name, phone, email, address, website,
       works_at_contact_id, created_at, updated_at
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())`,
    [
      id,
      directoryId,
      kind,
      name,
      body.phone || null,
      body.email || null,
      body.address || null,
      body.website || null,
      worksAtId,
    ],
  );

  for (const role of roles) {
    await pool.query(
      'INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, $2)',
      [id, role],
    );
  }

  const privateNote = body.private_note ?? body.privateNote;
  if (privateNote != null) {
    await pool.query(
      `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
       VALUES ($1, $2, $3, NOW())`,
      [id, userId, String(privateNote)],
    );
  }

  const row = await loadContactForViewer(pool, id, userId);
  return { row };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 * @param {object} body
 */
export async function patchPersonalContact(pool, contactId, userId, body) {
  const existing = await loadContactForViewer(pool, contactId, userId);
  if (!existing) return { notFound: true };

  const kind = body.kind ?? existing.kind;
  if (body.kind != null && !CONTACT_KINDS.includes(kind)) {
    return { error: 'Invalid kind' };
  }
  const name = body.name != null ? String(body.name).trim() : existing.name;
  if (!name) return { error: 'Name is required' };

  let roles = existing.roles;
  if (body.roles != null) {
    const roleResult = normalizeRoles(body.roles);
    if (roleResult.error) return { error: roleResult.error };
    roles = roleResult.roles ?? [];
  }

  const inactiveAt = body.inactive_at ?? body.inactiveAt;
  const worksAt = body.works_at_contact_id ?? body.worksAtContactId;
  if (worksAt && !(await userOwnsContact(pool, worksAt, userId))) {
    return { error: 'works_at_contact_id not found' };
  }

  const phone = body.phone !== undefined ? (body.phone || null) : existing.phone;
  const email = body.email !== undefined ? (body.email || null) : existing.email;
  const address = body.address !== undefined ? (body.address || null) : existing.address;
  const website = body.website !== undefined ? (body.website || null) : existing.website;
  const worksAtResolved = worksAt !== undefined ? (worksAt || null) : existing.works_at_contact_id;

  await pool.query(
    `UPDATE people_contacts SET
       kind = $1,
       name = $2,
       phone = $3,
       email = $4,
       address = $5,
       website = $6,
       works_at_contact_id = $7,
       inactive_at = $8,
       updated_at = NOW()
     WHERE id = $9`,
    [
      kind,
      name,
      phone,
      email,
      address,
      website,
      worksAtResolved,
      inactiveAt === undefined
        ? existing.inactive_at
        : (inactiveAt ? new Date(inactiveAt) : null),
      contactId,
    ],
  );

  if (body.roles != null) {
    await pool.query('DELETE FROM people_contact_roles WHERE contact_id = $1', [contactId]);
    for (const role of roles) {
      await pool.query(
        'INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, $2)',
        [contactId, role],
      );
    }
  }

  const privateNote = body.private_note ?? body.privateNote;
  if (privateNote !== undefined) {
    await pool.query(
      `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (contact_id, user_id)
       DO UPDATE SET note = EXCLUDED.note, updated_at = NOW()`,
      [contactId, userId, String(privateNote)],
    );
  }

  const row = await loadContactForViewer(pool, contactId, userId);
  return { row };
}
