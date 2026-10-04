import { v4 as uuidv4 } from 'uuid';

import { withTransaction } from '../db/withTransaction.js';
import { formatCarerCandidateDisplayName } from '../care/plannedAbsence.js';
import { assertCanEditContact } from './access.js';
import { CONTACT_KINDS, CONTACT_ROLES } from './constants.js';
import { PeopleError, PEOPLE_ERROR_CODES } from './errors.js';
import { inferContactKind } from './inference.js';
import { loadContactForViewer } from './contactMapping.js';
import { validateContactInput } from './contactValidation.js';
import {
  deactivateContactRow,
  deleteContactRow,
  ensurePersonalDirectory as ensurePersonalDirectorySql,
  insertContactRole,
  insertContactRow,
  insertPrivateNote,
  linkContactLegacyVet,
  linkContactToUser,
  replaceContactRoles,
  updateContactIdentityFromVet,
  updateContactRow,
  upsertPrivateNote,
} from './contactsRepoSql.js';
import { ensureLegacyVetForContact, syncVetRowFromContact } from './vetSync.js';

/** Use existing PoolClient when caller already holds a transaction (e.g. planned absence PATCH). */
async function runInTransaction(db, fn) {
  if (db && typeof db.connect === 'function') {
    return withTransaction(db, fn);
  }
  return fn(db);
}

export {
  ensurePersonalDirectorySql as ensurePersonalDirectory,
  linkContactLegacyVet,
  linkContactToUser,
};

function normalizeRoles(raw) {
  if (raw == null) return [];
  if (!Array.isArray(raw)) return { error: 'roles must be an array' };
  const roles = [...new Set(raw.map((r) => String(r).trim()).filter(Boolean))];
  const invalid = roles.find((r) => !CONTACT_ROLES.includes(r));
  if (invalid) return { error: `Invalid role: ${invalid}` };
  return { roles };
}

function parseInactiveAt(value) {
  if (value === null || value === '') return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Invalid inactive_at');
  }
  return d;
}

function linkedIdentityReadOnly(existing, body) {
  if (!existing?.linked_user_id) return false;
  if (body.name !== undefined && String(body.name).trim() !== String(existing.name).trim()) {
    return true;
  }
  if (body.email !== undefined) {
    const next = body.email == null || body.email === '' ? null : String(body.email).trim();
    const prev = existing.email == null ? null : String(existing.email).trim();
    if (next !== prev) return true;
  }
  return false;
}

export async function createPersonalContact(pool, userId, body) {
  const validation = validateContactInput(body, { requireName: true });
  if (validation.error) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, validation.error);
  }

  const roleResult = normalizeRoles(body.roles ?? []);
  if (roleResult.error) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, roleResult.error);
  }
  const roles = roleResult.roles ?? [];

  let kind = body.kind;
  if (!kind) kind = inferContactKind({ name: body.name, roles });
  if (!CONTACT_KINDS.includes(kind)) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Invalid kind');
  }
  const name = (body.name || '').trim();
  if (!name) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Name is required');
  }

  const worksAtId = body.works_at_contact_id || body.worksAtContactId || null;
  if (worksAtId && !(await loadContactForViewer(pool, worksAtId, userId))) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'works_at_contact_id not found');
  }

  const directoryId = await ensurePersonalDirectorySql(pool, userId);
  const id = uuidv4();

  await runInTransaction(pool, async (client) => {
    await insertContactRow(client, {
      id,
      directory_id: directoryId,
      kind,
      name,
      phone: body.phone || null,
      email: body.email || null,
      address: body.address || null,
      website: body.website || null,
      works_at_contact_id: worksAtId,
    });
    for (const role of roles) {
      await insertContactRole(client, id, role);
    }
    const privateNote = body.private_note ?? body.privateNote;
    if (privateNote != null && String(privateNote).trim()) {
      await insertPrivateNote(client, id, userId, String(privateNote));
    }
  });

  let row = await loadContactForViewer(pool, id, userId);
  if (row && roles.includes('vet')) {
    await ensureLegacyVetForContact(pool, row, userId);
    row = await loadContactForViewer(pool, id, userId);
  }
  return row;
}

