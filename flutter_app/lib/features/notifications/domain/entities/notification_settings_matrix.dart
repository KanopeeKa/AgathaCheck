/// Category × channel matrix (notifications v2 §8.1).
class NotificationCategoryChannels {
  const NotificationCategoryChannels({
    this.inboxAlways = false,
    this.inboxEnabled = true,
    this.pushEnabled = true,
    this.emailEnabled = false,
    this.locked = false,
    this.pushMode = SuggestionPushMode.weeklyDigest,
  });

  final bool inboxAlways;
  final bool inboxEnabled;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool locked;
  final SuggestionPushMode pushMode;

  NotificationCategoryChannels copyWith({
    bool? inboxAlways,
    bool? inboxEnabled,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? locked,
    SuggestionPushMode? pushMode,
  }) {
    return NotificationCategoryChannels(
      inboxAlways: inboxAlways ?? this.inboxAlways,
      inboxEnabled: inboxEnabled ?? this.inboxEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      locked: locked ?? this.locked,
      pushMode: pushMode ?? this.pushMode,
    );
  }
}

enum SuggestionPushMode { off, weeklyDigest, instant }

enum NotificationMatrixCategory {
  invitesRequests,
  accessMembership,
  organisationFoster,
  agathaSuggestions,
  accountSecurity,
  subscription,
}

extension NotificationMatrixCategoryWire on NotificationMatrixCategory {
  String get wireKey {
    switch (this) {
      case NotificationMatrixCategory.invitesRequests:
        return 'invites_requests';
      case NotificationMatrixCategory.accessMembership:
        return 'access_membership';
      case NotificationMatrixCategory.organisationFoster:
        return 'organisation_foster';
      case NotificationMatrixCategory.agathaSuggestions:
        return 'agatha_suggestions';
      case NotificationMatrixCategory.accountSecurity:
        return 'account_security';
      case NotificationMatrixCategory.subscription:
        return 'subscription';
    }
  }
}

class NotificationSettingsMatrix {
  const NotificationSettingsMatrix({required this.categories});

  final Map<NotificationMatrixCategory, NotificationCategoryChannels>
  categories;

  static NotificationSettingsMatrix defaults() {
    return NotificationSettingsMatrix(
      categories: {
        NotificationMatrixCategory.invitesRequests:
            const NotificationCategoryChannels(
              inboxAlways: true,
              pushEnabled: true,
              emailEnabled: true,
            ),
        NotificationMatrixCategory.accessMembership:
            const NotificationCategoryChannels(
              inboxAlways: true,
              pushEnabled: true,
              emailEnabled: false,
            ),
        NotificationMatrixCategory.organisationFoster:
            const NotificationCategoryChannels(
              inboxAlways: true,
              pushEnabled: true,
              emailEnabled: true,
            ),
        NotificationMatrixCategory.agathaSuggestions:
            const NotificationCategoryChannels(
              inboxEnabled: true,
              pushEnabled: false,
              emailEnabled: false,
              pushMode: SuggestionPushMode.weeklyDigest,
            ),
        NotificationMatrixCategory.accountSecurity:
            const NotificationCategoryChannels(
              inboxAlways: true,
              pushEnabled: true,
              emailEnabled: true,
              locked: true,
            ),
        NotificationMatrixCategory.subscription:
            const NotificationCategoryChannels(
              inboxAlways: true,
              pushEnabled: true,
              emailEnabled: true,
            ),
      },
    );
  }

  NotificationCategoryChannels channel(NotificationMatrixCategory category) {
    return categories[category] ??
        NotificationSettingsMatrix.defaults().categories[category]!;
  }

  NotificationSettingsMatrix copyWithCategory(
    NotificationMatrixCategory category,
    NotificationCategoryChannels value,
  ) {
    return NotificationSettingsMatrix(
      categories: {...categories, category: value},
    );
  }
}

const kSuggestionTypeKeys = <String>[
  'suggestionMissingRecurringCare',
  'suggestionWeightTrend',
  'suggestionRepeatedSymptom',
  'suggestionOverduePattern',
  'suggestionStaleRecord',
  'suggestionCareFamily',
  'suggestionShareCoverage',
];

Map<String, bool> defaultSuggestionTypeToggles() {
  return {for (final key in kSuggestionTypeKeys) key: true};
}
