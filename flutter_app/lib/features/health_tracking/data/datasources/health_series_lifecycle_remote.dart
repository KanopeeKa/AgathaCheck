import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/health_entry_model.dart';

Future<HealthEntryModel> closeEventRemote({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
}) async {
  final response = await client.post(
    Uri.parse('$baseUrl/api/health-entries/$entryId/close'),
    headers: headers,
    body: json.encode({}),
  );
  checkResponse(response);
  return HealthEntryModel.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}

Future<HealthEntryModel> reopenEventRemote({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
}) async {
  final response = await client.post(
    Uri.parse('$baseUrl/api/health-entries/$entryId/reopen'),
    headers: headers,
    body: json.encode({}),
  );
  checkResponse(response);
  return HealthEntryModel.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}

Future<HealthEntryModel> pauseCareItemRemote({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
}) async {
  final response = await client.post(
    Uri.parse('$baseUrl/api/health-entries/$entryId/pause'),
    headers: headers,
    body: json.encode({}),
  );
  checkResponse(response);
  return HealthEntryModel.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}

Future<HealthEntryModel> resumeCareItemRemote({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
}) async {
  final response = await client.post(
    Uri.parse('$baseUrl/api/health-entries/$entryId/resume'),
    headers: headers,
    body: json.encode({}),
  );
  checkResponse(response);
  return HealthEntryModel.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}
