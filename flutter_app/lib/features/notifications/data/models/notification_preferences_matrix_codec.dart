import '../../domain/entities/notification_settings_matrix.dart';

SuggestionPushMode parseSuggestionPushMode(Object? raw) {
  final value = raw?.toString() ?? '';
  switch (value) {
    case 'instant':
      return SuggestionPushMode.instant;
    case 'off':
      return SuggestionPushMode.off;
    case 'weekly_digest':
    default:
      return SuggestionPushMode.weeklyDigest;
  }
}

String suggestionPushModeWire(SuggestionPushMode mode) {
  switch (mode) {
    case SuggestionPushMode.instant:
      return 'instant';
    case SuggestionPushMode.off:
      return 'off';
    case SuggestionPushMode.weeklyDigest:
      return 'weekly_digest';
  }
}

NotificationCategoryChannels _parseCategoryChannels(
  Map<String, dynamic>? json,
) {
  if (json == null) {
    return const NotificationCategoryChannels();
  }
  final inbox = json['inbox'];
  final inboxAlways = inbox == 'always';
  final inboxEnabled = inboxAlways || inbox == true || inbox == 'true';
  return NotificationCategoryChannels(
    inboxAlways: inboxAlways,
    inboxEnabled: inboxEnabled,
    pushEnabled: json['push'] != false,
    emailEnabled: json['email'] == true,
    locked: json['locked'] == true,
    pushMode: parseSuggestionPushMode(json['push_mode']),
  );
}

Map<String, dynamic> categoryChannelsToJson(NotificationCategoryChannels ch) {
  return {
    'inbox': ch.inboxAlways ? 'always' : ch.inboxEnabled,
    'push': ch.pushEnabled,
    'email': ch.emailEnabled,
    if (ch.locked) 'locked': true,
    'push_mode': suggestionPushModeWire(ch.pushMode),
  };
}

NotificationSettingsMatrix parseSettingsMatrix(Map<String, dynamic>? json) {
  final defaults = NotificationSettingsMatrix.defaults();
  if (json == null || json.isEmpty) return defaults;
  final categories =
      <NotificationMatrixCategory, NotificationCategoryChannels>{};
  for (final category in NotificationMatrixCategory.values) {
    final wire = category.wireKey;
    final raw = json[wire];
    if (raw is Map<String, dynamic>) {
      categories[category] = _parseCategoryChannels(raw);
    } else {
      categories[category] = defaults.channel(category);
    }
  }
  return NotificationSettingsMatrix(categories: categories);
}

Map<String, dynamic> settingsMatrixToJson(NotificationSettingsMatrix matrix) {
  return {
    for (final category in NotificationMatrixCategory.values)
      category.wireKey: categoryChannelsToJson(matrix.channel(category)),
  };
}

Map<String, bool> parseSuggestionTypes(Map<String, dynamic>? json) {
  final defaults = defaultSuggestionTypeToggles();
  if (json == null) return defaults;
  final merged = Map<String, bool>.from(defaults);
  for (final key in kSuggestionTypeKeys) {
    if (json.containsKey(key)) {
      merged[key] = json[key] == true;
    }
  }
  return merged;
}

Map<String, dynamic> suggestionTypesToJson(Map<String, bool> types) {
  return {for (final key in kSuggestionTypeKeys) key: types[key] ?? true};
}
