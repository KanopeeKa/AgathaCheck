import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/core/services/analytics_client.dart';
import 'package:pet_profile_app/core/services/analytics_service.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';

class FakeAnalyticsClient implements AnalyticsClient {
  bool initialized = false;
  bool enabled = false;
  String? identifiedUserId;
  int resetCount = 0;
  final List<String> screens = [];
  final List<String> events = [];

  @override
  Future<void> initialize({required bool enabled}) async {
    initialized = true;
    this.enabled = enabled;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    this.enabled = enabled;
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? properties,
  }) async {
    identifiedUserId = userId;
  }

  @override
  Future<void> reset() async {
    resetCount += 1;
    identifiedUserId = null;
  }

  @override
  Future<void> capture(
    String eventName, [
    Map<String, Object>? properties,
  ]) async {
    events.add(eventName);
  }

  @override
  Future<void> screen(
    String screenName, [
    Map<String, Object>? properties,
  ]) async {
    screens.add(screenName);
  }
}

void main() {
  group('AnalyticsService', () {
    late FakeAnalyticsClient client;
    late AnalyticsService service;

    setUp(() {
      client = FakeAnalyticsClient();
      service = AnalyticsService(client);
    });

    test('does not track before consent', () async {
      await service.trackScreen('home');
      expect(client.screens, isEmpty);
    });

    test('enables tracking after consent', () async {
      await service.applyConsent(hasResponded: true, analyticsConsent: true);
      await service.trackScreen('home');
      expect(client.screens, ['home']);
    });

    test('skips sensitive screens', () async {
      await service.applyConsent(hasResponded: true, analyticsConsent: true);
      await service.trackScreen('healthDashboard');
      expect(client.screens, isEmpty);
    });

    test('identifies user on login when consented', () async {
      await service.applyConsent(hasResponded: true, analyticsConsent: true);
      await service.onLogin(
        AuthUser(
          id: 'user-1',
          email: 'a@example.com',
          category: 'pet_guardian',
        ),
      );
      expect(client.identifiedUserId, 'user-1');
    });

    test('resets on logout', () async {
      await service.applyConsent(hasResponded: true, analyticsConsent: true);
      await service.onLogout();
      expect(client.resetCount, 1);
    });

    test('withdraws consent and resets', () async {
      await service.applyConsent(hasResponded: true, analyticsConsent: true);
      await service.applyConsent(hasResponded: true, analyticsConsent: false);
      expect(client.resetCount, greaterThanOrEqualTo(1));
    });
  });
}
