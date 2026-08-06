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
  };
}
