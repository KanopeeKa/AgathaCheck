import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the auth tokens. Abstracted so mobile can use the platform secure
/// store (iOS Keychain / Android Keystore) while web and tests use
/// SharedPreferences.
abstract class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> writeAccessToken(String token);
  Future<void> writeTokens(String access, String refresh);
  Future<void> clear();
}

const _accessTokenKey = 'auth_access_token';
const _refreshTokenKey = 'auth_refresh_token';

/// Returned by [WebTokenStore.readRefreshToken] when the refresh token lives in
/// an HttpOnly cookie and is not readable from Dart.
const kHttpOnlyRefreshSentinel = '__http_only_refresh__';

/// SharedPreferences-backed store (web/dev/tests). Tokens live in plaintext
/// local storage — acceptable on web (no OS keychain) but not on mobile, where
/// [SecureTokenStore] is used instead.
class PrefsTokenStore implements TokenStore {
  PrefsTokenStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> readAccessToken() async => _prefs.getString(_accessTokenKey);
  @override
  Future<String?> readRefreshToken() async =>
      _prefs.getString(_refreshTokenKey);
  @override
  Future<void> writeAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
  }

  @override
  Future<void> writeTokens(String access, String refresh) async {
    await _prefs.setString(_accessTokenKey, access);
    await _prefs.setString(_refreshTokenKey, refresh);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
}

/// Web-only store: access token in memory; refresh token in HttpOnly cookie.
class WebTokenStore implements TokenStore {
  WebTokenStore(this._prefs);

  final SharedPreferences _prefs;
  String? _accessToken;
  bool _httpOnlyRefreshActive = false;
  bool _migrationAttempted = false;

  Future<void> _maybeMigrateFromPrefs() async {
    if (_migrationAttempted) return;
    _migrationAttempted = true;
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  @override
  Future<String?> readAccessToken() async {
    await _maybeMigrateFromPrefs();
    return _accessToken;
  }

  @override
  Future<String?> readRefreshToken() async {
    await _maybeMigrateFromPrefs();
    return _httpOnlyRefreshActive ? kHttpOnlyRefreshSentinel : null;
  }

  @override
  Future<void> writeAccessToken(String token) async {
    await _maybeMigrateFromPrefs();
    _accessToken = token;
    await _prefs.remove(_accessTokenKey);
  }

  @override
  Future<void> writeTokens(String access, String refresh) async {
    await _maybeMigrateFromPrefs();
    _accessToken = access;
    _httpOnlyRefreshActive = true;
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _httpOnlyRefreshActive = false;
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
}

/// One-time migration for app upgrades that switched mobile from
/// [PrefsTokenStore] to [SecureTokenStore]: copy legacy SharedPreferences
/// tokens into secure storage when secure storage is empty, then clear prefs.
@visibleForTesting
Future<void> migrateLegacyTokensFromPrefs({
  required SharedPreferences prefs,
  required Future<String?> Function(String key) readSecure,
  required Future<void> Function(String key, String value) writeSecure,
}) async {
  final secureAccess = await readSecure(_accessTokenKey);
  final secureRefresh = await readSecure(_refreshTokenKey);
  if (secureAccess != null || secureRefresh != null) return;

  final prefsAccess = prefs.getString(_accessTokenKey);
  final prefsRefresh = prefs.getString(_refreshTokenKey);
  if (prefsAccess == null && prefsRefresh == null) return;

  if (prefsAccess != null) {
    await writeSecure(_accessTokenKey, prefsAccess);
  }
  if (prefsRefresh != null) {
    await writeSecure(_refreshTokenKey, prefsRefresh);
  }
  await prefs.remove(_accessTokenKey);
  await prefs.remove(_refreshTokenKey);
}

/// flutter_secure_storage-backed store for mobile (iOS Keychain / Android
/// EncryptedSharedPreferences/Keystore).
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage, {SharedPreferences? legacyPrefs})
    : _legacyPrefs = legacyPrefs;

  final FlutterSecureStorage _storage;
  final SharedPreferences? _legacyPrefs;
  bool _migrationAttempted = false;

  Future<void> _maybeMigrateFromPrefs() async {
    if (_migrationAttempted || _legacyPrefs == null) return;
    _migrationAttempted = true;
    await migrateLegacyTokensFromPrefs(
      prefs: _legacyPrefs,
      readSecure: (key) => _storage.read(key: key),
      writeSecure: (key, value) => _storage.write(key: key, value: value),
    );
  }

  Future<void> _clearLegacyPrefs() async {
    if (_legacyPrefs == null) return;
    await _legacyPrefs.remove(_accessTokenKey);
    await _legacyPrefs.remove(_refreshTokenKey);
  }

  @override
  Future<String?> readAccessToken() async {
    await _maybeMigrateFromPrefs();
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() async {
    await _maybeMigrateFromPrefs();
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> writeAccessToken(String token) async {
    await _maybeMigrateFromPrefs();
    await _storage.write(key: _accessTokenKey, value: token);
    await _clearLegacyPrefs();
  }

  @override
  Future<void> writeTokens(String access, String refresh) async {
    await _maybeMigrateFromPrefs();
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
    await _clearLegacyPrefs();
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _clearLegacyPrefs();
  }
}

/// Picks the right store for the platform: secure storage on Android/iOS,
/// in-memory access + HttpOnly cookie refresh on web, SharedPreferences elsewhere.
TokenStore createTokenStore(SharedPreferences prefs) {
  if (kIsWeb) {
    return WebTokenStore(prefs);
  }
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return SecureTokenStore(const FlutterSecureStorage(), legacyPrefs: prefs);
  }
  return PrefsTokenStore(prefs);
}
