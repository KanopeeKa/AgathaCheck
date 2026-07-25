import 'dart:convert';

import 'organization_remote_context.dart';

class OrganizationAdoptionScreeningRemote {
  OrganizationAdoptionScreeningRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<Map<String, dynamic>>> getProspects(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/prospects'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get prospects');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdoptionVisits(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/adoption-visits'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get adoption visits');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getAdoptionJourney(
    String orgId,
    String placementId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/adoption-journey',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get adoption journey');
    }
    return data;
  }

  Future<Map<String, dynamic>> getSessionChecklist(
    String orgId,
    String placementId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/session-checklist',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get session checklist');
    }
    return data;
  }
}
