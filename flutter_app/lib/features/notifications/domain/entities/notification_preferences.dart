import 'notification_settings_matrix.dart';

class NotificationPreferences {
  NotificationPreferences({
    this.emailRemindersEnabled = false,
    this.reminderDaysBefore = 1,
    this.notifyOverdue = true,
    this.notifyDueSoon = true,
    this.notifyCompleted = true,
    this.mutedPetIds = const [],
    this.v2ExplainerDismissedAt,
    this.agathaSuggestionsInApp = true,
    NotificationSettingsMatrix? settingsMatrix,
    Map<String, bool>? suggestionTypes,
  }) : settingsMatrix = settingsMatrix ?? NotificationSettingsMatrix.defaults(),
       suggestionTypes = suggestionTypes ?? defaultSuggestionTypeToggles();

  final bool emailRemindersEnabled;
  final int reminderDaysBefore;
  final bool notifyOverdue;
  final bool notifyDueSoon;
  final bool notifyCompleted;
  final List<String> mutedPetIds;
  final DateTime? v2ExplainerDismissedAt;
  final bool agathaSuggestionsInApp;
  final NotificationSettingsMatrix settingsMatrix;
  final Map<String, bool> suggestionTypes;

  NotificationPreferences copyWith({
    bool? emailRemindersEnabled,
    int? reminderDaysBefore,
    bool? notifyOverdue,
    bool? notifyDueSoon,
    bool? notifyCompleted,
    List<String>? mutedPetIds,
    DateTime? v2ExplainerDismissedAt,
    bool? agathaSuggestionsInApp,
    NotificationSettingsMatrix? settingsMatrix,
    Map<String, bool>? suggestionTypes,
  }) {
    return NotificationPreferences(
      emailRemindersEnabled:
          emailRemindersEnabled ?? this.emailRemindersEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notifyOverdue: notifyOverdue ?? this.notifyOverdue,
      notifyDueSoon: notifyDueSoon ?? this.notifyDueSoon,
      notifyCompleted: notifyCompleted ?? this.notifyCompleted,
      mutedPetIds: mutedPetIds ?? this.mutedPetIds,
      v2ExplainerDismissedAt:
          v2ExplainerDismissedAt ?? this.v2ExplainerDismissedAt,
      agathaSuggestionsInApp:
          agathaSuggestionsInApp ?? this.agathaSuggestionsInApp,
      settingsMatrix: settingsMatrix ?? this.settingsMatrix,
      suggestionTypes: suggestionTypes ?? this.suggestionTypes,
    );
  }
}
