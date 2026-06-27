import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/health_entry_model.dart';
import '../models/health_history_model.dart';

class EventPhoto {
  final String id;
  final String eventId;
  final String photoPath;
  final String caption;
  final String createdAt;

  EventPhoto({
    required this.id,
    required this.eventId,
    required this.photoPath,
    this.caption = '',
    this.createdAt = '',
  });

  factory EventPhoto.fromJson(Map<String, dynamic> json) {
    return EventPhoto(
      id: (json['id'] ?? '').toString(),
      eventId: (json['event_id'] ?? json['health_entry_id'] ?? '').toString(),
      photoPath: (json['photo_path'] ?? json['url'] ?? '').toString(),
      caption: json['caption'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

abstract class HealthRemoteDataSource {
  Future<List<HealthEntryModel>> getEntries({String? petId, String? type});
  Future<HealthEntryModel?> getEntry(String id);
  Future<HealthEntryModel> createEntry(HealthEntryModel entry);
  Future<HealthEntryModel> updateEntry(HealthEntryModel entry);
  Future<void> deleteEntry(String id);
  Future<HealthEntryModel> markTaken(String id, {String notes});
  Future<HealthEntryModel> undoComplete(String id);
  Future<List<HealthHistoryModel>> getHistory(String entryId);
  Future<String> exportCsv({String? petId});
  Future<List<EventPhoto>> getPhotos(String entryId);
  Future<EventPhoto> uploadPhoto(String entryId, Uint8List bytes, String filename, {String caption});
  Future<void> deletePhoto(String entryId, String photoId);
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
  Future<List<HealthEntryModel>> getEntries(
      {String? petId, String? type}) async {
    final params = <String, String>{};
    if (petId != null) params['pet_id'] = petId;
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$baseUrl/api/health-entries')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _authHeaders());
    _checkResponse(response);

    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HealthEntryModel?> getEntry(String id) async {
    final response = await _client.get(
        Uri.parse('$baseUrl/api/health-entries/$id'),
        headers: _authHeaders());
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<HealthEntryModel> createEntry(HealthEntryModel entry) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries'),
      headers: _authHeaders(jsonBody: true),
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
      headers: _authHeaders(jsonBody: true),
      body: json.encode(entry.toJson()),
    );
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final response = await _client.delete(
        Uri.parse('$baseUrl/api/health-entries/$id'),
        headers: _authHeaders());
    _checkResponse(response);
  }

  @override
  Future<HealthEntryModel> markTaken(String id,
      {String notes = ''}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries/$id/mark-taken'),
      headers: _authHeaders(jsonBody: true),
      body: json.encode({'notes': notes}),
    );
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<HealthEntryModel> undoComplete(String id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries/$id/undo-complete'),
      headers: _authHeaders(jsonBody: true),
      body: json.encode({}),
    );
    _checkResponse(response);
    return HealthEntryModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<HealthHistoryModel>> getHistory(String entryId) async {
    final response = await _client.get(
        Uri.parse('$baseUrl/api/health-entries/$entryId/history'),
        headers: _authHeaders());
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
    final response = await _client.get(uri, headers: _authHeaders());
    _checkResponse(response);
    return response.body;
  }

  @override
  Future<List<EventPhoto>> getPhotos(String entryId) async {
    final response = await _client.get(
        Uri.parse('$baseUrl/api/health-entries/$entryId/photos'),
        headers: _authHeaders());
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => EventPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EventPhoto> uploadPhoto(String entryId, Uint8List bytes,
      String filename, {String caption = ''}) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/api/health-entries/$entryId/photos'));
    request.headers.addAll(_authHeaders());
    request.files
        .add(http.MultipartFile.fromBytes('photo', bytes, filename: filename));
    if (caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    _checkResponse(response);
    return EventPhoto.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deletePhoto(String entryId, String photoId) async {
    final response = await _client.delete(
        Uri.parse('$baseUrl/api/health-entries/$entryId/photos/$photoId'),
        headers: _authHeaders());
    _checkResponse(response);
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
