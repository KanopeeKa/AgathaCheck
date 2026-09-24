import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/absence_care_plan_model.dart';
import '../models/away_plan_readiness_model.dart';
import '../models/care_period_coverage_model.dart';
import '../models/planned_absence_model.dart';
import '../../domain/entities/absence_care_plan.dart';
import '../../domain/entities/away_plan_readiness.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../../domain/entities/carer_candidate.dart';
import '../../domain/entities/planned_absence.dart';

class CareContextApiException implements Exception {
  CareContextApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'CareContextApiException($statusCode): $message';
}

class CareContextRemoteDataSource {
  CareContextRemoteDataSource({required this.baseUrl, http.Client? client})
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
    throw CareContextApiException(
      response.statusCode,
      'Care context request failed (${response.statusCode})',
    );
  }

  Future<CarePeriodCoverageResult> fetchCarePeriodCoverage({
    required String petId,
    required String startsOn,
    required String endsOn,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/pets/$petId/care-period-coverage'
      '?starts_on=${Uri.encodeQueryComponent(startsOn)}'
      '&ends_on=${Uri.encodeQueryComponent(endsOn)}',
    );
    final response = await _client.get(uri, headers: _headers());
    _check(response);
    return CarePeriodCoverageModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CreatePlannedAbsenceResult> createPlannedAbsence({
    required String startsOn,
    required String endsOn,
    required List<String> petIds,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/planned-absences'),
      headers: _headers(jsonBody: true),
      body: json.encode({
        'starts_on': startsOn,
        'ends_on': endsOn,
        'pet_ids': petIds,
      }),
    );
    _check(response);
    return PlannedAbsenceModel.createResultFromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<PlannedAbsence>> listPlannedAbsences({
    String scope = 'all',
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/api/planned-absences?scope=${Uri.encodeQueryComponent(scope)}',
      ),
      headers: _headers(),
    );
    _check(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((raw) => PlannedAbsenceModel.fromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PlannedAbsence> fetchPlannedAbsence(String absenceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId'),
      headers: _headers(),
    );
    _check(response);
    return PlannedAbsenceModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AbsenceCarePlan> fetchAbsenceCarePlan(String absenceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/care-plan'),
      headers: _headers(),
    );
    _check(response);
    return AbsenceCarePlanModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AwayPlanReadiness> fetchAwayPlanReadiness(String absenceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/readiness'),
      headers: _headers(),
    );
    _check(response);
    return AwayPlanReadinessModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PlannedAbsence> updateHandoverNote({
    required String absenceId,
    String? handoverNote,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId'),
      headers: _headers(jsonBody: true),
      body: json.encode({'handover_note': handoverNote}),
    );
    _check(response);
    final body = json.decode(response.body) as Map<String, dynamic>;
    final absenceJson = body['absence'] as Map<String, dynamic>? ?? body;
    return PlannedAbsenceModel.fromJson(absenceJson);
  }

  Future<void> recordHandoverDownload(String absenceId) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/planned-absences/$absenceId/record-handover-download',
      ),
      headers: _headers(jsonBody: true),
      body: '{}',
    );
    _check(response);
  }

  Future<List<CarerCandidate>> fetchCarerCandidates(String petId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/carer-candidates'),
      headers: _headers(),
    );
    _check(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map(
          (raw) => CarerCandidate(
            userId: (raw as Map<String, dynamic>)['user_id'] as String? ?? '',
            displayName: raw['display_name'] as String? ?? '',
          ),
        )
        .toList(growable: false);
  }

  Future<PlannedAbsence> updatePetCarers({
    required String absenceId,
    required List<Map<String, dynamic>> petCarers,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId'),
      headers: _headers(jsonBody: true),
      body: json.encode({'pet_carers': petCarers}),
    );
    _check(response);
    final body = json.decode(response.body) as Map<String, dynamic>;
    final absenceJson = body['absence'] as Map<String, dynamic>? ?? body;
    return PlannedAbsenceModel.fromJson(absenceJson);
  }

  Future<PlannedAbsence> cancelPlannedAbsence(String absenceId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/cancel'),
      headers: _headers(jsonBody: true),
      body: '{}',
    );
    _check(response);
    final body = json.decode(response.body) as Map<String, dynamic>;
    final absenceJson = body['absence'] as Map<String, dynamic>? ?? body;
    return PlannedAbsenceModel.fromJson(absenceJson);
  }
}
