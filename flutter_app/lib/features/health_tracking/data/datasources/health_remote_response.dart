import 'dart:convert';

import 'package:http/http.dart' as http;

void checkHealthRemoteResponse(http.Response response) {
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
