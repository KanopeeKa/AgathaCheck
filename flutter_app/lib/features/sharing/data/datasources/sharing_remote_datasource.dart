import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/pet_access_model.dart';
import '../../domain/entities/invite_preview.dart';
import '../../domain/entities/pet_share_access.dart';
import '../../domain/entities/share_preview.dart';

class SharingRemoteDataSource {
  final String baseUrl;
  final http.Client _client;

  SharingRemoteDataSource({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? (kIsWeb ? '' : 'http://localhost:5000'),
      _client = client ?? http.Client();

  Future<String> createShare(
    String petId,
    String token, {
    String accessRole = 'carer',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/share'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'pet_id': petId, 'access_role': accessRole}),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create share');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['share_code'] as String;
  }

  Future<String> acceptShare(String code, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/share/$code/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to accept share');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['pet_id']?.toString() ?? '';
  }

  Future<SharePreview> getSharePreview(String code) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/share/$code'));
    if (response.statusCode == 410) {
      throw SharePreviewExpiredException();
    }
    if (response.statusCode >= 400) {
      throw SharePreviewNotFoundException();
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return SharePreview.fromJson(data);
  }

  Future<List<PetAccessModel>> getAccess(String petId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/access'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 403) {
      return [];
    }
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get access list');
    }
    final decoded = json.decode(response.body);
    final List list;
    if (decoded is Map<String, dynamic> && decoded.containsKey('access')) {
      list = decoded['access'] as List;
    } else if (decoded is List) {
      list = decoded;
    } else {
      list = [];
    }
    return list
        .map((e) => PetAccessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRole(
    String petId,
    String userId,
    String role,
    String token,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/pets/$petId/access/$userId/role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'role': role}),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update role');
    }
  }

  Future<void> removeAccess(String petId, String userId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/pets/$petId/access/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to remove access');
    }
  }

  Future<List<Map<String, dynamic>>> getShareLinks(
    String petId,
    String token,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/share-links'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 403) {
      return [];
    }
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to get share links');
    }
    final decoded = json.decode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> deleteShareLink(String linkId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/share/links/$linkId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete share link');
    }
  }

  Future<void> stopFollowing(String petId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/pets/$petId/follow'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to stop following');
    }
  }

  Future<void> hideSharedPet(
    String petId,
    String token, {
    required bool hidden,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/share/$petId/hide'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'hidden': hidden}),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update pet visibility');
    }
  }

  Future<List<Map<String, dynamic>>> getHiddenSharedPets(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/share/hidden'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      return [];
    }
    final decoded = json.decode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> transferOwnership(
    String petId, {
    required String recipientEmail,
    required String confirmationName,
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/pets/$petId/transfer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'recipient_email': recipientEmail,
        'confirmation_name': confirmationName,
      }),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to transfer pet');
    }
  }

  Future<CreateShareInviteResult> createInvite({
    required String inviteeEmail,
    required List<String> petIds,
    required String role,
    required String token,
    String? locale,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/share/invites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (locale != null) 'Accept-Language': locale,
      },
      body: json.encode({
        'invitee_email': inviteeEmail,
        'pet_ids': petIds,
        'role': role,
        if (locale != null) 'locale': locale,
      }),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to send invitation');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return CreateShareInviteResult.fromJson(data);
  }

  Future<List<PetShareAccess>> listAccessForPets(
    List<String> petIds,
    String token,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/share/access?pet_ids=${petIds.join(',')}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to load sharing access');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final pets = decoded['pets'];
    if (pets is! List) return [];
    return pets
        .whereType<Map<String, dynamic>>()
        .map(PetShareAccess.fromJson)
        .toList();
  }

  Future<InvitePreview> getInvitePreviewByCode(String code) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/share/invites/code/$code'),
    );
    if (response.statusCode == 410) {
      throw InvitePreviewExpiredException();
    }
    if (response.statusCode >= 400) {
      throw InvitePreviewNotFoundException();
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return InvitePreview.fromJson(data);
  }

  Future<AcceptShareInviteResult> acceptInviteByCode(
    String code,
    String token,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/share/invites/code/$code/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to accept invitation');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return AcceptShareInviteResult.fromJson(data);
  }

  Future<void> declineInvite(String inviteId, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/share/invites/$inviteId/decline'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to decline invitation');
    }
  }

  Future<void> cancelInvite(String inviteId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/share/invites/$inviteId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to cancel invitation');
    }
  }
}

class SharePreviewExpiredException implements Exception {}

class SharePreviewNotFoundException implements Exception {}
