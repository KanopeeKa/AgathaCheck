import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

/// Shared HTTP security helpers (CORS policy + error-detail redaction) used by
/// the shelf server and its route modules. Mirrors `server/config/security.js`;
/// keep the two in lockstep.

bool _isProduction() => Platform.environment['NODE_ENV'] == 'production';

/// Public view of the production flag for route modules that need to redact
/// sensitive values (e.g. the password-reset code) outside the error helpers.
bool isProduction() => _isProduction();

/// Returns a client-safe error string. In production the raw error message is
/// suppressed (it can leak DB/internal details) and [prodMessage] is returned;
/// outside production the detailed message is returned so developers keep full
/// diagnostics.
String publicError(Object error, [String prodMessage = 'Internal server error']) {
  if (_isProduction()) return prodMessage;
  return error.toString();
}

/// Spread into a JSON error map to attach `details` only outside production,
/// e.g. `{'error': 'X failed', ...errorDetails(e)}`.
Map<String, Object?> errorDetails(Object error) {
  if (_isProduction()) return const {};
  return {'details': error.toString()};
}

/// CORS middleware. When `CORS_ALLOWED_ORIGINS` is set (comma-separated), only
/// those origins are allowed. In production with no allowlist, cross-origin
/// requests are denied (the API serves its own same-origin Flutter frontend, so
/// it needs no cross-origin access by default). Outside production CORS stays
/// permissive for local development.
Middleware corsMiddleware() {
  final raw = Platform.environment['CORS_ALLOWED_ORIGINS'];
  if (raw != null && raw.trim().isNotEmpty) {
    final list =
        raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return corsHeaders(originChecker: originOneOf(list));
  }
  if (_isProduction()) {
    return corsHeaders(originChecker: (origin) => false);
  }
  return corsHeaders();
}
