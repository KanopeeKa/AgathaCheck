import 'dart:convert';

import 'organization_remote_context.dart';

class OrganizationFosterParentsRemote {
  OrganizationFosterParentsRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<Map<String, dynamic>>> getFosterParents(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/foster-parents'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get foster parents');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPeople(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/people'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get people');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getPersonDetail(
    String orgId,
    String kind,
    String recordId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/people/$kind/$recordId',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get person');
    }
    return data;
  }

  Future<Map<String, dynamic>> updatePersonContact(
    String orgId,
    String kind,
    String recordId,
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await _ctx.client.put(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/people/$kind/$recordId/contact',
      ),
      headers: _ctx.headers(token),
      body: json.encode(body),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to update contact');
    }
    return data;
  }

  Future<Map<String, dynamic>> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/foster-parents'),
      headers: _ctx.headers(token),
      body: json.encode({
        'display_name': displayName,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'foster_address': fosterAddress,
        'notes': notes,
        'lawful_basis_confirmed': lawfulBasisConfirmed,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to create foster parent');
    }
    return data;
  }

  Future<Map<String, dynamic>> updateExternalFosterParent(
    String orgId,
    String fosterParentId, {
    required String displayName,
    String? email,
    String? phone,
    String notes = '',
    required String token,
  }) async {
    final response = await _ctx.client.put(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-parents/$fosterParentId',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'display_name': displayName,
        'email': email,
        'phone': phone,
        'notes': notes,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to update foster parent');
    }
    return data;
  }

  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    final response = await _ctx.client.delete(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-parents/$fosterParentId',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to delete foster parent');
    }
  }
}
