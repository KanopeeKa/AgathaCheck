import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../domain/entities/household_summary.dart';

class HouseholdRemoteDataSource {
  final String baseUrl;
  final http.Client _client;

  HouseholdRemoteDataSource({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? (kIsWeb ? '' : 'http://localhost:5000'),
      _client = client ?? http.Client();

  Future<List<HouseholdSummary>> listHouseholds(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/households'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to list households');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final list = data['households'] as List? ?? [];
    return list.map((e) => _mapSummary(e as Map<String, dynamic>)).toList();
  }

  Future<HouseholdSummary> createHousehold(String name, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/households'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'name': name}),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create household');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return _mapSummary(data);
  }

  HouseholdSummary _mapSummary(Map<String, dynamic> json) {
    return HouseholdSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      myAccessTier:
          json['my_access_tier']?.toString() ??
          json['access_tier']?.toString() ??
          'full_access',
      myIsOrganiser:
          json['my_is_organiser'] == true || json['is_organiser'] == true,
    );
  }
}
