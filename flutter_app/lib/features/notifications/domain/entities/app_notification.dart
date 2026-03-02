enum NotificationType {
  dueSoon,
  overdue,
  reminder,
  completed,
  general,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    this.petId,
    this.petName,
    this.healthEntryId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? petId;
  final String? petName;
  final String? healthEntryId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({
    String? id,
    String? userId,
    String? petId,
    String? petName,
    String? healthEntryId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      healthEntryId: healthEntryId ?? this.healthEntryId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
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
