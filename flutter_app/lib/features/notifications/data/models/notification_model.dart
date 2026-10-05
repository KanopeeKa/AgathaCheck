import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_kind.dart';
import '../../domain/entities/notification_settings_matrix.dart';
import 'notification_preferences_matrix_codec.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    super.petId,
    super.petName,
    super.healthEntryId,
    super.organizationId,
    required super.title,
    required super.message,
    required super.type,
    super.wireType,
    super.kind,
    super.priority,
    super.resolvedAt,
    required super.isRead,
    required super.createdAt,
    super.suggestionDedupeKey,
    super.suggestionState,
    super.suggestionConfidence,
    super.suggestionExpiresAt,
    super.suggestionPayload,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      petId: json['pet_id']?.toString(),
      petName: json['pet_name']?.toString(),
      healthEntryId: json['health_entry_id']?.toString(),
      organizationId: json['organization_id']?.toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _parseType(json['type']?.toString() ?? 'general'),
      wireType: json['type']?.toString() ?? 'general',
      kind: json['kind'] != null
          ? NotificationKind.fromWire(json['kind']?.toString())
          : defaultKindForNotificationType(
              _parseType(json['type']?.toString() ?? 'general'),
            ),
      priority: NotificationPriority.fromWire(json['priority']?.toString()),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      isRead: json['is_read'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      suggestionDedupeKey: json['suggestion_dedupe_key']?.toString(),
      suggestionState: json['suggestion_state']?.toString(),
      suggestionConfidence: (json['suggestion_confidence'] as num?)?.toDouble(),
      suggestionExpiresAt: json['suggestion_expires_at'] != null
          ? DateTime.tryParse(json['suggestion_expires_at'].toString())
          : null,
      suggestionPayload: json['suggestion_payload'] is Map
          ? Map<String, dynamic>.from(json['suggestion_payload'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pet_id': petId,
      'pet_name': petName,
      'health_entry_id': healthEntryId,
      'organization_id': organizationId,
      'title': title,
      'message': message,
      'type': typeToApi(type),
      'kind': kind.wireValue,
      'priority': priority.wireValue,
      'resolved_at': resolvedAt?.toIso8601String(),
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Serializes [NotificationType] to its canonical API string. MUST NOT use
  /// `enum.name`: it is minified in release builds and `dueSoon` would not even
  /// match the snake_case `_parseType` the server emits. Exhaustive by design.
  static String typeToApi(NotificationType type) {
    switch (type) {
      case NotificationType.dueSoon:
        return 'due_soon';
      case NotificationType.overdue:
        return 'overdue';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.completed:
        return 'completed';
      case NotificationType.general:
        return 'general';
    }
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'due_soon':
        return NotificationType.dueSoon;
      case 'overdue':
        return NotificationType.overdue;
      case 'reminder':
        return NotificationType.reminder;
      case 'completed':
        return NotificationType.completed;
      default:
        return NotificationType.general;
    }
  }
}

class NotificationPreferencesModel {
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

  NotificationPreferencesModel({
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

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    final matrix = parseSettingsMatrix(
      json['settings_matrix'] as Map<String, dynamic>?,
    );
    final agathaInApp =
        json['agatha_suggestions_in_app'] != false &&
        matrix
            .channel(NotificationMatrixCategory.agathaSuggestions)
            .inboxEnabled;
    return NotificationPreferencesModel(
      emailRemindersEnabled: _parseBool(json['email_reminders_enabled']),
      reminderDaysBefore: (json['reminder_days_before'] as num?)?.toInt() ?? 1,
      notifyOverdue:
          json['notify_overdue'] != false &&
          json['notify_overdue']?.toString() != 'false',
      notifyDueSoon:
          json['notify_due_soon'] != false &&
          json['notify_due_soon']?.toString() != 'false',
      notifyCompleted:
          json['notify_completed'] != false &&
          json['notify_completed']?.toString() != 'false',
      mutedPetIds:
          (json['muted_pet_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      v2ExplainerDismissedAt: json['v2_explainer_dismissed_at'] != null
          ? DateTime.tryParse(json['v2_explainer_dismissed_at'].toString())
          : null,
      agathaSuggestionsInApp: agathaInApp,
      settingsMatrix: matrix,
      suggestionTypes: parseSuggestionTypes(
        json['suggestion_types'] as Map<String, dynamic>?,
      ),
    );
  }

  static bool _parseBool(Object? value) {
    if (value == true) return true;
    if (value == false) return false;
    return value?.toString().toLowerCase() == 'true';
  }

  Map<String, dynamic> toJson() {
    final matrixJson = settingsMatrixToJson(settingsMatrix);
    matrixJson[NotificationMatrixCategory.agathaSuggestions.wireKey] = {
      ...matrixJson[NotificationMatrixCategory.agathaSuggestions.wireKey]
          as Map<String, dynamic>,
      'inbox': agathaSuggestionsInApp,
    };
    return {
      'email_reminders_enabled': emailRemindersEnabled,
      'reminder_days_before': reminderDaysBefore,
      'notify_overdue': notifyOverdue,
      'notify_due_soon': notifyDueSoon,
      'notify_completed': notifyCompleted,
      'muted_pet_ids': mutedPetIds,
      'agatha_suggestions_in_app': agathaSuggestionsInApp,
      'settings_matrix': matrixJson,
      'suggestion_types': suggestionTypesToJson(suggestionTypes),
      if (v2ExplainerDismissedAt != null)
        'v2_explainer_dismissed_at': v2ExplainerDismissedAt!
            .toUtc()
            .toIso8601String(),
    };
  }
}
