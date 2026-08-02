import 'dart:convert';

import '../../models/archived_pet_model.dart';
import 'organization_remote_context.dart';

class OrganizationPetsRemote {
  OrganizationPetsRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/pets'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get organization pets');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getOrganizationPetSummary(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/summary?sort=last_activity&limit=12',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get organization pet summary');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getRedactedOrganizationPet(
    String orgId,
    String petId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/redacted',
      ),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get redacted organization pet');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createOrganizationPet(
    String orgId,
    Map<String, dynamic> petJson,
    String token,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/pets'),
      headers: _ctx.headers(token),
      body: json.encode(petJson),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to create organization pet');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> transferPetToUser(
    String orgId,
    String petId, {
    required String recipientEmail,
    String transferType = 'adoption',
    String notes = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/transfer',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'recipient_email': recipientEmail,
        'transfer_type': transferType,
        'notes': notes,
      }),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to transfer pet');
    }
  }

  Future<void> transferPetToOrg(
    String petId,
    String orgId, {
    String transferType = 'transfer',
    String notes = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/pets/$petId/transfer-to-org'),
      headers: _ctx.headers(token),
      body: json.encode({
        'organization_id': orgId,
        'transfer_type': transferType,
        'notes': notes,
      }),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to transfer pet to organization');
    }
  }

  Future<List<ArchivedPetModel>> getOrganizationArchivedPets(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/archived'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get archived pets');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => ArchivedPetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ArchivedPetModel>> getUserArchivedPets(String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/archived-pets'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get archived pets');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => ArchivedPetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getFamilyEvents(
    String token,
    String petId,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/pets/$petId/family-events'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get family events');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createFamilyEvent(
    String token,
    String petId,
    Map<String, dynamic> body,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/pets/$petId/family-events'),
      headers: _ctx.headers(token),
      body: json.encode(body),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to create family event');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateFamilyEvent(
    String token,
    String petId,
    String eventId,
    Map<String, dynamic> body,
  ) async {
    final response = await _ctx.client.put(
      Uri.parse('${_ctx.baseUrl}/api/pets/$petId/family-events/$eventId'),
      headers: _ctx.headers(token),
      body: json.encode(body),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to update family event');
    }
  }

  Future<void> deleteFamilyEvent(
    String token,
    String petId,
    String eventId,
  ) async {
    final response = await _ctx.client.delete(
      Uri.parse('${_ctx.baseUrl}/api/pets/$petId/family-events/$eventId'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to delete family event');
    }
  }
}
