import 'dart:convert';

import 'organization_remote_context.dart';

class OrganizationInvitesRemote {
  OrganizationInvitesRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<Map<String, dynamic>>> getPendingInvites(String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/invites/pending'),
      headers: _ctx.authOnly(token),
    );
    if (response.statusCode >= 400) {
      return [];
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> acceptInvite(
      String inviteId, String token) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/invites/$inviteId/accept'),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to accept invite');
    }
    return data;
  }

  Future<void> declineInvite(String inviteId, String token) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/invites/$inviteId/decline'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to decline invite');
    }
  }
}
