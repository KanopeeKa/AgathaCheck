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
