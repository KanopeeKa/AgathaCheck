/// PostHog configuration via compile-time defines.
///
/// Example:
///   flutter run --dart-define=POSTHOG_API_KEY=phc_xxx \
///     --dart-define=POSTHOG_HOST=https://eu.i.posthog.com
class AnalyticsConfig {
  static const String apiKey = String.fromEnvironment('POSTHOG_API_KEY');

  static const String host = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.i.posthog.com',
  );

  static const bool sessionReplay = bool.fromEnvironment(
    'POSTHOG_SESSION_REPLAY',
    defaultValue: false,
  );

  static bool get isConfigured => apiKey.isNotEmpty;
}
