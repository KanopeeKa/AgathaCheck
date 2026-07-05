import 'package:posthog_flutter/posthog_flutter.dart';

import '../config/analytics_config.dart';
import 'analytics_client.dart';

class NoopAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> initialize({required bool enabled}) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? properties,
  }) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> capture(String eventName, [Map<String, Object>? properties]) async {}

  @override
  Future<void> screen(String screenName, [Map<String, Object>? properties]) async {}
}

class PosthogAnalyticsClient implements AnalyticsClient {
  bool _initialized = false;
  bool _enabled = false;

  @override
  Future<void> initialize({required bool enabled}) async {
    if (!AnalyticsConfig.isConfigured) return;

    final config = PostHogConfig(AnalyticsConfig.apiKey)
      ..host = AnalyticsConfig.host
      ..captureApplicationLifecycleEvents = false
      ..debug = false
      ..sessionReplay = AnalyticsConfig.sessionReplay;

    if (AnalyticsConfig.sessionReplay) {
      config.sessionReplayConfig.maskAllTexts = true;
      config.sessionReplayConfig.maskAllImages = true;
    }

    config.beforeSend = [
      (event) {
        if (!_enabled) return null;
        event.properties?.remove('email');
        event.properties?.remove('notes');
        event.properties?.remove('bio');
        return event;
      },
    ];

    await Posthog().setup(config);
    _initialized = true;
    await setEnabled(enabled);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!_initialized) return;
    if (enabled) {
      await Posthog().enable();
    } else {
      await Posthog().disable();
      await Posthog().reset();
    }
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? properties,
  }) async {
    if (!_enabled || !_initialized) return;
    await Posthog().identify(
      userId: userId,
      userProperties: properties,
    );
  }

  @override
  Future<void> reset() async {
    if (!_initialized) return;
    await Posthog().reset();
  }

  @override
  Future<void> capture(String eventName, [Map<String, Object>? properties]) async {
    if (!_enabled || !_initialized) return;
    await Posthog().capture(
      eventName: eventName,
      properties: properties ?? const {},
    );
  }

  @override
  Future<void> screen(String screenName, [Map<String, Object>? properties]) async {
    if (!_enabled || !_initialized) return;
    await Posthog().screen(
      screenName: screenName,
      properties: properties ?? const {},
    );
  }
}
