import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/absence_care_plan_model.dart';
import '../models/away_plan_readiness_model.dart';
import '../models/care_period_coverage_model.dart';
import '../models/per_pet_away_plan_status_model.dart';
import '../models/pet_planned_absence_list_model.dart';
import '../models/planned_absence_model.dart';
import '../../domain/entities/pet_planned_absence_row.dart';
import '../../domain/entities/absence_care_plan.dart';
import '../../domain/entities/away_plan_readiness.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../../domain/entities/carer_candidate.dart';
import '../../domain/entities/per_pet_away_plan_status.dart';
import '../../domain/entities/planned_absence.dart';

class CareContextApiException implements Exception {
  CareContextApiException(this.statusCode, this.message, {this.code});

  final int statusCode;
  final String message;
  final String? code;

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
    throw _failure(response);
  }

  CareContextApiException _failure(http.Response response) {
    var message = 'Care context request failed (${response.statusCode})';
    String? code;
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is String && err.isNotEmpty) message = err;
        code = decoded['code'] as String?;
      }
    } catch (_) {
      // Keep generic message when body is not JSON.
    }
    return CareContextApiException(response.statusCode, message, code: code);
  }

  Future<CarePeriodCoverageResult> fetchCarePeriodCoverage({
    required String petId,
    required String startsOn,
    required String endsOn,
    String? plannedAbsenceId,
  }) async {
    final query = {
      'starts_on': startsOn,
      'ends_on': endsOn,
      if (plannedAbsenceId != null && plannedAbsenceId.isNotEmpty)
        'planned_absence_id': plannedAbsenceId,
    };
    final uri = Uri.parse(
      '$baseUrl/api/pets/$petId/care-period-coverage',
    ).replace(queryParameters: query);
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
    String? title,
  }) async {
    final payload = <String, dynamic>{
      'starts_on': startsOn,
      'ends_on': endsOn,
      'pet_ids': petIds,
    };
    if (title != null && title.isNotEmpty) {
      payload['title'] = title;
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/api/planned-absences'),
      headers: _headers(jsonBody: true),
      body: json.encode(payload),
    );
    _check(response);
    return PlannedAbsenceModel.createResultFromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<PlannedAbsence>> listPlannedAbsences({
    String scope = 'all',
  }) async {
    if (scope == 'all') {
      final upcoming = await listPlannedAbsences(scope: 'upcoming');
      final past = await listPlannedAbsences(scope: 'past');
      return _mergePlannedAbsenceLists(upcoming, past);
    }
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

  List<PlannedAbsence> _mergePlannedAbsenceLists(
    List<PlannedAbsence> upcoming,
    List<PlannedAbsence> past,
  ) {
    final byId = <String, PlannedAbsence>{};
    for (final absence in [...upcoming, ...past]) {
      byId[absence.id] = absence;
    }
    return byId.values.toList(growable: false);
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

  Future<PerPetAwayPlanStatus> fetchPerPetAwayPlanStatus({
    required String absenceId,
    required String petId,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/pets/$petId/status'),
      headers: _headers(),
    );
    _check(response);
    final body = json.decode(response.body) as Map<String, dynamic>;
    final statusJson = body['status'] as Map<String, dynamic>? ?? body;
    return PerPetAwayPlanStatusModel.fromStatusJson(statusJson);
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

  Future<PlannedAbsence> updatePlannedAbsenceDetails({
    required String absenceId,
    required String startsOn,
    required String endsOn,
    String? title,
    String? handoverNote,
    bool confirmGuestAccessWiden = false,
  }) async {
    final payload = <String, dynamic>{
      'starts_on': startsOn,
      'ends_on': endsOn,
      'title': title,
      'handover_note': handoverNote,
    };
    if (confirmGuestAccessWiden) {
      payload['confirm_guest_access_widen'] = true;
    }
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId'),
      headers: _headers(jsonBody: true),
      body: json.encode(payload),
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

  Future<List<CarerCandidate>> fetchCarerCandidates(
    String petId, {
    String? plannedAbsenceId,
  }) async {
    final query = <String, String>{};
    if (plannedAbsenceId != null && plannedAbsenceId.isNotEmpty) {
      query['planned_absence_id'] = plannedAbsenceId;
    }
    final uri = Uri.parse('$baseUrl/api/pets/$petId/carer-candidates')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client.get(
      uri,
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

  Future<void> patchPerPetAwayPlan({
    required String absenceId,
    required String petId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/pets/$petId'),
      headers: _headers(jsonBody: true),
      body: json.encode(body),
    );
    _check(response);
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

  Future<Map<String, String>> fetchAbsenceResolutionNotes(
    String absenceId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/resolutions'),
      headers: _headers(),
    );
    _check(response);
    final body = json.decode(response.body) as Map<String, dynamic>;
    final list = body['resolutions'] as List<dynamic>? ?? const [];
    final notes = <String, String>{};
    for (final raw in list) {
      final map = raw as Map<String, dynamic>;
      final entryId = map['health_entry_id'] as String?;
      final note = map['absence_note'] as String?;
      if (entryId != null && note != null && note.isNotEmpty) {
        notes[entryId] = note;
      }
    }
    return notes;
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

  Future<Map<String, dynamic>> fetchAbsenceCarerInvitePreview(
    String code,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/planned-absences/carer-invites/code/$code'),
      headers: _headers(),
    );
    _check(response);
    return Map<String, dynamic>.from(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PetPlannedAbsenceListResult> fetchPetPlannedAbsences(
    String petId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/$petId/planned-absences'),
      headers: _headers(),
    );
    _check(response);
    return PetPlannedAbsenceListModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AddPetToAbsenceResult> addPetToPlannedAbsence({
    required String absenceId,
    required String petId,
    bool confirmGuestAccessWiden = false,
  }) async {
    final payload = <String, dynamic>{
      'pet_id': petId,
      if (confirmGuestAccessWiden) 'confirm_guest_access_widen': true,
    };
    final response = await _client.post(
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/pets'),
      headers: _headers(jsonBody: true),
      body: json.encode(payload),
    );
    _check(response);
    return PetPlannedAbsenceListModel.addPetResultFromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<RemovePetFromAbsenceResult> removePetFromPlannedAbsence({
    required String absenceId,
    required String petId,
    bool confirmDeleteAbsence = false,
  }) async {
    final request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/api/planned-absences/$absenceId/pets/$petId'),
    );
    request.headers.addAll(_headers(jsonBody: true));
    if (confirmDeleteAbsence) {
      request.body = json.encode({'confirm_delete_absence': true});
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _check(response);
    return PetPlannedAbsenceListModel.removePetResultFromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> acceptAbsenceCarerInvite(String code) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/planned-absences/carer-invites/code/$code/accept',
      ),
      headers: _headers(jsonBody: true),
      body: '{}',
    );
    _check(response);
    return Map<String, dynamic>.from(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
