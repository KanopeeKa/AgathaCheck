import '../entities/organization_member.dart';

/// G0 §7 permission keys — default role grants (Phase 0 scaffolding).
const Map<String, Set<OrgMemberRole>> g0PermissionDefaults = {
  'manage_fosters': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'review_foster_onboarding': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
  },
  'contact_fosters': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'confirm_foster_competencies': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
  },
  'manage_fostering_sessions': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
  },
  'home_visits': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'adopter_screening': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'manage_adoption_visits': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'start_adoption_journey': {OrgMemberRole.superAdmin, OrgMemberRole.admin},
  'confirm_return_to_shelter': {
    OrgMemberRole.superAdmin,
    OrgMemberRole.admin,
  },
  'manage_document_templates': {OrgMemberRole.superAdmin},
};

/// Returns whether [role] has [permissionKey] under G0 defaults.
/// [organizationId] reserved for Phase 3 per-org overrides.
bool hasPermission(
  OrgMemberRole role,
  String? organizationId,
  String permissionKey,
) {
  final defaults = g0PermissionDefaults[permissionKey];
  if (defaults == null) return false;
  return defaults.contains(role);
}
