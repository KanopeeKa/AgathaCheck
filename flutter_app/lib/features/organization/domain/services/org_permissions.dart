import '../entities/organization_member.dart';

/// G0 §7 permission keys — default role grants unioned with org overrides (Phase 3 + v2 view keys).
const Map<String, Set<OrgMemberRole>> g0PermissionDefaults = {
  'view_org_internal': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
    OrgMemberRole.foster,
    OrgMemberRole.associate,
  },
  'view_admin_contacts': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
    OrgMemberRole.foster,
    OrgMemberRole.associate,
  },
  'view_org_pets': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
    OrgMemberRole.foster,
    OrgMemberRole.associate,
  },
  'view_connections': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
    OrgMemberRole.foster,
    OrgMemberRole.associate,
  },
  'view_fostering_sessions': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
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

/// Organisation v2 view keys — mirrors server VIEW_PERMISSION_KEYS.
const viewPermissionKeys = [
  'view_org_internal',
  'view_admin_contacts',
  'view_org_pets',
  'view_connections',
  'view_fostering_sessions',
];

/// Bundle preset names (Phase 3 constants — UI applies in Phase 5).
const permissionBundleFosterAdmin = 'foster_admin';
const permissionBundlePetAdmin = 'pet_admin';
const permissionBundleTeamAdmin = 'team_admin';

/// Permission keys grouped under bundle headers in the detailed permissions UI.
/// Mirrors server [PERMISSION_BUNDLE_KEYS] plus adoption/ops keys in foster admin.
const Map<String, List<String>> permissionBundleKeyGroups = {
  permissionBundleFosterAdmin: [
    'manage_fosters',
    'review_foster_onboarding',
    'contact_fosters',
    'confirm_foster_competencies',
    'manage_fostering_sessions',
    'home_visits',
    'adopter_screening',
    'manage_adoption_visits',
    'start_adoption_journey',
    'confirm_return_to_shelter',
  ],
  permissionBundlePetAdmin: ['manage_pets', 'transfer_pet_ownership'],
  permissionBundleTeamAdmin: [
    'manage_admin_contacts',
    'manage_members',
    'manage_document_templates',
    'manage_permissions',
  ],
};

/// View keys shown before bundle groups in the detailed permissions list.
const List<String> permissionViewKeysOrdered = viewPermissionKeys;

/// All permission keys in UI display order (views, then bundle groups).
List<String> get orderedPermissionKeys {
  final keys = <String>[...permissionViewKeysOrdered];
  for (final group in permissionBundleKeyGroups.values) {
    keys.addAll(group);
  }
  return keys;
}

/// G0 default permission keys for a wire role tier (Associate / Admin / Super Admin).
Set<String> g0PermissionKeysForRole(OrgMemberRole role) {
  return g0PermissionDefaults.entries
      .where((entry) => entry.value.contains(role))
      .map((entry) => entry.key)
      .toSet();
}

/// Role tiers for Apply Associate / Admin / Super Admin preset buttons.
const List<OrgMemberRole> permissionRoleTierPresets = [
  OrgMemberRole.associate,
  OrgMemberRole.admin,
  OrgMemberRole.superAdmin,
];

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
