import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/utils/calendar_date.dart';
import '../models/health_event_photo.dart';
import '../models/health_entry_model.dart';
import '../models/health_history_model.dart';
import '../models/health_occurrence_model.dart';
import 'health_occurrence_remote_datasource.dart'
    show
        RescheduleOccurrenceRemoteResult,
        fetchOpenOccurrences,
        fetchPastOccurrences,
        postCompleteOccurrence,
        postRescheduleOccurrence,
        postSkipMissedOccurrences,
        postSkipOccurrence,
        postUndoOccurrence,
        patchOccurrenceNotes;
import 'health_entry_photos_remote.dart';
import 'health_weight_completion_remote.dart';
import 'health_series_lifecycle_remote.dart';
import 'health_remote_response.dart';

export '../models/health_event_photo.dart';

abstract class HealthRemoteDataSource {
  Future<List<HealthEntryModel>> getEntries({String? petId, String? type});
  Future<HealthEntryModel?> getEntry(String id);
  Future<HealthEntryModel> createEntry(HealthEntryModel entry);
  Future<HealthEntryModel> updateEntry(HealthEntryModel entry);
  Future<void> deleteEntry(String id);
  Future<HealthEntryModel> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  });
  Future<HealthEntryModel> undoComplete(String id);
  Future<HealthEntryModel> closeEvent(String id);
  Future<HealthEntryModel> reopenEvent(String id);
  Future<HealthEntryModel> pauseCareItem(String id);
  Future<HealthEntryModel> resumeCareItem(String id);
  Future<HealthEntryModel> unmarkDone(String id);
  Future<List<HealthHistoryModel>> getHistory(String entryId);
  Future<String> exportCsv({String? petId});
  Future<List<EventPhoto>> getPhotos(String entryId);
  Future<EventPhoto> uploadPhoto(
    String entryId,
    Uint8List bytes,
    String filename, {
    String caption = '',
    String? occurrenceId,
  });
  Future<void> deletePhoto(String entryId, String photoId);
  Future<List<HealthOccurrenceModel>> getOpenOccurrences(String entryId);
  Future<List<HealthOccurrenceModel>> getPastOccurrences(String entryId);
  Future<HealthOccurrenceModel> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  });
  Future<HealthOccurrenceModel> skipOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
  });
  Future<int> skipMissedOccurrences(String entryId);
  Future<HealthOccurrenceModel> undoOccurrence(
    String entryId,
    String occurrenceId,
  );
  Future<HealthOccurrenceModel> updateOccurrenceNotes(
    String entryId,
    String occurrenceId,
    String notes,
  );
  Future<RescheduleOccurrenceRemoteResult> rescheduleOccurrence(
    String entryId,
    String occurrenceId,
    DateTime scheduledDate, {
    String? reasonCode,
  });
  Future<void> completeWeightOccurrence({
    required String petId,
    required String entryId,
    required String occurrenceId,
    required double weightKg,
    required DateTime date,
    String notes = '',
    String unit = 'kg',
    String measurementSource = 'guardian',
  });
}

