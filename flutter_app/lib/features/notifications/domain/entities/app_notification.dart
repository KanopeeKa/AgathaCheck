import 'notification_kind.dart';

enum NotificationType {
  dueSoon,
  overdue,
  reminder,
  completed,
  general;

  String get label {
    switch (this) {
      case NotificationType.dueSoon:
        return 'Due Soon';
      case NotificationType.overdue:
        return 'Overdue';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.completed:
        return 'Completed';
      case NotificationType.general:
        return 'General';
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    this.petId,
    this.petName,
    this.healthEntryId,
    this.organizationId,
    required this.title,
    required this.message,
    required this.type,
    this.wireType = 'general',
    this.kind = NotificationKind.care,
    this.priority = NotificationPriority.normal,
    this.resolvedAt,
    required this.isRead,
    required this.createdAt,
    this.suggestionDedupeKey,
    this.suggestionState,
    this.suggestionConfidence,
    this.suggestionExpiresAt,
    this.suggestionPayload,
  });

  final String id;
  final String userId;
  final String? petId;
  final String? petName;
  final String? healthEntryId;
  final String? organizationId;
  final String title;
  final String message;
  final NotificationType type;
  final String wireType;
  final NotificationKind kind;
  final NotificationPriority priority;
  final DateTime? resolvedAt;
  final bool isRead;
  final DateTime createdAt;
  final String? suggestionDedupeKey;
  final String? suggestionState;
  final double? suggestionConfidence;
  final DateTime? suggestionExpiresAt;
  final Map<String, dynamic>? suggestionPayload;

  bool get isSuggestionUnread =>
      kind == NotificationKind.suggestion &&
      (suggestionState == 'new' || (suggestionState == null && !isRead));

  /// FR-SC-3 — health-adjacent suggestion copy (S2, S3).
  bool get showsHealthAdjacentDisclaimer =>
      wireType == 'suggestionWeightTrend' ||
      wireType == 'suggestionRepeatedSymptom' ||
      suggestionPayload?['health_adjacent'] == true;

  AppNotification copyWith({
    String? id,
    String? userId,
    String? petId,
    String? petName,
    String? healthEntryId,
    String? organizationId,
    String? title,
    String? message,
    NotificationType? type,
    String? wireType,
    NotificationKind? kind,
    NotificationPriority? priority,
    DateTime? resolvedAt,
    bool? isRead,
    DateTime? createdAt,
    String? suggestionDedupeKey,
    String? suggestionState,
    double? suggestionConfidence,
    DateTime? suggestionExpiresAt,
    Map<String, dynamic>? suggestionPayload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      healthEntryId: healthEntryId ?? this.healthEntryId,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      wireType: wireType ?? this.wireType,
      kind: kind ?? this.kind,
      priority: priority ?? this.priority,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      suggestionDedupeKey: suggestionDedupeKey ?? this.suggestionDedupeKey,
      suggestionState: suggestionState ?? this.suggestionState,
      suggestionConfidence: suggestionConfidence ?? this.suggestionConfidence,
      suggestionExpiresAt: suggestionExpiresAt ?? this.suggestionExpiresAt,
      suggestionPayload: suggestionPayload ?? this.suggestionPayload,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Default kind for existing [NotificationType] values (Phase 0 — all care today).
NotificationKind defaultKindForNotificationType(NotificationType type) {
  switch (type) {
    case NotificationType.dueSoon:
    case NotificationType.overdue:
    case NotificationType.reminder:
    case NotificationType.completed:
    case NotificationType.general:
      return NotificationKind.care;
  }
}
