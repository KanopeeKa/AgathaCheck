import 'dart:convert';

import '../../../domain/entities/org_connection.dart';
import 'organization_remote_context.dart';

class OrganizationConnectionsRemote {
  OrganizationConnectionsRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<OrgConnection>> getConnections(String orgId, String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/connections'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load connections');
    }
    final list = json.decode(response.body) as List;
    return list.map((e) => _mapConnection(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createConnectionRequest(
    String orgId, {
    required String targetOrgId,
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/connection-requests'),
      headers: _ctx.headers(token),
      body: json.encode({'target_org_id': targetOrgId}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to create connection request');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<List<OrgConnectionRequest>> getConnectionRequests(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/connection-requests',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load connection requests');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => _mapRequest(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeConnectionRequest(
    String orgId,
    String requestId,
    String token,
  ) async {
    final response = await _ctx.client.delete(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/connection-requests/$requestId',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to revoke connection request');
    }
  }

  Future<void> acceptConnectionRequest(String token, String requestToken) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/connection-requests/$requestToken/accept',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to accept connection request');
    }
  }

  Future<void> disconnectOrgs(
    String orgId,
    String otherOrgId,
    String token,
  ) async {
    final response = await _ctx.client.delete(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/connections/$otherOrgId',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to disconnect organisations');
    }
  }

  OrgConnection _mapConnection(Map<String, dynamic> json) {
    return OrgConnection(
      id: json['id']?.toString() ?? '',
      peerOrgId: json['peer_org_id']?.toString() ?? '',
      peerOrgName: json['peer_org_name']?.toString() ?? '',
      peerOrgType: json['peer_org_type']?.toString(),
      peerOrgEmail: json['peer_org_email']?.toString(),
      connectedAt: json['connected_at'] != null
          ? DateTime.tryParse(json['connected_at'].toString())
          : null,
    );
  }

  OrgConnectionRequest _mapRequest(Map<String, dynamic> json) {
    return OrgConnectionRequest(
      id: json['id']?.toString() ?? '',
      requestingOrgId: json['requesting_org_id']?.toString() ?? '',
      targetOrgId: json['target_org_id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expires_at'].toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      revokedAt: json['revoked_at'] != null
          ? DateTime.tryParse(json['revoked_at'].toString())
          : null,
    );
  }
}
