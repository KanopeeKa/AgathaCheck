import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class FosterPlacementsRemoteDataSource {
  FosterPlacementsRemoteDataSource({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? (kIsWeb ? '' : 'http://localhost:5000'),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<Map<String, dynamic>>> getPendingPlacements(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/foster-placements/pending'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to load pending foster placements');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> acceptPlacement(String placementId, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/foster-placements/$placementId/accept'),
      headers: _headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to accept foster placement');
    }
    return data;
  }

  Future<Map<String, dynamic>> declinePlacement(String placementId, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/foster-placements/$placementId/decline'),
      headers: _headers(token),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to decline foster placement');
    }
    return data;
  }
}
