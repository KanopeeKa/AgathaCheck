import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/network/auth_http_client.dart';
import '../../domain/failures/health_document_failure.dart';

Never throwHealthDocumentFailure(Object error, [StackTrace? stackTrace]) {
  if (error is HealthDocumentFailure) {
    Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
  }
  if (error is SessionExpiredException) {
    Error.throwWithStackTrace(
      HealthDocumentSessionExpiredFailure(error.message),
      stackTrace ?? StackTrace.current,
    );
  }
  if (error is SocketException || error is http.ClientException) {
    Error.throwWithStackTrace(
      const HealthDocumentNetworkFailure(),
      stackTrace ?? StackTrace.current,
    );
  }
  if (error is HealthDocumentHttpException) {
    final status = error.statusCode;
    final message = error.message;
    if (status >= 500) {
      Error.throwWithStackTrace(
        HealthDocumentServerFailure(message, statusCode: status),
        stackTrace ?? StackTrace.current,
      );
    }
    Error.throwWithStackTrace(
      HealthDocumentClientFailure(message, statusCode: status),
      stackTrace ?? StackTrace.current,
    );
  }
  Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
}

class HealthDocumentHttpException implements Exception {
  HealthDocumentHttpException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

void checkHealthDocumentResponse(http.Response response) {
  if (response.statusCode >= 400) {
    String message;
    try {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      message = decoded['error'] as String? ?? 'Unknown error';
    } catch (_) {
      message = 'HTTP ${response.statusCode}';
    }
    throw HealthDocumentHttpException(response.statusCode, message);
  }
}
