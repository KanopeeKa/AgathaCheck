import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/services/org_permissions.dart';

import 'recording_organization_repository_base.dart';

mixin RecordingOrganizationRepositoryPermissionsMixin
    on RecordingOrganizationRepositoryBase {
  @override
  Future<Map<String, dynamic>> getMyPermissions(
    String orgId,
    String token,
  ) async => {
    'role': 'admin',
    'effective_permissions': <String>[],
    'overrides': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>> getPermissionBundles(
    String orgId,
    String token,
  ) async => {'bundles': {}};

  @override
  Future<Map<String, dynamic>> getMemberPermissions(
    String orgId,
    String targetUserId,
    String token,
  ) async => {
    'role': 'admin',
    'effective_permissions': <String>[],
    'overrides': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>> applyPermissionBundle(
    String orgId,
    String targetUserId,
    String preset,
    String token,
  ) async => {'granted_count': 0};

  @override
  Future<Map<String, dynamic>> grantMemberPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) async => {'granted': false};

  @override
  Future<Map<String, dynamic>> revokeMemberPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) async => {'revoked': false};

  @override
  Future<Map<String, dynamic>> batchMemberPermissions(
    String orgId,
    List<Map<String, dynamic>> changes,
    String token,
  ) async => {'applied_count': changes.length, 'change_count': changes.length};

  @override
  Future<List<Map<String, dynamic>>> getOrgAuditEvents(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<Map<String, dynamic>> getDocumentTemplates(
    String orgId,
    String token,
  ) async => {
    'session_checklist': <Map<String, dynamic>>[],
    'adoption_milestones': <Map<String, dynamic>>[],
    'email_templates': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>> updateEmailTemplate(
    String orgId,
    String templateKey, {
    required String subject,
    required String bodyHtml,
    required String bodyText,
    String locale = 'en',
    required String token,
  }) async => {
    'template_key': templateKey,
    'locale': locale,
    'subject': subject,
    'body_html': bodyHtml,
    'body_text': bodyText,
  };

  @override
  Future<Map<String, dynamic>> getRolePermissionDefaults(
    String orgId,
    String token,
  ) async => {
    'permission_keys': g0PermissionDefaults.keys.toList(),
    'tiers': {
      'associate': {
        'editable': true,
        'effective_defaults': ['view_org_pets'],
        'g0_defaults': ['view_org_pets'],
        'org_overrides': <Map<String, dynamic>>[],
      },
      'admin': {
        'editable': true,
        'effective_defaults': ['view_org_pets', 'manage_fosters'],
        'g0_defaults': ['view_org_pets', 'manage_fosters'],
        'org_overrides': <Map<String, dynamic>>[],
      },
      'super_admin': {
        'editable': false,
        'effective_defaults': g0PermissionDefaults.entries
            .where((entry) => entry.value.contains(OrgMemberRole.superAdmin))
            .map((entry) => entry.key)
            .toList(),
        'g0_defaults': g0PermissionDefaults.entries
            .where((entry) => entry.value.contains(OrgMemberRole.superAdmin))
            .map((entry) => entry.key)
            .toList(),
        'org_overrides': <Map<String, dynamic>>[],
      },
    },
  };

  @override
  Future<Map<String, dynamic>> saveRolePermissionDefaults(
    String orgId,
    String tier,
    List<String> grantedKeys,
    String token,
  ) async => {
    'tier': tier,
    'effective_defaults': grantedKeys,
    'members_affected': 1,
  };
}
