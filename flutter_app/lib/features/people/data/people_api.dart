import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/contact_usage.dart';
import 'dto/people_dtos.dart';
import 'people_api_exception.dart';

class PeopleApi {
  PeopleApi({required this.baseUrl, required this.client, this.token});

  final String baseUrl;
  final http.Client client;
  final String? token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await client.get(_uri(path, query), headers: _headers);
    return _decodeObject(response);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await client.get(_uri(path, query), headers: _headers);
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await client.post(
      _uri(path),
      headers: _headers,
      body: json.encode(body),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await client.patch(
      _uri(path),
      headers: _headers,
      body: json.encode(body),
    );
    return _decodeObject(response);
  }

  Future<void> delete(String path) async {
    final response = await client.delete(_uri(path), headers: _headers);
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw _exceptionFromResponse(response);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw PeopleApiException(
        code: 'invalid_response',
        statusCode: response.statusCode,
      );
    }
    throw _exceptionFromResponse(response);
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = json.decode(response.body);
      if (decoded is List<dynamic>) return decoded;
      throw PeopleApiException(
        code: 'invalid_response',
        statusCode: response.statusCode,
      );
    }
    throw _exceptionFromResponse(response);
  }

  PeopleApiException _exceptionFromResponse(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        final code = body['code']?.toString() ?? 'unknown';
        final usagesRaw = body['details'] is Map
            ? (body['details'] as Map)['usages']
            : body['usages'];
        final usages = <ContactUsage>[];
        if (usagesRaw is List) {
          for (final item in usagesRaw) {
            if (item is Map<String, dynamic>) {
              usages.add(ContactUsageDto.fromJson(item));
            }
          }
        }
        return PeopleApiException(
          code: code,
          statusCode: response.statusCode,
          message: body['error']?.toString(),
          usages: usages,
        );
      }
    } catch (_) {
      // fall through
    }
    return PeopleApiException(
      code: 'http_${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}
