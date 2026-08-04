/**
 * Per-org member privacy (Organisation UX v3 Phase 8).
 * @see docs/architecture/org-member-privacy.md
 */
import { hasEffectivePermission } from './orgPermissions.js';
import {
  ORG_ROLE_FOSTER,
  isOrgAdmin,
  isSuperAdmin,
  normaliseRole,
} from './orgRoles.js';

export const CARD_VISIBILITY_ALL = 'all';
export const CARD_VISIBILITY_ADMINS = 'admins';
export const CARD_VISIBILITY_NAMED = 'named';

export const CONTACT_VISIBILITY_ADMINS = 'admins';
export const CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS = 'admins_and_foster_managers';
export const CONTACT_VISIBILITY_ADMINS_OR_NAMED = 'admins_or_named';
export const CONTACT_VISIBILITY_NAMED = 'named';

export const ADDRESS_VISIBILITY_ADMINS_OR_NAMED = 'admins_or_named';
export const ADDRESS_VISIBILITY_ADMINS = 'admins';
export const ADDRESS_VISIBILITY_NAMED = 'named';
export const ADDRESS_VISIBILITY_HIDDEN = 'hidden';

export const PRIVACY_FIELDS = Object.freeze(['card', 'phone', 'email', 'address']);

const CARD_VALUES = new Set([
  CARD_VISIBILITY_ALL,
  CARD_VISIBILITY_ADMINS,
  CARD_VISIBILITY_NAMED,
]);

const CONTACT_VALUES = new Set([
  CONTACT_VISIBILITY_ADMINS,
  CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS,
  CONTACT_VISIBILITY_ADMINS_OR_NAMED,
  CONTACT_VISIBILITY_NAMED,
]);

const ADDRESS_VALUES = new Set([
  ADDRESS_VISIBILITY_ADMINS_OR_NAMED,
  ADDRESS_VISIBILITY_ADMINS,
  ADDRESS_VISIBILITY_NAMED,
  ADDRESS_VISIBILITY_HIDDEN,
]);

export function normaliseCardVisibility(value) {
  const wire = String(value || CARD_VISIBILITY_ALL).trim();
  return CARD_VALUES.has(wire) ? wire : CARD_VISIBILITY_ALL;
}

export function normaliseContactVisibility(value, fallback = CONTACT_VISIBILITY_ADMINS_OR_NAMED) {
  const wire = String(value || fallback).trim();
  return CONTACT_VALUES.has(wire) ? wire : fallback;
}

export function normaliseAddressVisibility(value) {
  const wire = String(value || ADDRESS_VISIBILITY_ADMINS_OR_NAMED).trim();
  return ADDRESS_VALUES.has(wire) ? wire : ADDRESS_VISIBILITY_ADMINS_OR_NAMED;
}

/** Role-specific defaults applied on membership create / migrate. */
export function defaultPrivacyForRole(role) {
  const normalised = normaliseRole(role);
  const fosterDefaults = normalised === ORG_ROLE_FOSTER;
  return {
    card_visibility: CARD_VISIBILITY_ALL,
    phone_visibility: fosterDefaults
      ? CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS
      : CONTACT_VISIBILITY_ADMINS_OR_NAMED,
    email_visibility: fosterDefaults
      ? CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS
      : CONTACT_VISIBILITY_ADMINS_OR_NAMED,
    address_visibility: ADDRESS_VISIBILITY_ADMINS_OR_NAMED,
  };
}

/** Admin/super_admin card floor — cannot set below admins. */
export function enforceCardVisibilityFloor(value, subjectRole) {
  const normalised = normaliseCardVisibility(value);
  if (isOrgAdmin(subjectRole) && normalised === CARD_VISIBILITY_NAMED) {
    return CARD_VISIBILITY_ADMINS;
  }
  return normalised;
}

