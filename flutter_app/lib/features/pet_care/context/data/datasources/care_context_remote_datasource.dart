import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/care_period_coverage_model.dart';
import '../models/planned_absence_model.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../../domain/entities/planned_absence.dart';

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
    throw Exception('Care context request failed (${response.statusCode})');
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

  Future<List<PlannedAbsence>> listPlannedAbsences() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/planned-absences'),
      headers: _headers(),
    );
    _check(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map(
          (raw) => PlannedAbsenceModel.fromJson(raw as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
