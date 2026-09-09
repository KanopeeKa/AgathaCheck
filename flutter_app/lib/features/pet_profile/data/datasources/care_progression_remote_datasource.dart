import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/care_establishment_model.dart';

class CareProgressionRemoteDataSource {
  CareProgressionRemoteDataSource({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? authToken;

  Map<String, String> _headers() {
    final headers = <String, String>{};
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
      'Care progression request failed (${response.statusCode})',
    );
  }

  Future<List<CareEstablishmentModel>> fetchEstablishments(String petId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/care-progression'),
      headers: _headers(),
    );
    _check(response);
    final body = json.decode(response.body) as Map<String, dynamic>;
    final list = body['establishments'] as List<dynamic>? ?? [];
    return list
        .map(
          (e) => CareEstablishmentModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
