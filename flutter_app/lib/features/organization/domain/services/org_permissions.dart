import '../entities/organization_member.dart';

/// G0 §7 permission keys — default role grants unioned with org overrides (Phase 3).
const Map<String, Set<OrgMemberRole>> g0PermissionDefaults = {
  'manage_fosters': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'review_foster_onboarding': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'contact_fosters': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'confirm_foster_competencies': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
  },
  'manage_fostering_sessions': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'home_visits': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'adopter_screening': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'manage_adoption_visits': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'start_adoption_journey': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'confirm_return_to_shelter': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'manage_document_templates': {OrgMemberRole.superAdmin},
  'manage_pets': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'transfer_pet_ownership': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'manage_admin_contacts': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'manage_members': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'manage_permissions': {OrgMemberRole.superAdmin},
};

/// Bundle preset names (Phase 3 constants — UI applies in Phase 5).
const permissionBundleFosterAdmin = 'foster_admin';
const permissionBundlePetAdmin = 'pet_admin';
const permissionBundleTeamAdmin = 'team_admin';

/// Active permission overrides keyed by organisation — populated from API (Phase 5).
final _viewerOverrideCache = <String, Set<String>>{};

void setViewerPermissionOverrides(String orgId, Set<String> keys) {
  _viewerOverrideCache[orgId] = keys;
}

void clearViewerPermissionOverrides([String? orgId]) {
  if (orgId != null) {
    _viewerOverrideCache.remove(orgId);
  } else {
    _viewerOverrideCache.clear();
  }
}

/// Active permission overrides for the given org — Phase 5 UI loads from API.
Set<String> orgPermissionOverrides(String? orgId) {
  if (orgId == null) return const {};
  return _viewerOverrideCache[orgId] ?? const {};
}

bool _hasRoleDefault(OrgMemberRole role, String permissionKey) {
  final defaults = g0PermissionDefaults[permissionKey];
  if (defaults == null) return false;
  return defaults.contains(role);
}

/// Returns whether [role] has [permissionKey] under role defaults union overrides.
/// [organizationId] resolves overrides via [orgPermissionOverrides] until Phase 5 UI.
bool hasPermission(
  OrgMemberRole role,
  String? organizationId,
  String permissionKey,
) {
  final overrides = orgPermissionOverrides(organizationId);
  if (overrides.contains(permissionKey)) return true;
  return _hasRoleDefault(role, permissionKey);
}
