import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefsTokenStore', () {
    test('writes, reads, and clears tokens', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PrefsTokenStore(prefs);

      expect(await store.readAccessToken(), isNull);

      await store.writeTokens('access-1', 'refresh-1');
      expect(await store.readAccessToken(), 'access-1');
      expect(await store.readRefreshToken(), 'refresh-1');

      await store.writeAccessToken('access-2');
      expect(await store.readAccessToken(), 'access-2');
      expect(await store.readRefreshToken(), 'refresh-1');

      await store.clear();
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('uses the canonical SharedPreferences keys (back-compat)', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'a',
        'auth_refresh_token': 'r',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = PrefsTokenStore(prefs);
      expect(await store.readAccessToken(), 'a');
      expect(await store.readRefreshToken(), 'r');
    });
  });

  group('migrateLegacyTokensFromPrefs', () {
    test(
      'copies prefs tokens into secure storage when secure is empty',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'legacy-access',
          'auth_refresh_token': 'legacy-refresh',
        });
        final prefs = await SharedPreferences.getInstance();
        final secure = <String, String>{};

        await migrateLegacyTokensFromPrefs(
          prefs: prefs,
          readSecure: (key) async => secure[key],
          writeSecure: (key, value) async => secure[key] = value,
        );

        expect(secure['auth_access_token'], 'legacy-access');
        expect(secure['auth_refresh_token'], 'legacy-refresh');
        expect(prefs.getString('auth_access_token'), isNull);
        expect(prefs.getString('auth_refresh_token'), isNull);
      },
    );

    test('does not overwrite existing secure tokens', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'legacy-access',
        'auth_refresh_token': 'legacy-refresh',
      });
      final prefs = await SharedPreferences.getInstance();
      final secure = <String, String>{'auth_access_token': 'secure-access'};

      await migrateLegacyTokensFromPrefs(
        prefs: prefs,
        readSecure: (key) async => secure[key],
        writeSecure: (key, value) async => secure[key] = value,
      );

      expect(secure['auth_access_token'], 'secure-access');
      expect(secure.containsKey('auth_refresh_token'), isFalse);
      expect(prefs.getString('auth_access_token'), 'legacy-access');
      expect(prefs.getString('auth_refresh_token'), 'legacy-refresh');
    });

    test('no-op when both stores are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final secure = <String, String>{};

      await migrateLegacyTokensFromPrefs(
        prefs: prefs,
        readSecure: (key) async => secure[key],
        writeSecure: (key, value) async => secure[key] = value,
      );

      expect(secure, isEmpty);
    });
  });

  group('WebTokenStore', () {
    test('stores access in memory and returns refresh sentinel', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'legacy-access',
        'auth_refresh_token': 'legacy-refresh',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = WebTokenStore(prefs);

      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);

      await store.writeTokens('access-1', 'ignored-refresh');
      expect(await store.readAccessToken(), 'access-1');
      expect(await store.readRefreshToken(), kHttpOnlyRefreshSentinel);
      expect(prefs.getString('auth_access_token'), isNull);
      expect(prefs.getString('auth_refresh_token'), isNull);

      await store.writeAccessToken('access-2');
      expect(await store.readAccessToken(), 'access-2');
      expect(await store.readRefreshToken(), kHttpOnlyRefreshSentinel);

      await store.clear();
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('clears legacy SharedPreferences keys on first use', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'legacy-access',
        'auth_refresh_token': 'legacy-refresh',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = WebTokenStore(prefs);

      await store.readAccessToken();
      expect(prefs.getString('auth_access_token'), isNull);
      expect(prefs.getString('auth_refresh_token'), isNull);
    });
  });

  group('createTokenStore platform selection', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('returns SecureTokenStore on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(createTokenStore(prefs), isA<SecureTokenStore>());
    });

    test('returns SecureTokenStore on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(createTokenStore(prefs), isA<SecureTokenStore>());
    });

    test('returns PrefsTokenStore on desktop (non-mobile)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(createTokenStore(prefs), isA<PrefsTokenStore>());
    });
  });
}
