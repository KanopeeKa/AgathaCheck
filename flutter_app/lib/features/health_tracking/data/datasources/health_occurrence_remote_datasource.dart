import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/utils/calendar_date.dart';
import '../models/health_occurrence_model.dart';

Future<List<HealthOccurrenceModel>> fetchOpenOccurrences({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
}) async {
  final response = await client.get(
    Uri.parse(
      '$baseUrl/api/health-entries/$entryId/occurrences',
    ).replace(queryParameters: const {'status': 'open'}),
    headers: headers,
  );
  checkResponse(response);
  final list = json.decode(response.body) as List<dynamic>;
  return list
      .map((e) => HealthOccurrenceModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<HealthOccurrenceModel>> fetchPastOccurrences({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
}) async {
  final response = await client.get(
    Uri.parse(
      '$baseUrl/api/health-entries/$entryId/occurrences',
    ).replace(queryParameters: const {'status': 'past'}),
    headers: headers,
  );
  checkResponse(response);
  final list = json.decode(response.body) as List<dynamic>;
  return list
      .map((e) => HealthOccurrenceModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<HealthOccurrenceModel> postCompleteOccurrence({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
  required String occurrenceId,
  String notes = '',
  DateTime? completedOn,
  bool skipEarlierMissed = false,
}) async {
  final body = <String, dynamic>{
    'notes': notes,
    'skip_earlier_missed': skipEarlierMissed,
  };
  if (completedOn != null) {
    body['completed_on'] = toCalendarDateString(completedOn);
  }
  final response = await client.post(
    Uri.parse(
      '$baseUrl/api/health-entries/$entryId/occurrences/$occurrenceId/complete',
    ),
    headers: headers,
    body: json.encode(body),
  );
  checkResponse(response);
  final decoded = json.decode(response.body) as Map<String, dynamic>;
  final occurrence = decoded['occurrence'] as Map<String, dynamic>? ?? decoded;
  return HealthOccurrenceModel.fromJson(occurrence);
}

Future<HealthOccurrenceModel> postSkipOccurrence({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
  required String occurrenceId,
  String notes = '',
}) async {
  final response = await client.post(
    Uri.parse(
      '$baseUrl/api/health-entries/$entryId/occurrences/$occurrenceId/skip',
    ),
    headers: headers,
    body: json.encode({'notes': notes}),
  );
  checkResponse(response);
  return HealthOccurrenceModel.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}

Future<int> postSkipMissedOccurrences({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
}) async {
  final response = await client.post(
    Uri.parse('$baseUrl/api/health-entries/$entryId/occurrences/skip-missed'),
    headers: headers,
    body: json.encode({}),
  );
  checkResponse(response);
  final decoded = json.decode(response.body) as Map<String, dynamic>;
  return decoded['count'] as int? ?? 0;
}

class RescheduleOccurrenceRemoteResult {
  const RescheduleOccurrenceRemoteResult({
    required this.occurrence,
    required this.warnings,
    this.nextDueDate,
  });

  final HealthOccurrenceModel occurrence;
  final List<Map<String, dynamic>> warnings;
  final DateTime? nextDueDate;
}

Future<RescheduleOccurrenceRemoteResult> postRescheduleOccurrence({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
  required String occurrenceId,
  required DateTime scheduledDate,
  String? reasonCode,
}) async {
  final body = <String, dynamic>{
    'scheduled_date': toCalendarDateString(scheduledDate),
  };
  if (reasonCode != null && reasonCode.isNotEmpty) {
    body['reason_code'] = reasonCode;
  }
  final response = await client.post(
    Uri.parse(
      '$baseUrl/api/health-entries/$entryId/occurrences/$occurrenceId/reschedule',
    ),
    headers: headers,
    body: json.encode(body),
  );
  checkResponse(response);
  final decoded = json.decode(response.body) as Map<String, dynamic>;
  final occurrenceJson =
      decoded['occurrence'] as Map<String, dynamic>? ?? decoded;
  final warningsRaw = decoded['warnings'];
  final warnings = warningsRaw is List
      ? warningsRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
      : <Map<String, dynamic>>[];
  final nextDue = parseCalendarDate(decoded['next_due_date']);
  return RescheduleOccurrenceRemoteResult(
    occurrence: HealthOccurrenceModel.fromJson(occurrenceJson),
    warnings: warnings,
    nextDueDate: nextDue,
  );
}

Future<HealthOccurrenceModel> postUndoOccurrence({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
  required String occurrenceId,
}) async {
  final response = await client.post(
    Uri.parse(
      '$baseUrl/api/health-entries/$entryId/occurrences/$occurrenceId/undo',
    ),
    headers: headers,
    body: json.encode({}),
  );
  checkResponse(response);
  return HealthOccurrenceModel.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}
