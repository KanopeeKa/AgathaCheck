/**
 * Write-path validation for health entry care family, source, and provider fields.
 */

import {
  validateCareFamily as validateCareFamilyEnum,
  validateCareSource as validateCareSourceEnum,
} from '../care/enums.js';
import { validateProviderContactForPetWrite } from '../care/providerUsed.js';

export function validateCareFamilyForWrite(
  value,
  { recurring = false, requiredOnCreate = false } = {},
) {
  const required = requiredOnCreate || recurring;
  const requiredMessage = requiredOnCreate
    ? 'care_family is required'
    : 'care_family is required for recurring care';
  return validateCareFamilyEnum(value, { required, requiredMessage });
}

export function validateCareSourceForWrite(value) {
  return validateCareSourceEnum(value);
}

/** @param {object} data */
export function parseEntryProviderInput(data) {
  const hasContact = data.provider_contact_id !== undefined
    || data.providerContactId !== undefined;
  const hasTyped = data.provider_typed_name !== undefined
    || data.providerTypedName !== undefined;
  if (!hasContact && !hasTyped) {
    return { contactId: undefined, typedName: undefined };
  }
  let contactId = hasContact
    ? (data.provider_contact_id ?? data.providerContactId ?? null)
    : undefined;
  let typedName = hasTyped
    ? String(data.provider_typed_name ?? data.providerTypedName ?? '').trim()
    : undefined;
  if (contactId && typedName) {
    return { error: 'Provide either a provider contact or a typed name, not both' };
  }
  if (contactId === '') contactId = null;
  if (typedName === '') typedName = null;
  return { contactId, typedName };
}

export async function resolveEntryProviderForWrite(pool, userId, petId, data, existing = null) {
  const providerInput = parseEntryProviderInput(data);
  if (providerInput.error) return { error: providerInput.error };
  if (!existing) {
    const providerContactId = providerInput.contactId ?? null;
    const providerTypedName = providerInput.typedName ?? null;
    const attachError = await validateProviderContactForPetWrite(
      pool,
      userId,
      petId,
      providerContactId,
    );
    if (attachError) return attachError;
    return { providerContactId, providerTypedName };
  }
  let providerContactId = existing.provider_contact_id;
  let providerTypedName = existing.provider_typed_name;
  if (providerInput.contactId !== undefined) {
    providerContactId = providerInput.contactId;
    if (providerContactId) providerTypedName = null;
  }
  if (providerInput.typedName !== undefined) {
    providerTypedName = providerInput.typedName;
    if (providerTypedName) providerContactId = null;
  }
  if (providerInput.contactId !== undefined && providerContactId) {
    const attachError = await validateProviderContactForPetWrite(
      pool,
      userId,
      petId,
      providerContactId,
    );
    if (attachError) return attachError;
  }
  return { providerContactId, providerTypedName };
}
