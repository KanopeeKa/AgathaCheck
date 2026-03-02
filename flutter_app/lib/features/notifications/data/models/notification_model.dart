import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    super.petId,
    super.petName,
    super.healthEntryId,
    required super.title,
    required super.message,
    required super.type,
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
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _parseType(json['type']?.toString() ?? 'general'),
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
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
      'title': title,
      'message': message,
      'type': type.name,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'due_soon':
        return NotificationType.dueSoon;
      case 'overdue':
        return NotificationType.overdue;
      case 'reminder':
        return NotificationType.reminder;
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

  const NotificationPreferencesModel({
    this.emailRemindersEnabled = false,
    this.reminderDaysBefore = 1,
    this.notifyOverdue = true,
    this.notifyDueSoon = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      emailRemindersEnabled: json['email_reminders_enabled'] == true,
      reminderDaysBefore: (json['reminder_days_before'] as num?)?.toInt() ?? 1,
      notifyOverdue: json['notify_overdue'] != false,
      notifyDueSoon: json['notify_due_soon'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_reminders_enabled': emailRemindersEnabled,
      'reminder_days_before': reminderDaysBefore,
      'notify_overdue': notifyOverdue,
      'notify_due_soon': notifyDueSoon,
    };
  }
}
