import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/care_recommendation_model.dart';
import '../models/care_safeguard_model.dart';
import '../../domain/entities/care_recommendation.dart';

class CareIntelligenceRemoteDataSource {
  CareIntelligenceRemoteDataSource({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? authToken;

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
      'Care intelligence request failed (${response.statusCode})',
    );
  }

  Future<List<CareRecommendationModel>> fetchRecommendations(
    String petId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/care-recommendations'),
      headers: _headers(),
    );
    _check(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => CareRecommendationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CareSafeguardModel>> fetchSafeguards(String petId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/care-safeguards'),
      headers: _headers(),
    );
    _check(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => CareSafeguardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CareSafeguardModel> dismissSafeguard({
    required String petId,
    required String safeguardId,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/pets/$petId/care-safeguards/$safeguardId/dismiss',
      ),
      headers: _headers(jsonBody: true),
      body: json.encode({}),
    );
    _check(response);
    return CareSafeguardModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CareRecommendationModel> respond({
    required String petId,
    required String recommendationId,
    required CareRecommendationResponseAction action,
    Map<String, dynamic>? adjust,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/pets/$petId/care-recommendations/$recommendationId/respond',
      ),
      headers: _headers(jsonBody: true),
      body: json.encode({
        'action': careRecommendationStatusWire(action),
        if (adjust != null) 'adjust': adjust,
      }),
    );
    _check(response);
    return CareRecommendationModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
