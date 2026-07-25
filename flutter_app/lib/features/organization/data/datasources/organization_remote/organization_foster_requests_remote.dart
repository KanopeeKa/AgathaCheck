import 'dart:convert';

import 'organization_remote_context.dart';

class OrganizationFosterRequestsRemote {
  OrganizationFosterRequestsRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<Map<String, dynamic>>> getFosterRequests(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/foster-requests'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get foster requests');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getEligibleFosterTargets(
    String orgId, {
    required List<String> petIds,
    required String token,
  }) async {
    final query = petIds.isEmpty
        ? ''
        : '?pet_ids=${Uri.encodeQueryComponent(petIds.join(','))}';
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-requests/eligible-targets$query',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get eligible foster targets');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createFosterRequest(
    String orgId, {
    required String message,
    required List<String> petIds,
    required List<String> orgFosterParentIds,
    bool send = false,
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/foster-requests'),
      headers: _ctx.headers(token),
      body: json.encode({
        'message': message,
        'pet_ids': petIds,
        'org_foster_parent_ids': orgFosterParentIds,
        if (send) 'send': true,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to create foster request');
    }
    return data;
  }

  Future<Map<String, dynamic>> getFosterRequestDetail(
    String orgId,
    String requestId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-requests/$requestId',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get foster request');
    }
    return data;
  }

  Future<Map<String, dynamic>> sendFosterRequest(
    String orgId,
    String requestId,
    String token,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-requests/$requestId/send',
      ),
      headers: _ctx.headers(token),
      body: json.encode({}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to send foster request');
    }
    return data;
  }

  Future<Map<String, dynamic>> respondToFosterRequest(
    String orgId,
    String requestId, {
    required String response,
    String? message,
    String? earliestAvailability,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'response': response,
      if (message != null && message.isNotEmpty) 'message': message,
      if (earliestAvailability != null && earliestAvailability.isNotEmpty)
        'earliest_availability': earliestAvailability,
    };
    final httpResponse = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-requests/$requestId/responses',
      ),
      headers: _ctx.headers(token),
      body: json.encode(body),
    );
    final data = json.decode(httpResponse.body) as Map<String, dynamic>;
    if (httpResponse.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to respond to foster request');
    }
    return data;
  }
}