export async function patchPersonalContact(pool, contactId, userId, body) {
  const existing = await loadContactForViewer(pool, contactId, userId);
  if (!existing) {
    throw new PeopleError(PEOPLE_ERROR_CODES.CONTACT_NOT_FOUND, 404, 'Contact not found');
  }

  if (linkedIdentityReadOnly(existing, body)) {
    throw new PeopleError(
      PEOPLE_ERROR_CODES.LINKED_IDENTITY_READ_ONLY,
      409,
      'Name and email cannot be changed for a linked account',
    );
  }

  const validation = validateContactInput(body);
  if (validation.error) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, validation.error);
  }

  let kind = body.kind ?? existing.kind;
  if (body.kind != null && !CONTACT_KINDS.includes(kind)) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Invalid kind');
  }
  const name = body.name != null ? String(body.name).trim() : existing.name;
  if (!name) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Name is required');
  }

  let roles = existing.roles;
  if (body.roles != null) {
    const roleResult = normalizeRoles(body.roles);
    if (roleResult.error) {
      throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, roleResult.error);
    }
    roles = roleResult.roles ?? [];
  }

  let inactiveAt = existing.inactive_at;
  if (body.active !== undefined) {
    inactiveAt = body.active ? null : new Date();
  } else if (body.inactive_at !== undefined || body.inactiveAt !== undefined) {
    const raw = body.inactive_at ?? body.inactiveAt;
    inactiveAt = raw == null || raw === '' ? null : parseInactiveAt(raw);
  }

  const worksAt = body.works_at_contact_id ?? body.worksAtContactId;
  if (worksAt && !(await loadContactForViewer(pool, worksAt, userId))) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'works_at_contact_id not found');
  }

  const phone = body.phone !== undefined ? (body.phone || null) : existing.phone;
  const email = body.email !== undefined ? (body.email || null) : existing.email;
  const address = body.address !== undefined ? (body.address || null) : existing.address;
  const website = body.website !== undefined ? (body.website || null) : existing.website;
  const worksAtResolved = worksAt !== undefined ? (worksAt || null) : existing.works_at_contact_id;
  const privateNote = body.private_note ?? body.privateNote;

  try {
    await runInTransaction(pool, async (client) => {
      await updateContactRow(client, contactId, {
        kind,
        name,
        phone,
        email,
        address,
        website,
        works_at_contact_id: worksAtResolved,
        inactive_at: inactiveAt === undefined ? existing.inactive_at : inactiveAt,
      });
      if (body.roles != null) await replaceContactRoles(client, contactId, roles);
      if (privateNote !== undefined) {
        await upsertPrivateNote(client, contactId, userId, String(privateNote));
      }
    });
  } catch (err) {
    if (err instanceof PeopleError) throw err;
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Contact update failed');
  }

  let row = await loadContactForViewer(pool, contactId, userId);
  if (row?.roles?.includes('vet')) {
    await ensureLegacyVetForContact(pool, row, userId);
    row = await loadContactForViewer(pool, contactId, userId);
  }
  if (row?.legacy_vet_id) {
    await syncVetRowFromContact(pool, row, userId);
    row = await loadContactForViewer(pool, contactId, userId);
  }
  return row;
}

export async function deletePersonalContact(pool, contactId, userId) {
  await assertCanEditContact(pool, contactId, userId);
  const row = await loadContactForViewer(pool, contactId, userId);
  if (!row) {
    throw new PeopleError(PEOPLE_ERROR_CODES.CONTACT_NOT_FOUND, 404, 'Contact not found');
  }
  if (row.legacy_vet_id) {
    throw new PeopleError(
      PEOPLE_ERROR_CODES.VALIDATION_FAILED,
      400,
      'Delete the linked vet record instead',
    );
  }
  const inUse = await pool.query(
    `SELECT 1 FROM pet_contact_relationships WHERE contact_id = $1
     UNION ALL
     SELECT 1 FROM planned_absence_pets WHERE contact_id = $1
     LIMIT 1`,
    [contactId],
  );
  if (inUse.rows.length > 0) {
    throw new PeopleError(
      PEOPLE_ERROR_CODES.CONTACT_IN_USE,
      409,
      'Contact is linked to a pet relationship',
    );
  }
  await deleteContactRow(pool, contactId);
}

