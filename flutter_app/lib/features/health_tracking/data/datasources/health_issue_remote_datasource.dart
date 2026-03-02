import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/health_issue_model.dart';

abstract class HealthIssueRemoteDataSource {
  Future<List<HealthIssueModel>> getIssues(String petId);
  Future<HealthIssueModel> createIssue(HealthIssueModel model);
  Future<HealthIssueModel> updateIssue(HealthIssueModel model);
  Future<void> deleteIssue(String id);
  Future<void> linkEvent(String issueId, String entryId);
  Future<void> unlinkEvent(String issueId, String entryId);
}

class HealthIssueRemoteDataSourceImpl implements HealthIssueRemoteDataSource {
  HealthIssueRemoteDataSourceImpl({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<HealthIssueModel>> getIssues(String petId) async {
    final uri = Uri.parse('$baseUrl/api/health-issues')
        .replace(queryParameters: {'pet_id': petId});
    final response = await _client.get(uri);
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthIssueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HealthIssueModel> createIssue(HealthIssueModel model) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-issues'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(model.toJson()),
    );
    _checkResponse(response);
    return HealthIssueModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<HealthIssueModel> updateIssue(HealthIssueModel model) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/health-issues/${model.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(model.toJson()),
    );
    _checkResponse(response);
    return HealthIssueModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteIssue(String id) async {
    final response =
        await _client.delete(Uri.parse('$baseUrl/api/health-issues/$id'));
    _checkResponse(response);
  }

  @override
  Future<void> linkEvent(String issueId, String entryId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-issues/$issueId/events'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'health_entry_id': entryId}),
    );
    _checkResponse(response);
  }

  @override
  Future<void> unlinkEvent(String issueId, String entryId) async {
    final response = await _client.delete(
        Uri.parse('$baseUrl/api/health-issues/$issueId/events/$entryId'));
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
