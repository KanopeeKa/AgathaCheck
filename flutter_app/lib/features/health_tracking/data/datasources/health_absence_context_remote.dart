import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/health_entry_absence_context_model.dart';
import 'health_remote_response.dart';

class HealthAbsenceContextRemote {
  HealthAbsenceContextRemote({required this.baseUrl, http.Client? client})
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

  Future<HealthEntryAbsenceContext> fetchAbsenceContext(String entryId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/health-entries/$entryId/absence-context'),
      headers: _headers(),
    );
    checkHealthRemoteResponse(response);
    return HealthEntryAbsenceContext.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> saveResolution({
    required String absenceId,
    required String healthEntryId,
    required String decision,
    String? absenceNote,
    Map<String, dynamic>? lookedAfterBy,
    bool recordOnly = false,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/resolutions'),
      headers: _headers(jsonBody: true),
      body: json.encode({
        'health_entry_id': healthEntryId,
        'decision': decision,
        if (recordOnly) 'record_only': true,
        if (absenceNote != null) 'absence_note': absenceNote,
        if (lookedAfterBy != null) 'looked_after_by': lookedAfterBy,
      }),
    );
    checkHealthRemoteResponse(response);
  }
}
