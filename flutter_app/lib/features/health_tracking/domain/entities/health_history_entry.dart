/// Represents a single history record of when a health entry occurrence was completed.
class HealthHistoryEntry {
  /// Creates a new [HealthHistoryEntry] instance.
  const HealthHistoryEntry({
    required this.id,
    required this.entryId,
    required this.markedAt,
    this.dueDate,
    this.completedOn,
    this.markedByUserId,
    this.markedByName,
    this.notes = '',
  });

  final String id;
  final String entryId;

  /// When the user recorded completion (c).
  final DateTime markedAt;

  /// When the occurrence was due (a).
  final DateTime? dueDate;

  /// When it actually happened (b).
  final DateTime? completedOn;

  final String? markedByUserId;
  final String? markedByName;
  final String notes;

  /// Legacy alias for [markedAt].
  DateTime get takenAt => markedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthHistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
