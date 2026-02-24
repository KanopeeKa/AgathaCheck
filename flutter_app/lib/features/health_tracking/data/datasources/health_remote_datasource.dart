import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/health_entry_model.dart';
import '../models/health_history_model.dart';

/// Remote data source for health tracking via the REST API.
///
/// Communicates with the Dart server's /api/health-entries endpoints.
abstract class HealthRemoteDataSource {
  /// Retrieves all health entries, optionally filtered by [petId] and [type].
  Future<List<HealthEntryModel>> getEntries({String? petId, String? type});

  /// Retrieves a single health entry by [id].
  Future<HealthEntryModel?> getEntry(String id);

  /// Creates a new health entry.
  Future<HealthEntryModel> createEntry(HealthEntryModel entry);

  /// Updates an existing health entry.
  Future<HealthEntryModel> updateEntry(HealthEntryModel entry);

  /// Deletes a health entry by [id].
  Future<void> deleteEntry(String id);

  /// Marks an entry as taken and advances the next due date.
  Future<HealthEntryModel> markTaken(String id, {String notes});

  /// Retrieves history for a health entry.
  Future<List<HealthHistoryModel>> getHistory(String entryId);

  /// Exports health entries as CSV text.
  Future<String> exportCsv({String? petId});
}

/// Implementation of [HealthRemoteDataSource] using HTTP.
class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  /// Creates a [HealthRemoteDataSourceImpl] with the given [baseUrl] and [client].
  HealthRemoteDataSourceImpl({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// The base URL for the API server.
  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<HealthEntryModel>> getEntries(
      {String? petId, String? type}) async {
    final params = <String, String>{};
    if (petId != null) params['pet_id'] = petId;
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$baseUrl/api/health-entries')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri);
    _checkResponse(response);

    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HealthEntryModel?> getEntry(String id) async {
    final response =
        await _client.get(Uri.parse('$baseUrl/api/health-entries/$id'));
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<HealthEntryModel> createEntry(HealthEntryModel entry) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(entry.toJson()),
    );
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<HealthEntryModel> updateEntry(HealthEntryModel entry) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/health-entries/${entry.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(entry.toJson()),
    );
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final response =
        await _client.delete(Uri.parse('$baseUrl/api/health-entries/$id'));
    _checkResponse(response);
  }

  @override
  Future<HealthEntryModel> markTaken(String id,
      {String notes = ''}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries/$id/mark-taken'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'notes': notes}),
    );
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<HealthHistoryModel>> getHistory(String entryId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/health-entries/$entryId/history'));
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> exportCsv({String? petId}) async {
    final params = <String, String>{};
    if (petId != null) params['pet_id'] = petId;

    final uri = Uri.parse('$baseUrl/api/health-entries/export')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri);
    _checkResponse(response);
    return response.body;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      final body = response.body;
      String message;
      try {
        final decoded = json.decode(body) as Map<String, dynamic>;
        message = decoded['error'] as String? ?? 'Unknown error';
      } catch (_) {
        message = 'HTTP ${response.statusCode}';
      }
      throw Exception(message);
    }
  }
}
