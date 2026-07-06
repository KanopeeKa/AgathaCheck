import 'dart:convert';

import '../../models/organization_member_model.dart';
import 'organization_remote_context.dart';

class OrganizationMembersRemote {
  OrganizationMembersRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<OrganizationMemberModel>> getMembers(
      String orgId, String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/members'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get members');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => OrganizationMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> inviteByEmail(
      String orgId, String email, String role, String token) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/invite'),
      headers: _ctx.headers(token),
      body: json.encode({'email': email, 'role': role}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to invite user');
    }
    return data;
  }

  Future<void> updateMemberRole(
      String orgId, String userId, String role, String token) async {
    final response = await _ctx.client.put(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/members/$userId/role'),
      headers: _ctx.headers(token),
      body: json.encode({'role': role}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to update role');
    }
  }

  Future<void> removeMember(String orgId, String userId, String token) async {
    final response = await _ctx.client.delete(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/members/$userId'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to remove member');
    }
  }

  Future<void> leaveOrganization(String orgId, String token) async {
    final response = await _ctx.client.delete(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/members/me'),
      headers: _ctx.authOnly(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to leave organization');
    }
  }
}
