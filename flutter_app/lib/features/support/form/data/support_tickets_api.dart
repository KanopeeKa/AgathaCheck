import 'dart:convert';

import 'package:http/http.dart' as http;

import 'support_ticket_submit_payload.dart';

class SupportTicketSubmitException implements Exception {
  SupportTicketSubmitException({
    required this.statusCode,
    required this.message,
    this.retryAfterSeconds,
    this.fieldErrors = const [],
  });

  final int statusCode;
  final String message;
  final int? retryAfterSeconds;
  final List<String> fieldErrors;

  bool get isRateLimited => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;
}

class SupportTicketsApi {
  SupportTicketsApi({
    required this.baseUrl,
    this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String? accessToken;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<String> submitTicket(SupportTicketSubmitPayload payload) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(
      _uri('/api/support/tickets'),
      headers: headers,
      body: json.encode(payload.toJson()),
    );

    if (response.statusCode == 201) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['reference'] is String) {
        return decoded['reference'] as String;
      }
      throw SupportTicketSubmitException(
        statusCode: response.statusCode,
        message: 'Unexpected response',
      );
    }

    var message = 'Request failed';
    var details = <String>[];
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['error']?.toString() ?? message;
        final rawDetails = decoded['details'];
        if (rawDetails is List) {
          details = rawDetails.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {
      // keep defaults
    }

    int? retryAfter;
    final retryHeader = response.headers['retry-after'];
    if (retryHeader != null) {
      retryAfter = int.tryParse(retryHeader);
    }

    throw SupportTicketSubmitException(
      statusCode: response.statusCode,
      message: message,
      retryAfterSeconds: retryAfter,
      fieldErrors: details,
    );
  }

  void close() => _client.close();
}
