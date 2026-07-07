import '../../features/auth/data/auth_service.dart';
import '../config/analytics_config.dart';
import 'analytics_client.dart';
import 'posthog_analytics_client.dart';

/// Screens where session replay and detailed analytics must not capture content.
const sensitiveAnalyticsScreens = {
  'healthDashboard',
  'healthEntryForm',
  'otherEventForm',
  'organizationPersonDetail',
  'myDetails',
};

class AnalyticsService {
  AnalyticsService(this._client);

  final AnalyticsClient _client;
  bool _consentGranted = false;

  factory AnalyticsService.create() {
    if (AnalyticsConfig.isConfigured) {
      return AnalyticsService(PosthogAnalyticsClient());
    }
    return AnalyticsService(NoopAnalyticsClient());
  }

  Future<void> applyConsent({
    required bool hasResponded,
    required bool analyticsConsent,
  }) async {
    final shouldEnable = hasResponded && analyticsConsent;
    if (!_consentGranted && shouldEnable) {
      await _client.initialize(enabled: true);
    } else {
      await _client.setEnabled(shouldEnable);
    }
    _consentGranted = shouldEnable;
    if (!shouldEnable) {
      await _client.reset();
    }
  }

  Future<void> onLogin(AuthUser user) async {
    if (!_consentGranted) return;
    await _client.identify(
      userId: user.id,
      properties: {if (user.category != null) 'category': user.category!},
    );
  }

  Future<void> onLogout() async {
    await _client.reset();
  }

  Future<void> trackScreen(String? screenName) async {
    if (!_consentGranted || screenName == null || screenName.isEmpty) return;
    if (sensitiveAnalyticsScreens.contains(screenName)) return;
    await _client.screen(screenName);
  }

  Future<void> capture(
    String eventName, [
    Map<String, Object>? properties,
  ]) async {
    if (!_consentGranted) return;
    await _client.capture(eventName, properties);
  }
}
