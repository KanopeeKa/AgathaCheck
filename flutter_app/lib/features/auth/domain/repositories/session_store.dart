/// Returned by [SessionStore.readRefreshToken] when the refresh token lives in
/// an HttpOnly cookie and is not readable from Dart.
const kHttpOnlyRefreshSentinel = '__http_only_refresh__';

/// Persists auth tokens (access + refresh). Abstract port — implementations live in `data/`.
abstract class SessionStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> writeAccessToken(String token);
  Future<void> writeTokens(String access, String refresh);
  Future<void> clear();
}
