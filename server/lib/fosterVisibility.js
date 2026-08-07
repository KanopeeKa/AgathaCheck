import { isOrgAdmin, normaliseRole } from './orgRoles.js';

export const FOSTER_VISIBLE_TO_OTHER_FOSTERS = 'other_fosters';
export const FOSTER_VISIBLE_TO_ADMINS = 'admins';
export const FOSTER_VISIBLE_TO_BOTH = 'both';
export const FOSTER_VISIBLE_TO_NOBODY = 'nobody';

export const FOSTER_ADDRESS_FULL = 'full';
export const FOSTER_ADDRESS_TOWN = 'town';
export const FOSTER_ADDRESS_HIDDEN = 'hidden';

export const FOSTER_CONTACT_EMAIL = 'email';
export const FOSTER_CONTACT_PHONE = 'phone';
export const FOSTER_CONTACT_NEITHER = 'neither';
export const FOSTER_CONTACT_BOTH = 'both';

export const FOSTER_MESSAGE_CHANNEL_IN_APP = 'in_app';
export const FOSTER_MESSAGE_CHANNEL_EMAIL = 'email';
export const FOSTER_MESSAGE_CHANNEL_BOTH = 'both';

const VISIBLE_TO_VALUES = new Set([
  FOSTER_VISIBLE_TO_OTHER_FOSTERS,
  FOSTER_VISIBLE_TO_ADMINS,
  FOSTER_VISIBLE_TO_BOTH,
  FOSTER_VISIBLE_TO_NOBODY,
]);

const ADDRESS_VISIBILITY_VALUES = new Set([
  FOSTER_ADDRESS_FULL,
  FOSTER_ADDRESS_TOWN,
  FOSTER_ADDRESS_HIDDEN,
]);

const CONTACT_VISIBILITY_VALUES = new Set([
  FOSTER_CONTACT_EMAIL,
  FOSTER_CONTACT_PHONE,
  FOSTER_CONTACT_NEITHER,
  FOSTER_CONTACT_BOTH,
]);

const MESSAGE_CHANNEL_VALUES = new Set([
  FOSTER_MESSAGE_CHANNEL_IN_APP,
  FOSTER_MESSAGE_CHANNEL_EMAIL,
  FOSTER_MESSAGE_CHANNEL_BOTH,
]);

export function normaliseVisibleTo(value) {
  const wire = String(value || FOSTER_VISIBLE_TO_BOTH).trim();
  return VISIBLE_TO_VALUES.has(wire) ? wire : FOSTER_VISIBLE_TO_BOTH;
}

export function normaliseAddressVisibility(value) {
  const wire = String(value || FOSTER_ADDRESS_FULL).trim();
  return ADDRESS_VISIBILITY_VALUES.has(wire) ? wire : FOSTER_ADDRESS_FULL;
}

export function normaliseContactVisibility(value) {
  const wire = String(value || FOSTER_CONTACT_BOTH).trim();
  return CONTACT_VISIBILITY_VALUES.has(wire) ? wire : FOSTER_CONTACT_BOTH;
}

export function normaliseMessageChannel(value) {
  const wire = String(value || FOSTER_MESSAGE_CHANNEL_IN_APP).trim();
  return MESSAGE_CHANNEL_VALUES.has(wire) ? wire : FOSTER_MESSAGE_CHANNEL_IN_APP;
}

export function visibilityFieldsFromRow(row = {}) {
  return {
    visible_to: normaliseVisibleTo(row.visible_to),
    address_visibility: normaliseAddressVisibility(row.address_visibility),
    contact_visibility: normaliseContactVisibility(row.contact_visibility),
    notification_message_channel: normaliseMessageChannel(row.notification_message_channel),
    rules_agreement_at: row.rules_agreement_at || null,
  };
}

function viewerIsAdmin(viewerRole) {
  return isOrgAdmin(normaliseRole(viewerRole));
}

function viewerIsFoster(viewerRole, viewerIsFosterParent = false) {
  return viewerIsFosterParent;
}

