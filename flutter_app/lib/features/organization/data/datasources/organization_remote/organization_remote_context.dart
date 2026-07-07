import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Shared HTTP client and auth headers for organization API calls.
class OrganizationRemoteContext {
  OrganizationRemoteContext({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? (kIsWeb ? '' : 'http://localhost:5000'),
      client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;

  Map<String, String> headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, String> authOnly(String token) => {
    'Authorization': 'Bearer $token',
  };

  Never throwApiError(http.Response response, String fallback) {
    final data = json.decode(response.body);
    throw Exception(data['error'] ?? fallback);
  }
}