export function privacySettingsFromRow(row = {}, role = null) {
  const defaults = defaultPrivacyForRole(role || row.role || ORG_ROLE_FOSTER);
  return {
    card_visibility: enforceCardVisibilityFloor(
      row.card_visibility ?? defaults.card_visibility,
      role || row.role,
    ),
    phone_visibility: normaliseContactVisibility(
      row.phone_visibility ?? defaults.phone_visibility,
      defaults.phone_visibility,
    ),
    email_visibility: normaliseContactVisibility(
      row.email_visibility ?? defaults.email_visibility,
      defaults.email_visibility,
    ),
    address_visibility: normaliseAddressVisibility(
      row.address_visibility ?? defaults.address_visibility,
    ),
  };
}

export function hasNamedGrant(grants, viewerUserId, field) {
  if (!viewerUserId || !Array.isArray(grants)) return false;
  return grants.some(
    (grant) => grant.field === field && grant.grantee_user_id === viewerUserId,
  );
}

function viewerIsFosterManager(viewerRole, viewerPermissionKeys) {
  return hasEffectivePermission(viewerRole, viewerPermissionKeys, 'manage_fosters');
}

/**
 * Whether [viewer] may see [field] on [subject] given stored settings and grants.
 */
export function canViewerSeeField({
  field,
  viewerUserId,
  viewerRole,
  viewerPermissionKeys = [],
  subjectUserId,
  subjectRole,
  settings,
  grants = [],
}) {
  if (!field || !settings) return false;
  if (viewerUserId && subjectUserId && viewerUserId === subjectUserId) return true;

  const isAdminViewer = isOrgAdmin(viewerRole);
  const namedGrant = hasNamedGrant(grants, viewerUserId, field);

  switch (field) {
    case 'card': {
      const visibility = settings.card_visibility;
      if (visibility === CARD_VISIBILITY_ALL) return true;
      if (visibility === CARD_VISIBILITY_ADMINS) return isAdminViewer;
      if (visibility === CARD_VISIBILITY_NAMED) {
        return namedGrant;
      }
      return false;
    }
    case 'phone':
    case 'email': {
      const visibility = field === 'phone'
        ? settings.phone_visibility
        : settings.email_visibility;
      if (visibility === CONTACT_VISIBILITY_ADMINS) return isAdminViewer;
      if (visibility === CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS) {
        return isAdminViewer || viewerIsFosterManager(viewerRole, viewerPermissionKeys);
      }
      if (visibility === CONTACT_VISIBILITY_ADMINS_OR_NAMED) {
        return isAdminViewer || namedGrant;
      }
      if (visibility === CONTACT_VISIBILITY_NAMED) return namedGrant;
      return false;
    }
    case 'address': {
      const visibility = settings.address_visibility;
      if (visibility === ADDRESS_VISIBILITY_HIDDEN) return false;
      if (visibility === ADDRESS_VISIBILITY_ADMINS) return isAdminViewer;
      if (visibility === ADDRESS_VISIBILITY_ADMINS_OR_NAMED) {
        return isAdminViewer || namedGrant;
      }
      if (visibility === ADDRESS_VISIBILITY_NAMED) return namedGrant;
      return false;
    }
    default:
      return false;
  }
}

/** Super Admin always sees member name for non-admin subjects (name floor). */
export function canViewerSeeMemberName(ctx) {
  if (ctx.viewerUserId && ctx.subjectUserId && ctx.viewerUserId === ctx.subjectUserId) {
    return true;
  }
  if (canViewerSeeField({ ...ctx, field: 'card' })) return true;
  if (isSuperAdmin(ctx.viewerRole) && !isOrgAdmin(ctx.subjectRole)) return true;
  return false;
}

export function buildViewerPrivacyContext({
  viewerUserId,
  viewerRole,
  viewerPermissionKeys = [],
  subjectUserId,
  subjectRole,
  settings,
  grants = [],
}) {
  return {
    viewerUserId,
    viewerRole,
    viewerPermissionKeys,
    subjectUserId,
    subjectRole,
    settings,
    grants,
  };
}

/** Redact a member directory row for a viewer. Returns null when fully hidden. */
export function redactMemberForViewer(person, ctx) {
  const showName = canViewerSeeMemberName(ctx);
  const showCard = canViewerSeeField({ ...ctx, field: 'card' });
  const showPhone = canViewerSeeField({ ...ctx, field: 'phone' });
  const showEmail = canViewerSeeField({ ...ctx, field: 'email' });
  const showAddress = canViewerSeeField({ ...ctx, field: 'address' });

  if (!showName && !showCard) return null;

  return {
    ...person,
    display_name: showName ? person.display_name : '',
    email: showEmail ? person.email : null,
    photo_url: showCard ? person.photo_url : null,
    foster_phone: showPhone ? (person.foster_phone || '') : '',
    foster_address: showAddress ? (person.foster_address || '') : '',
    admin_notes: showCard ? (person.admin_notes || '') : '',
  };
}

