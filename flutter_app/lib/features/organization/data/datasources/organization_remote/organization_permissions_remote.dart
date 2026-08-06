import 'dart:convert';

import 'organization_remote_context.dart';

class OrganizationPermissionsRemote {
  OrganizationPermissionsRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<Map<String, dynamic>> getMyPermissions(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/permissions/me'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load permissions');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPermissionBundles(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/permission-bundles'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load permission bundles');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMemberPermissions(
    String orgId,
    String targetUserId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/members/$targetUserId/permissions',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load member permissions');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyPermissionBundle(
    String orgId,
    String targetUserId,
    String preset,
    String token,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/members/$targetUserId/permissions/bundle',
      ),
      headers: _ctx.headers(token),
      body: json.encode({'preset': preset}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to apply permission bundle');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> grantPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/members/$targetUserId/permissions',
      ),
      headers: _ctx.headers(token),
      body: json.encode({'permission_key': permissionKey}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to grant permission');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> revokePermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) async {
    final response = await _ctx.client.delete(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/members/$targetUserId/permissions/$permissionKey',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to revoke permission');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> batchPermissions(
    String orgId,
    List<Map<String, dynamic>> changes,
    String token,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/permissions/batch'),
      headers: _ctx.headers(token),
      body: json.encode({'changes': changes}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to save permission changes');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAuditEvents(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/audit-events'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load audit events');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getDocumentTemplates(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/document-templates'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load document templates');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
