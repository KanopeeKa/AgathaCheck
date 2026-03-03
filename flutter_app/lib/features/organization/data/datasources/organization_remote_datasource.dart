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

  Future<OrganizationModel> getOrganization(int id, String token) async {
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
      int id, Map<String, dynamic> orgJson, String token) async {
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

  Future<void> deleteOrganization(int id, String token) async {
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
      int id, Uint8List bytes, String filename, String token) async {
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
      int orgId, String token) async {
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

  Future<String> inviteMember(int orgId, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/invite'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create invite');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['invite_code']?.toString() ?? '';
  }

  Future<void> joinOrganization(String code, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/organizations/join/$code'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to join organization');
    }
  }

  Future<void> updateMemberRole(
      int orgId, int userId, String role, String token) async {
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

  Future<void> removeMember(int orgId, int userId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/organizations/$orgId/members/$userId'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to remove member');
    }
  }

  Future<void> leaveOrganization(int orgId, String token) async {
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
      int orgId, String token) async {
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
      int orgId, Map<String, dynamic> petJson, String token) async {
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
      int orgId, String petId, {
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
      String petId, int orgId, {
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
      int orgId, String token) async {
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
}
