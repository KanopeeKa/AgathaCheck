import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/pet_access_model.dart';

class SharingRemoteDataSource {
  final String baseUrl;
  final http.Client _client;

  SharingRemoteDataSource({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? (kIsWeb ? '' : 'http://localhost:5000'),
        _client = client ?? http.Client();

  Future<String> createShare(
      String petId, Map<String, dynamic> petJson, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/share'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'pet': petJson, 'pet_id': petId}),
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

  Future<List<PetAccessModel>> getAccess(String petId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/access'),
      headers: {
        'Authorization': 'Bearer $token',
      },
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
      String petId, int userId, String role, String token) async {
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

  Future<void> removeAccess(String petId, int userId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/pets/$petId/access/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to remove access');
    }
  }
}
