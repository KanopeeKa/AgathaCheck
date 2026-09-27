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
 * Resolve provider used at completion from entry defaults and optional body overrides.
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
  if (contactId) {
    const row = await loadContactForViewer(pool, contactId, userId);
    if (!row) {
      contactId = null;
    } else {
      snapshot = contactRowToProviderSnapshot(row);
    }
  } else if (typedName) {
    snapshot = { typed_name: typedName, name: typedName };
  }

  return { contactId, typedName: typedName || null, snapshot };
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