export function canViewerSeeFosterCard({
  visibleTo,
  viewerRole,
  viewerUserId,
  fosterUserId,
  viewerIsFosterParent = false,
}) {
  if (viewerUserId && fosterUserId && viewerUserId === fosterUserId) return true;
  const setting = normaliseVisibleTo(visibleTo);
  if (setting === FOSTER_VISIBLE_TO_NOBODY) return false;
  if (viewerIsAdmin(viewerRole)) {
    return setting === FOSTER_VISIBLE_TO_ADMINS || setting === FOSTER_VISIBLE_TO_BOTH;
  }
  if (viewerIsFoster(viewerRole, viewerIsFosterParent)) {
    return setting === FOSTER_VISIBLE_TO_OTHER_FOSTERS || setting === FOSTER_VISIBLE_TO_BOTH;
  }
  return false;
}

export function formatAddressForViewer(address, addressVisibility) {
  const raw = (address || '').trim();
  const setting = normaliseAddressVisibility(addressVisibility);
  if (!raw || setting === FOSTER_ADDRESS_HIDDEN) return '';
  if (setting === FOSTER_ADDRESS_FULL) return raw;
  const townMatch = raw.match(/(?:,\s*|\s+)([A-Za-z][A-Za-z\s'-]{1,48})$/);
  return townMatch ? townMatch[1].trim() : raw.split(/[,\n]/).pop()?.trim() || raw;
}

export function contactFieldsForViewer({
  email,
  phone,
  contactVisibility,
  viewerRole,
  viewerUserId,
  fosterUserId,
  viewerIsFosterParent = false,
}) {
  if (viewerUserId && fosterUserId && viewerUserId === fosterUserId) {
    return { email: email || null, phone: phone || null };
  }
  const setting = normaliseContactVisibility(contactVisibility);
  const showEmail = setting === FOSTER_CONTACT_EMAIL || setting === FOSTER_CONTACT_BOTH;
  const showPhone = setting === FOSTER_CONTACT_PHONE || setting === FOSTER_CONTACT_BOTH;
  if (!viewerIsAdmin(viewerRole) && !viewerIsFoster(viewerRole, viewerIsFosterParent)) {
    return { email: null, phone: null };
  }
  return {
    email: showEmail ? (email || null) : null,
    phone: showPhone ? (phone || null) : null,
  };
}

export function applyFosterVisibilityToMap(parentMap, {
  viewerRole,
  viewerUserId,
  viewerIsFosterParent = false,
}) {
  const fosterUserId = parentMap.user_id || null;
  if (!canViewerSeeFosterCard({
    visibleTo: parentMap.visible_to,
    viewerRole,
    viewerUserId,
    fosterUserId,
    viewerIsFosterParent,
  })) {
    return null;
  }

  const contacts = contactFieldsForViewer({
    email: parentMap.email,
    phone: parentMap.phone,
    contactVisibility: parentMap.contact_visibility,
    viewerRole,
    viewerUserId,
    fosterUserId,
    viewerIsFosterParent,
  });

  return {
    ...parentMap,
    email: contacts.email,
    phone: contacts.phone,
    foster_address: formatAddressForViewer(
      parentMap.foster_address,
      parentMap.address_visibility,
    ),
    is_self_card: Boolean(viewerUserId && fosterUserId && viewerUserId === fosterUserId),
  };
}

export function fosterSortKey(displayName) {
  const parts = String(displayName || '').trim().split(/\s+/);
  if (parts.length <= 1) return parts[0]?.toLowerCase() || '';
  return parts[parts.length - 1].toLowerCase();
}

export function sortFosterParentsForViewer(parents, viewerUserId) {
  let self = null;
  const others = [];
  for (const parent of parents) {
    if (viewerUserId && parent.user_id === viewerUserId) {
      self = parent;
    } else {
      others.push(parent);
    }
  }
  others.sort((a, b) => {
    const last = fosterSortKey(a.display_name).localeCompare(fosterSortKey(b.display_name));
    if (last !== 0) return last;
    return String(a.display_name || '').localeCompare(String(b.display_name || ''), undefined, {
      sensitivity: 'base',
    });
  });
  if (!self) return others;
  return [self, ...others];
}
