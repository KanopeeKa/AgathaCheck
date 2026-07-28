import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/health_issue_model.dart';

abstract class HealthIssueRemoteDataSource {
  Future<List<HealthIssueModel>> getIssues(String petId, String token);
  Future<HealthIssueModel> createIssue(HealthIssueModel model, String token);
  Future<HealthIssueModel> updateIssue(HealthIssueModel model, String token);
  Future<void> deleteIssue(String id, String token);
  Future<void> linkEvent(String issueId, String entryId, String token);
  Future<void> unlinkEvent(String issueId, String entryId, String token);
  Future<List<Map<String, dynamic>>> getDocuments(String issueId, String token);
  Future<Map<String, dynamic>> uploadDocument(
    String issueId,
    List<int> bytes,
    String filename,
    String mimeType,
    String token,
  );
  Future<void> deleteDocument(String issueId, String documentId, String token);
}

class HealthIssueRemoteDataSourceImpl implements HealthIssueRemoteDataSource {
  HealthIssueRemoteDataSourceImpl({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  @override
  Future<List<HealthIssueModel>> getIssues(String petId, String token) async {
    final uri = Uri.parse(
      '$baseUrl/api/health-issues',
    ).replace(queryParameters: {'pet_id': petId});
    final response = await _client.get(uri, headers: _headers(token));
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthIssueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HealthIssueModel> createIssue(
    HealthIssueModel model,
    String token,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-issues'),
      headers: _headers(token),
      body: json.encode(model.toJson()),
    );
    _checkResponse(response);
    return HealthIssueModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<HealthIssueModel> updateIssue(
    HealthIssueModel model,
    String token,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/health-issues/${model.id}'),
      headers: _headers(token),
      body: json.encode(model.toJson()),
    );
    _checkResponse(response);
    return HealthIssueModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteIssue(String id, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/health-issues/$id'),
      headers: _headers(token),
    );
    _checkResponse(response);
  }

  @override
  Future<void> linkEvent(String issueId, String entryId, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-issues/$issueId/events'),
      headers: _headers(token),
      body: json.encode({'health_entry_id': entryId}),
    );
    _checkResponse(response);
  }

  @override
  Future<void> unlinkEvent(String issueId, String entryId, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/health-issues/$issueId/events/$entryId'),
      headers: _headers(token),
    );
    _checkResponse(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getDocuments(
    String issueId,
    String token,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/health-issues/$issueId/documents'),
      headers: _headers(token),
    );
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<Map<String, dynamic>> uploadDocument(
    String issueId,
    List<int> bytes,
    String filename,
    String mimeType,
    String token,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/health-issues/$issueId/documents'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
        contentType: mimeType.trim().isEmpty
            ? null
            : MediaType.parse(mimeType),
      ),
    );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _checkResponse(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<void> deleteDocument(
    String issueId,
    String documentId,
    String token,
  ) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/health-issues/$issueId/documents/$documentId'),
      headers: _headers(token),
    );
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
