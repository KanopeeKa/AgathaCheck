import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';

Future<void> _waitForRefreshToken(AuthNotifier notifier) async {
  for (var i = 0; i < 100 && notifier.state.refreshToken == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('forceRefreshAccessToken dedupes concurrent refreshes (single-flight)',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth_access_token': 'old-access',
      'auth_refresh_token': 'refresh-1',
    });
    final prefs = await SharedPreferences.getInstance();

    var refreshCalls = 0;
    final mock = MockClient((req) async {
      if (req.url.path.endsWith('/api/auth/me')) {
        return http.Response(jsonEncode({'id': '1', 'email': 'a@b.c'}), 200);
      }
      if (req.url.path.endsWith('/api/auth/refresh')) {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(jsonEncode({'access_token': 'new-access'}), 200);
      }
      return http.Response('not found', 404);
    });
    final notifier =
        AuthNotifier(AuthService(baseUrl: '', client: mock), PrefsTokenStore(prefs));
    await _waitForRefreshToken(notifier);
    expect(notifier.state.refreshToken, 'refresh-1');

    final results = await Future.wait([
      notifier.forceRefreshAccessToken(),
      notifier.forceRefreshAccessToken(),
      notifier.forceRefreshAccessToken(),
    ]);

    expect(results, ['new-access', 'new-access', 'new-access']);
    expect(refreshCalls, 1);
    expect(notifier.state.accessToken, 'new-access');
    expect(notifier.state.sessionExpired, isFalse);
  });

  test('forceRefreshAccessToken sets sessionExpired when the refresh fails',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth_access_token': 'old-access',
      'auth_refresh_token': 'refresh-1',
    });
    final prefs = await SharedPreferences.getInstance();

    final mock = MockClient((req) async {
      if (req.url.path.endsWith('/api/auth/me')) {
        return http.Response(jsonEncode({'id': '1', 'email': 'a@b.c'}), 200);
      }
      if (req.url.path.endsWith('/api/auth/refresh')) {
        return http.Response('nope', 401);
      }
      return http.Response('not found', 404);
    });
    final notifier =
        AuthNotifier(AuthService(baseUrl: '', client: mock), PrefsTokenStore(prefs));
    await _waitForRefreshToken(notifier);

    final token = await notifier.forceRefreshAccessToken();

    expect(token, isNull);
    expect(notifier.state.sessionExpired, isTrue);
    expect(notifier.state.accessToken, isNull);
    expect(notifier.state.refreshToken, isNull);
  });
}
