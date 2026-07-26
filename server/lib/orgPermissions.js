import {
  ORG_ROLE_ADMIN,
  ORG_ROLE_SUPER_ADMIN,
} from './orgRoles.js';

/**
 * G0 §7 permission keys — default grants until Phase 3 organization_permissions table.
 * Each value is the set of org roles that receive the key by default.
 */
export const G0_PERMISSION_DEFAULTS = Object.freeze({
  manage_fosters: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  review_foster_onboarding: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  contact_fosters: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  confirm_foster_competencies: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_fostering_sessions: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  home_visits: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  adopter_screening: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_adoption_visits: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  start_adoption_journey: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  confirm_return_to_shelter: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_document_templates: Object.freeze([ORG_ROLE_SUPER_ADMIN]),
});

/** Bundle preset names for Phase 3 — constants only in Phase 0. */
export const PERMISSION_BUNDLE_FOSTER_ADMIN = 'foster_admin';
export const PERMISSION_BUNDLE_PET_ADMIN = 'pet_admin';
export const PERMISSION_BUNDLE_TEAM_ADMIN = 'team_admin';

/**
 * Returns whether [role] has [permissionKey] under G0 default grants.
 * [org] is reserved for Phase 3 per-org overrides — ignored in Phase 0.
 */
export function hasPermission(role, org, permissionKey) {
  void org;
  const defaults = G0_PERMISSION_DEFAULTS[permissionKey];
  if (!defaults) return false;
  return defaults.includes(role);
}

export function permissionKeysForRole(role) {
  return Object.entries(G0_PERMISSION_DEFAULTS)
    .filter(([, roles]) => roles.includes(role))
    .map(([key]) => key);
}
