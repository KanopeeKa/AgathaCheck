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

/// SharedPreferences-backed store (web/dev/tests). Tokens live in plaintext
/// local storage — acceptable on web (no OS keychain) but not on mobile, where
/// [SecureTokenStore] is used instead.
class PrefsTokenStore implements TokenStore {
  PrefsTokenStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> readAccessToken() async => _prefs.getString(_accessTokenKey);
  @override
  Future<String?> readRefreshToken() async => _prefs.getString(_refreshTokenKey);
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

/// flutter_secure_storage-backed store for mobile (iOS Keychain / Android
/// EncryptedSharedPreferences/Keystore).
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);
  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);
  @override
  Future<void> writeTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

/// Picks the right store for the platform: secure storage on Android/iOS, and
/// SharedPreferences everywhere else (web/desktop/tests).
TokenStore createTokenStore(SharedPreferences prefs) {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return SecureTokenStore(const FlutterSecureStorage());
  }
  return PrefsTokenStore(prefs);
}
