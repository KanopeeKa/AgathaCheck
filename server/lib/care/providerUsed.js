import { contactRowToMap, loadContactForViewer } from '../people/contactMapping.js';

/**
 * @param {object|null} contactRow
 * @returns {object|null}
 */
export function contactRowToProviderSnapshot(contactRow) {
  if (!contactRow) return null;
  const map = contactRowToMap(contactRow);
  return {
    contact_id: map.id,
    name: map.name,
    kind: map.kind,
    phone: map.phone,
    email: map.email,
  };
}

/**
 * The contact attached to a care item, whoever's directory it lives in.
 * Reading it is authorised by the completer's access to the pet (checked by
 * the route), not by the completer's own directory — PEOPLE invariant I12:
 * a co-parent or carer completing care keeps the item's provider.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @returns {Promise<object|null>}
 */
async function loadAttachedContact(pool, contactId) {
  const result = await pool.query(
    `SELECT pc.id, pc.directory_id, pc.kind, pc.name, pc.phone, pc.email
     FROM people_contacts pc
     WHERE pc.id = $1`,
    [contactId],
  );
  return result.rows[0] ?? null;
}

/**
 * Resolve provider used at completion from entry defaults and optional body overrides.
 *
 * The item's own contact is always snapshotted (I12). A different contact in
 * the body must be one the completer can see; otherwise the item's contact is
 * kept rather than silently dropping the provider.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {object} entry health_entries row
 * @param {object} [body] completion request body
 * @returns {Promise<{ contactId: string|null, typedName: string|null, snapshot: object|null }>}
 */
export async function resolveProviderUsedForCompletion(pool, userId, entry, body = {}) {
  const bodyContact =
    body.provider_contact_id || body.providerContactId || body.provider_used_contact_id || null;
  const bodyTyped =
    typeof body.provider_typed_name === 'string'
      ? body.provider_typed_name.trim()
      : typeof body.providerTypedName === 'string'
        ? body.providerTypedName.trim()
        : null;

  let contactId = bodyContact || entry.provider_contact_id || null;
  let typedName = bodyTyped || entry.provider_typed_name || null;

  if (contactId && typedName) {
    typedName = null;
  }

  let snapshot = null;
  if (bodyContact && bodyContact !== entry.provider_contact_id) {
    const row = await loadContactForViewer(pool, bodyContact, userId);
    if (row) {
      return { contactId: bodyContact, typedName: null, snapshot: contactRowToProviderSnapshot(row) };
    }
    contactId = entry.provider_contact_id || null;
    typedName = contactId ? null : (bodyTyped || entry.provider_typed_name || null);
  }
  if (contactId) {
    const row = await loadAttachedContact(pool, contactId);
    if (!row) {
      contactId = null;
    } else {
      snapshot = contactRowToProviderSnapshot(row);
    }
  }
  if (!contactId && typedName) {
    snapshot = { typed_name: typedName, name: typedName };
  }

  return { contactId, typedName: contactId ? null : (typedName || null), snapshot };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {object} body PATCH body
 * @returns {Promise<{ contactId?: string|null, typedName?: string|null, snapshot?: object|null, error?: string }|null>}
 */
export async function resolveProviderUsedPatch(pool, userId, body) {
  const hasContact = Object.prototype.hasOwnProperty.call(body, 'provider_contact_id')
    || Object.prototype.hasOwnProperty.call(body, 'providerContactId');
  const hasTyped = Object.prototype.hasOwnProperty.call(body, 'provider_typed_name')
    || Object.prototype.hasOwnProperty.call(body, 'providerTypedName');

  if (!hasContact && !hasTyped) return null;

  let contactId = hasContact
    ? (body.provider_contact_id ?? body.providerContactId ?? null)
    : null;
  let typedName = hasTyped
    ? String(body.provider_typed_name ?? body.providerTypedName ?? '').trim()
    : null;

  if (contactId && typedName) {
    return { error: 'Provide either a provider contact or a typed name, not both' };
  }
  if (contactId === '') contactId = null;
  if (typedName === '') typedName = null;

  let snapshot = null;
  if (contactId) {
    const row = await loadContactForViewer(pool, contactId, userId);
    if (!row) return { error: 'Provider contact not found' };
    snapshot = contactRowToProviderSnapshot(row);
    typedName = null;
  } else if (typedName) {
    snapshot = { typed_name: typedName, name: typedName };
    contactId = null;
  } else {
    snapshot = null;
  }

  return { contactId, typedName, snapshot };
}
