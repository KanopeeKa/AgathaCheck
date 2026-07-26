import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/pet_timeline_segment.dart';

class PetTimelineRemoteDataSource {
  PetTimelineRemoteDataSource({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<PetTimelineSegment>> fetchTimeline(
    String petId,
    String token,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/timeline'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to load timeline (${response.statusCode})');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final segments = body['segments'] as List<dynamic>? ?? [];
    return segments
        .map((e) => PetTimelineSegment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PetTimelineSegment> createManualEntry(
    String petId,
    String token, {
    required String title,
    required String description,
    required String startDate,
    String? endDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/pets/$petId/timeline/entries'),
      headers: _headers(token),
      body: json.encode({
        'title': title,
        'description': description,
        'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(
        'Failed to create timeline entry (${response.statusCode})',
      );
    }
    return PetTimelineSegment.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
