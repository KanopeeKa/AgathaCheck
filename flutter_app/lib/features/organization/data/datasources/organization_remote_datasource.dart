import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/archived_pet_model.dart';
import '../models/organization_member_model.dart';
import '../models/organization_model.dart';

class OrganizationRemoteDataSource {
  final String baseUrl;
  final http.Client _client;

  OrganizationRemoteDataSource({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? (kIsWeb ? '' : 'http://localhost:5000'),
        _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, String> _authOnly(String token) => {
        'Authorization': 'Bearer $token',
      };

  Future<List<OrganizationModel>> getOrganizations(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get organizations');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => OrganizationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrganizationModel> getOrganization(String id, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$id'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get organization');
    }
    return OrganizationModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<OrganizationModel> createOrganization(
      Map<String, dynamic> orgJson, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations'),
      headers: _headers(token),
      body: json.encode(orgJson),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create organization');
    }
    return OrganizationModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<OrganizationModel> updateOrganization(
      String id, Map<String, dynamic> orgJson, String token) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/organizations/$id'),
      headers: _headers(token),
      body: json.encode(orgJson),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update organization');
    }
    return OrganizationModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteOrganization(String id, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/organizations/$id'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete organization');
    }
  }

  Future<OrganizationModel> uploadPhoto(
      String id, Uint8List bytes, String filename, String token) async {
    final uri = Uri.parse('$baseUrl/api/organizations/$id/photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
      ));
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Photo upload failed');
    }
    return OrganizationModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<List<OrganizationMemberModel>> getMembers(
      String orgId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/members'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get members');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => OrganizationMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> inviteByEmail(String orgId, String email, String role, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/invite'),
      headers: _headers(token),
      body: json.encode({'email': email, 'role': role}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to invite user');
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> getPendingInvites(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/invites/pending'),
      headers: _authOnly(token),
    );
    if (response.statusCode >= 400) {
      return [];
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> acceptInvite(String inviteId, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/invites/$inviteId/accept'),
      headers: _headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to accept invite');
    }
    return data;
  }

  Future<void> declineInvite(String inviteId, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/invites/$inviteId/decline'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to decline invite');
    }
  }

  Future<void> updateMemberRole(
      String orgId, String userId, String role, String token) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/organizations/$orgId/members/$userId/role'),
      headers: _headers(token),
      body: json.encode({'role': role}),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update role');
    }
  }

  Future<void> removeMember(String orgId, String userId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/organizations/$orgId/members/$userId'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to remove member');
    }
  }

  Future<void> leaveOrganization(String orgId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/organizations/$orgId/members/me'),
      headers: _authOnly(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to leave organization');
    }
  }

  Future<List<Map<String, dynamic>>> getOrganizationPets(
      String orgId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/pets'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get organization pets');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createOrganizationPet(
      String orgId, Map<String, dynamic> petJson, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/pets'),
      headers: _headers(token),
      body: json.encode(petJson),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create organization pet');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> transferPetToUser(
      String orgId, String petId, {
      required String recipientEmail,
      String transferType = 'adoption',
      String notes = '',
      required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/pets/$petId/transfer'),
      headers: _headers(token),
      body: json.encode({
        'recipient_email': recipientEmail,
        'transfer_type': transferType,
        'notes': notes,
      }),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to transfer pet');
    }
  }

  Future<void> transferPetToOrg(
      String petId, String orgId, {
      String transferType = 'transfer',
      String notes = '',
      required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/pets/$petId/transfer-to-org'),
      headers: _headers(token),
      body: json.encode({
        'organization_id': orgId,
        'transfer_type': transferType,
        'notes': notes,
      }),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to transfer pet to organization');
    }
  }

  Future<List<ArchivedPetModel>> getOrganizationArchivedPets(
      String orgId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/archived'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get archived pets');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => ArchivedPetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ArchivedPetModel>> getUserArchivedPets(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/archived-pets'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get archived pets');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => ArchivedPetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getFamilyEvents(String token, String petId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/family-events'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get family events');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createFamilyEvent(String token, String petId, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/pets/$petId/family-events'),
      headers: _headers(token),
      body: json.encode(body),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create family event');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateFamilyEvent(String token, String petId, String eventId, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/pets/$petId/family-events/$eventId'),
      headers: _headers(token),
      body: json.encode(body),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update family event');
    }
  }

  Future<void> deleteFamilyEvent(String token, String petId, String eventId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/pets/$petId/family-events/$eventId'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete family event');
    }
  }

  Future<List<Map<String, dynamic>>> getFosterParents(
      String orgId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/foster-parents'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get foster parents');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPeople(String orgId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/people'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get people');
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
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/people/$kind/$recordId'),
      headers: _headers(token),
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
    final response = await _client.put(
      Uri.parse('$baseUrl/api/organizations/$orgId/people/$kind/$recordId/contact'),
      headers: _headers(token),
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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/foster-parents'),
      headers: _headers(token),
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
    final response = await _client.put(
      Uri.parse('$baseUrl/api/organizations/$orgId/foster-parents/$fosterParentId'),
      headers: _headers(token),
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
      String orgId, String fosterParentId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/organizations/$orgId/foster-parents/$fosterParentId'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete foster parent');
    }
  }

  Future<Map<String, dynamic>> getPetPlacement(
      String orgId, String petId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/pets/$petId/placement'),
      headers: _headers(token),
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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/pets/$petId/placements'),
      headers: _headers(token),
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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/placements/$placementId/end'),
      headers: _headers(token),
      body: json.encode({
        if (endDate != null) 'end_date': endDate,
      }),
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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/placements/$placementId/start-adoption'),
      headers: _headers(token),
      body: json.encode({
        if (adoptionConditions.isNotEmpty) 'adoption_conditions': adoptionConditions,
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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/placements/$placementId/complete-conditions'),
      headers: _headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to complete adoption conditions');
    }
    return data;
  }

  Future<Map<String, dynamic>> cancelAdoption(
    String orgId,
    String placementId, {
    String? endDate,
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/placements/$placementId/cancel-adoption'),
      headers: _headers(token),
      body: json.encode({
        if (endDate != null) 'end_date': endDate,
      }),
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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/pets/$petId/placements/direct-adopt'),
      headers: _headers(token),
      body: json.encode({
        'foster_user_id': fosterUserId,
        if (adoptionConditions.isNotEmpty) 'adoption_conditions': adoptionConditions,
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
    final response = await _client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/pets/$petId/foster-history'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to load foster history');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }
}
