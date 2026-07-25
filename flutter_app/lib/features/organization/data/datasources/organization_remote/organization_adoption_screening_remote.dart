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

  Future<Map<String, dynamic>> updateSessionChecklistItem(
    String orgId,
    String placementId,
    String itemKey, {
    required bool completed,
    required String token,
  }) async {
    final response = await _ctx.client.patch(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/session-checklist/$itemKey',
      ),
      headers: _ctx.headers(token),
      body: json.encode({'completed': completed}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(
        data['error'] ?? 'Failed to update session checklist item',
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> getAdoptionMilestones(
    String orgId,
    String placementId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/adoption-milestones',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get adoption milestones');
    }
    return data;
  }

  Future<Map<String, dynamic>> updateAdoptionMilestoneItem(
    String orgId,
    String journeyId,
    String itemKey, {
    required bool completed,
    required String token,
  }) async {
    final response = await _ctx.client.patch(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/adoption-journeys/$journeyId/milestones/$itemKey',
      ),
      headers: _ctx.headers(token),
      body: json.encode({'completed': completed}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to update adoption milestone');
    }
    return data;
  }

  Future<Map<String, dynamic>> getRegisterExport(
    String orgId,
    String placementId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/register-export',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get register export');
    }
    return data;
  }

  Future<Map<String, dynamic>> recordAdoptionVisitOutcome(
    String orgId,
    String visitId,
    String visitOutcome,
    String token,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/adoption-visits/$visitId/outcome',
      ),
      headers: _ctx.headers(token),
      body: json.encode({'visit_outcome': visitOutcome}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to record visit outcome');
    }
    return data;
  }

  Future<Map<String, dynamic>> completeVisitAndStartAdoption(
    String orgId,
    String placementId, {
    String? visitId,
    String adoptionConditions = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/adoption-path/complete-visit-and-start',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        if (visitId != null && visitId.isNotEmpty) 'visit_id': visitId,
        if (adoptionConditions.isNotEmpty)
          'adoption_conditions': adoptionConditions,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(
        data['error'] ?? 'Failed to complete visit and start adoption',
      );
    }
    return data;
  }
}
