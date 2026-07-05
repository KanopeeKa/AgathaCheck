abstract class AnalyticsClient {
  Future<void> initialize({required bool enabled});

  Future<void> setEnabled(bool enabled);

  Future<void> identify({
    required String userId,
    Map<String, Object>? properties,
  });

  Future<void> reset();

  Future<void> capture(String eventName, [Map<String, Object>? properties]);

  Future<void> screen(String screenName, [Map<String, Object>? properties]);
}