/// Implementation of [HealthRemoteDataSource] using HTTP.
class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  /// Creates a [HealthRemoteDataSourceImpl] with the given [baseUrl] and [client].
  HealthRemoteDataSourceImpl({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// The base URL for the API server.
  final String baseUrl;
  final http.Client _client;

  String? authToken;

  /// Builds request headers, attaching the bearer token when available.
  /// Pass [jsonBody] for requests that send a JSON body.
  Map<String, String> _authHeaders({bool jsonBody = false}) {
    final headers = <String, String>{};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<HealthEntryModel>> getEntries({
    String? petId,
    String? type,
  }) async {
    final params = <String, String>{};
    if (petId != null) params['pet_id'] = petId;
    if (type != null) params['type'] = type;

    final uri = Uri.parse(
      '$baseUrl/api/health-entries',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _authHeaders());
    checkHealthRemoteResponse(response);

    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HealthEntryModel?> getEntry(String id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/health-entries/$id'),
      headers: _authHeaders(),
    );
    if (response.statusCode == 404) return null;
    checkHealthRemoteResponse(response);
    return HealthEntryModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<HealthEntryModel> createEntry(HealthEntryModel entry) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries'),
      headers: _authHeaders(jsonBody: true),
      body: json.encode(entry.toJson()),
    );
    checkHealthRemoteResponse(response);
    return HealthEntryModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<HealthEntryModel> updateEntry(HealthEntryModel entry) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/health-entries/${entry.id}'),
      headers: _authHeaders(jsonBody: true),
      body: json.encode(entry.toJson()),
    );
    checkHealthRemoteResponse(response);
    return HealthEntryModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/health-entries/$id'),
      headers: _authHeaders(),
    );
    checkHealthRemoteResponse(response);
  }

  @override
  Future<HealthEntryModel> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    final body = <String, dynamic>{'notes': notes};
    if (completedOn != null) {
      body['completed_on'] = toCalendarDateString(completedOn);
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries/$id/mark-taken'),
      headers: _authHeaders(jsonBody: true),
      body: json.encode(body),
    );
    checkHealthRemoteResponse(response);
    return HealthEntryModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<HealthEntryModel> undoComplete(String id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries/$id/undo-complete'),
      headers: _authHeaders(jsonBody: true),
      body: json.encode({}),
    );
    checkHealthRemoteResponse(response);
    return HealthEntryModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<HealthEntryModel> closeEvent(String id) {
    return closeEventRemote(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: id,
    );
  }

  @override
  Future<HealthEntryModel> reopenEvent(String id) {
    return reopenEventRemote(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: id,
    );
  }

  @override
  Future<HealthEntryModel> pauseCareItem(String id) {
    return pauseCareItemRemote(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: id,
    );
  }

  @override
  Future<HealthEntryModel> resumeCareItem(String id) {
    return resumeCareItemRemote(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: id,
    );
  }

  @override
  Future<HealthEntryModel> unmarkDone(String id) => undoComplete(id);

  @override
  Future<List<HealthHistoryModel>> getHistory(String entryId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/health-entries/$entryId/history'),
      headers: _authHeaders(),
    );
    checkHealthRemoteResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> exportCsv({String? petId}) async {
    final params = <String, String>{};
    if (petId != null) params['pet_id'] = petId;

    final uri = Uri.parse(
      '$baseUrl/api/health-entries/export',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _authHeaders());
    checkHealthRemoteResponse(response);
    return response.body;
  }

  @override
  Future<List<EventPhoto>> getPhotos(String entryId) {
    return fetchHealthEntryPhotos(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
    );
  }

  @override
  Future<EventPhoto> uploadPhoto(
    String entryId,
    Uint8List bytes,
    String filename, {
    String caption = '',
    String? occurrenceId,
  }) {
    return postHealthEntryPhoto(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      bytes: bytes,
      filename: filename,
      caption: caption,
      occurrenceId: occurrenceId,
    );
  }

  @override
  Future<void> deletePhoto(String entryId, String photoId) {
    return deleteHealthEntryPhoto(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      photoId: photoId,
    );
  }

  @override
  Future<List<HealthOccurrenceModel>> getOpenOccurrences(String entryId) {
    return fetchOpenOccurrences(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
    );
  }

  @override
  Future<List<HealthOccurrenceModel>> getPastOccurrences(String entryId) {
    return fetchPastOccurrences(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
    );
  }

  @override
  Future<HealthOccurrenceModel> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  }) {
    return postCompleteOccurrence(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      notes: notes,
      completedOn: completedOn,
      skipEarlierMissed: skipEarlierMissed,
    );
  }

  @override
  Future<HealthOccurrenceModel> skipOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
  }) {
    return postSkipOccurrence(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      notes: notes,
    );
  }

  @override
  Future<int> skipMissedOccurrences(String entryId) {
    return postSkipMissedOccurrences(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
    );
  }

  @override
  Future<HealthOccurrenceModel> undoOccurrence(
    String entryId,
    String occurrenceId,
  ) {
    return postUndoOccurrence(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
    );
  }

  @override
  Future<HealthOccurrenceModel> updateOccurrenceNotes(
    String entryId,
    String occurrenceId,
    String notes,
  ) {
    return patchOccurrenceNotes(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      notes: notes,
    );
  }

  @override
  Future<RescheduleOccurrenceRemoteResult> rescheduleOccurrence(
    String entryId,
    String occurrenceId,
    DateTime scheduledDate, {
    String? reasonCode,
  }) {
    return postRescheduleOccurrence(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      scheduledDate: scheduledDate,
      reasonCode: reasonCode,
    );
  }

  @override
  Future<void> completeWeightOccurrence({
    required String petId,
    required String entryId,
    required String occurrenceId,
    required double weightKg,
    required DateTime date,
    String notes = '',
    String unit = 'kg',
    String measurementSource = 'guardian',
  }) {
    return completeWeightOccurrenceRemote(
      client: _client,
      baseUrl: baseUrl,
      headers: _authHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      petId: petId,
      entryId: entryId,
      occurrenceId: occurrenceId,
      weightKg: weightKg,
      date: date,
      notes: notes,
      unit: unit,
      measurementSource: measurementSource,
    );
  }
}
