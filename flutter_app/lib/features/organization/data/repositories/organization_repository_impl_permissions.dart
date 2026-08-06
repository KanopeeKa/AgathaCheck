import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryPermissionsMixin on OrganizationRepositoryImplBase {
  @override
  Future<Map<String, dynamic>> getPermissionBundles(
    String orgId,
    String token,
  ) => dataSource.getPermissionBundles(orgId, token);

  @override
  Future<Map<String, dynamic>> getMyPermissions(String orgId, String token) =>
      dataSource.getMyPermissions(orgId, token);

  @override
  Future<Map<String, dynamic>> getMemberPermissions(
    String orgId,
    String targetUserId,
    String token,
  ) => dataSource.getMemberPermissions(orgId, targetUserId, token);

  @override
  Future<Map<String, dynamic>> applyPermissionBundle(
    String orgId,
    String targetUserId,
    String preset,
    String token,
  ) => dataSource.applyPermissionBundle(orgId, targetUserId, preset, token);

  @override
  Future<Map<String, dynamic>> grantMemberPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) => dataSource.grantPermission(orgId, targetUserId, permissionKey, token);

  @override
  Future<Map<String, dynamic>> revokeMemberPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) => dataSource.revokePermission(orgId, targetUserId, permissionKey, token);

  @override
  Future<Map<String, dynamic>> batchMemberPermissions(
    String orgId,
    List<Map<String, dynamic>> changes,
    String token,
  ) => dataSource.batchPermissions(orgId, changes, token);

  @override
  Future<List<Map<String, dynamic>>> getOrgAuditEvents(
    String orgId,
    String token,
  ) => dataSource.getAuditEvents(orgId, token);

  @override
  Future<Map<String, dynamic>> getDocumentTemplates(
    String orgId,
    String token,
  ) => dataSource.getDocumentTemplates(orgId, token);
}
