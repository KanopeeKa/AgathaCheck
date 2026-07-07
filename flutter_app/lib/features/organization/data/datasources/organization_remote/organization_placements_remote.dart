import 'dart:convert';

import 'organization_remote_context.dart';

class OrganizationPlacementsRemote {
  OrganizationPlacementsRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<Map<String, dynamic>> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/placement',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get foster placement');
    }
    return data;
  }

  Future<Map<String, dynamic>> startFosterPlacement(
    String orgId,
    String petId, {
    required String fosterUserId,
    String? startDate,
    String notes = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/placements',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'foster_user_id': fosterUserId,
        if (startDate != null) 'start_date': startDate,
        'notes': notes,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to start foster placement');
    }
    return data;
  }

  Future<Map<String, dynamic>> endFosterPlacement(
    String orgId,
    String placementId, {
    String? endDate,
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/end',
      ),
      headers: _ctx.headers(token),
      body: json.encode({if (endDate != null) 'end_date': endDate}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to end foster placement');
    }
    return data;
  }

  Future<Map<String, dynamic>> startAdoption(
    String orgId,
    String placementId, {
    String adoptionConditions = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/start-adoption',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        if (adoptionConditions.isNotEmpty)
          'adoption_conditions': adoptionConditions,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to start adoption');
    }
    return data;
  }

  Future<Map<String, dynamic>> completeAdoptionConditions(
    String orgId,
    String placementId, {
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/complete-conditions',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(
        data['error'] ?? 'Failed to complete adoption conditions',
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> cancelAdoption(
    String orgId,
    String placementId, {
    String? endDate,
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/placements/$placementId/cancel-adoption',
      ),
      headers: _ctx.headers(token),
      body: json.encode({if (endDate != null) 'end_date': endDate}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to cancel adoption');
    }
    return data;
  }

  Future<Map<String, dynamic>> directAdopt(
    String orgId,
    String petId, {
    required String fosterUserId,
    String adoptionConditions = '',
    String notes = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/placements/direct-adopt',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'foster_user_id': fosterUserId,
        if (adoptionConditions.isNotEmpty)
          'adoption_conditions': adoptionConditions,
        if (notes.isNotEmpty) 'notes': notes,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to start direct adoption');
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> getPetFosterHistory(
    String orgId,
    String petId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/foster-history',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load foster history');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }
}
