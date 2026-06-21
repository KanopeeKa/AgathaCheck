import 'dart:io';

/// Single source of truth for the JWT signing secret, shared by every shelf
/// route module so the resolution rules cannot drift between files.
///
/// Resolves `JWT_SECRET`, falling back to `SESSION_SECRET`. In production
/// (`NODE_ENV=production`) a missing secret throws immediately rather than
/// silently signing tokens with a publicly-known default — which would allow
/// token forgery. The dev/test fallback is intentionally kept (so local runs
/// work without extra setup) but is unreachable in production because of the
/// throw. Mirrors `server/config/jwtSecret.js`; keep the two in lockstep.
///
/// Generate a strong secret with: openssl rand -hex 32
final String jwtSecret = _resolveJwtSecret();

String _resolveJwtSecret() {
  final resolved = Platform.environment['JWT_SECRET'] ??
      Platform.environment['SESSION_SECRET'];
  if (resolved == null && Platform.environment['NODE_ENV'] == 'production') {
    throw StateError(
      'JWT_SECRET (or SESSION_SECRET) is required in production. '
      'Generate one with: openssl rand -hex 32',
    );
  }
  return resolved ?? 'default_secret';
}
