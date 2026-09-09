import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/care_pending_moment_model.dart';

class CareProgressionMomentsRemoteDataSource {
  CareProgressionMomentsRemoteDataSource({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

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
      'Care progression moments request failed (${response.statusCode})',
    );
  }

  Future<CarePendingMomentsResponseModel> fetchPendingMoments(
    String petId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/care-progression/pending-moments'),
      headers: _headers(),
    );
    _check(response);
    final body = json.decode(response.body) as Map<String, dynamic>;
    return CarePendingMomentsResponseModel.fromJson(petId, body);
  }

  Future<void> acknowledgePresented({
    required String petId,
    required String bundleId,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/pets/$petId/care-progression/moments/$bundleId/acknowledge-presented',
      ),
      headers: _headers(),
    );
    _check(response);
  }
}