/** Best-effort legacy foster prefs → unified enums (Phase 8 migration). */
export function mapLegacyFosterVisibility({
  visible_to: visibleTo,
  contact_visibility: contactVisibility,
  address_visibility: addressVisibility,
}) {
  const visible = String(visibleTo || 'both').trim();
  let cardVisibility = CARD_VISIBILITY_ALL;
  if (visible === 'admins') cardVisibility = CARD_VISIBILITY_ADMINS;
  else if (visible === 'nobody') cardVisibility = CARD_VISIBILITY_NAMED;

  let phoneVisibility = CONTACT_VISIBILITY_ADMINS_OR_NAMED;
  let emailVisibility = CONTACT_VISIBILITY_ADMINS_OR_NAMED;
  const contact = String(contactVisibility || 'both').trim();
  if (contact === 'neither') {
    phoneVisibility = CONTACT_VISIBILITY_NAMED;
    emailVisibility = CONTACT_VISIBILITY_NAMED;
  }

  let mappedAddress = ADDRESS_VISIBILITY_ADMINS_OR_NAMED;
  const address = String(addressVisibility || 'full').trim();
  if (address === 'hidden') mappedAddress = ADDRESS_VISIBILITY_HIDDEN;

  return {
    card_visibility: cardVisibility,
    phone_visibility: phoneVisibility,
    email_visibility: emailVisibility,
    address_visibility: mappedAddress,
  };
}

export function privacyPayloadFromMembership(row, grantsByField) {
  const settings = privacySettingsFromRow(row, row.role);
  return {
    ...settings,
    grants: grantsByField || {
      card: [],
      phone: [],
      email: [],
      address: [],
    },
  };
}

export function grantsByFieldFromRows(grantRows = []) {
  const grouped = {
    card: [],
    phone: [],
    email: [],
    address: [],
  };
  for (const row of grantRows) {
    if (!PRIVACY_FIELDS.includes(row.field)) continue;
    if (!grouped[row.field].includes(row.grantee_user_id)) {
      grouped[row.field].push(row.grantee_user_id);
    }
  }
  return grouped;
}

/** @returns {Map<string, object[]>} subjectUserId → grant rows */
export function groupGrantsBySubject(grantRows = []) {
  const map = new Map();
  for (const row of grantRows) {
    const subjectId = row.subject_user_id;
    if (!map.has(subjectId)) map.set(subjectId, []);
    map.get(subjectId).push(row);
  }
  return map;
}

export async function loadGrantsBySubjectForOrg(pool, orgId) {
  const { rows } = await pool.query(
    `SELECT organization_id, subject_user_id, grantee_user_id, field
     FROM organization_visibility_grants
     WHERE organization_id = $1`,
    [orgId],
  );
  return groupGrantsBySubject(rows);
}

export function redactMemberSummaryForViewer(person, viewer, settings, grantRows = []) {
  if (!person.user_id || person.kind !== 'member') {
    return person;
  }
  const ctx = buildViewerPrivacyContext({
    viewerUserId: viewer.userId,
    viewerRole: viewer.role,
    viewerPermissionKeys: viewer.permissionKeys || [],
    subjectUserId: person.user_id,
    subjectRole: person.role,
    settings: privacySettingsFromRow(settings, person.role),
    grants: grantRows,
  });
  const redacted = redactMemberForViewer(
    {
      ...person,
      foster_phone: person.foster_phone || '',
      foster_address: person.foster_address || '',
      admin_notes: person.admin_notes || '',
    },
    ctx,
  );
  if (!redacted) return null;
  return {
    ...redacted,
    active_foster_count: canViewerSeeField({ ...ctx, field: 'card' })
      ? person.active_foster_count
      : 0,
  };
}