export async function upsertContactFromVetFields(pool, fields, userId) {
  const directoryId = await ensurePersonalDirectorySql(pool, userId);
  const existing = await pool.query(
    'SELECT id FROM people_contacts WHERE legacy_vet_id = $1',
    [fields.legacy_vet_id],
  );

  if (existing.rows.length > 0) {
    const contactId = existing.rows[0].id;
    await updateContactIdentityFromVet(pool, contactId, fields);
    return contactId;
  }

  const contactId = uuidv4();
  await runInTransaction(pool, async (client) => {
    await insertContactRow(client, {
      id: contactId,
      directory_id: directoryId,
      kind: fields.kind,
      name: fields.name,
      phone: fields.phone,
      email: fields.email,
      address: fields.address,
      website: fields.website,
      legacy_vet_id: fields.legacy_vet_id,
    });
    await insertContactRole(client, contactId, 'vet', { onConflict: true });
    if (fields.privateNote) {
      await upsertPrivateNote(client, contactId, userId, fields.privateNote);
    }
  });
  return contactId;
}

export async function ensureLinkedUserContact(pool, ownerUserId, linkedUserId) {
  const directoryId = await ensurePersonalDirectorySql(pool, ownerUserId);
  const existing = await pool.query(
    `SELECT id FROM people_contacts
     WHERE directory_id = $1 AND linked_user_id = $2
     LIMIT 1`,
    [directoryId, linkedUserId],
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const userRow = await pool.query(
    'SELECT id, first_name, last_name, email FROM users WHERE id = $1',
    [linkedUserId],
  );
  const displayName = userRow.rows[0]
    ? formatCarerCandidateDisplayName(userRow.rows[0])
    : 'User';
  const contactId = uuidv4();
  await runInTransaction(pool, async (client) => {
    await insertContactRow(client, {
      id: contactId,
      directory_id: directoryId,
      kind: 'person',
      name: displayName,
      linked_user_id: linkedUserId,
    });
    await insertContactRole(client, contactId, 'sitter');
  });
  return contactId;
}

export async function ensureNoteOnlyContact(pool, ownerUserId, name, note) {
  const directoryId = await ensurePersonalDirectorySql(pool, ownerUserId);
  const existing = await pool.query(
    `SELECT pc.id
     FROM people_contacts pc
     INNER JOIN people_contact_private_notes pcpn
       ON pcpn.contact_id = pc.id AND pcpn.user_id = $2
     WHERE pc.directory_id = $1
       AND pc.kind = 'person'
       AND pc.name = $3
       AND COALESCE(pcpn.note, '') = COALESCE($4, '')
     LIMIT 1`,
    [directoryId, ownerUserId, name, note ?? ''],
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const contactId = uuidv4();
  await runInTransaction(pool, async (client) => {
    await insertContactRow(client, {
      id: contactId,
      directory_id: directoryId,
      kind: 'person',
      name,
    });
    await insertContactRole(client, contactId, 'sitter');
    if (note) await insertPrivateNote(client, contactId, ownerUserId, note);
  });
  return contactId;
}

export async function copyContactToPersonalDirectory(client, contact, personalDirId) {
  const existing = await client.query(
    `SELECT pc.id FROM people_contacts pc
     WHERE pc.directory_id = $1
       AND lower(pc.name) = lower($2)
       AND coalesce(pc.email, '') = coalesce($3::text, '')
     LIMIT 1`,
    [personalDirId, contact.name, contact.email],
  );
  let targetContactId = existing.rows[0]?.id;
  if (!targetContactId) {
    targetContactId = uuidv4();
    await insertContactRow(client, {
      id: targetContactId,
      directory_id: personalDirId,
      kind: contact.kind,
      name: contact.name,
      phone: contact.phone,
      email: contact.email,
      address: contact.address,
      website: contact.website,
      works_at_contact_id: contact.works_at_contact_id,
      linked_user_id: contact.linked_user_id,
    });
    const roles = (contact.roles || []).filter(Boolean);
    for (const role of roles) {
      await insertContactRole(client, targetContactId, role, { onConflict: true });
    }
  }
  return targetContactId;
}

export async function deactivateOrDeleteContactForVet(pool, vetId) {
  if (!vetId) return;
  const contact = await pool.query(
    'SELECT id FROM people_contacts WHERE legacy_vet_id = $1',
    [vetId],
  );
  if (contact.rows.length === 0) return;
  const contactId = contact.rows[0].id;
  const inUse = await pool.query(
    'SELECT 1 FROM pet_contact_relationships WHERE contact_id = $1 LIMIT 1',
    [contactId],
  );
  if (inUse.rows.length > 0) {
    await deactivateContactRow(pool, contactId);
    return;
  }
  await deleteContactRow(pool, contactId);
}
