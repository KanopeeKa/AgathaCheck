import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_kind.dart';

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

  const NotificationPreferencesModel({
    this.emailRemindersEnabled = false,
    this.reminderDaysBefore = 1,
    this.notifyOverdue = true,
    this.notifyDueSoon = true,
    this.notifyCompleted = true,
    this.mutedPetIds = const [],
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      emailRemindersEnabled: json['email_reminders_enabled'] == true,
      reminderDaysBefore: (json['reminder_days_before'] as num?)?.toInt() ?? 1,
      notifyOverdue: json['notify_overdue'] != false,
      notifyDueSoon: json['notify_due_soon'] != false,
      notifyCompleted: json['notify_completed'] != false,
      mutedPetIds:
          (json['muted_pet_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_reminders_enabled': emailRemindersEnabled,
      'reminder_days_before': reminderDaysBefore,
      'notify_overdue': notifyOverdue,
      'notify_due_soon': notifyDueSoon,
      'notify_completed': notifyCompleted,
      'muted_pet_ids': mutedPetIds,
    };
  }
}
