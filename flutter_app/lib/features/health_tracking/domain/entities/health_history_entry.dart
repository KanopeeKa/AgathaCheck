/// Represents a single history record of when a health entry was taken/administered.
class HealthHistoryEntry {
  /// Creates a new [HealthHistoryEntry] instance.
  const HealthHistoryEntry({
    required this.id,
    required this.entryId,
    required this.takenAt,
    this.notes = '',
  });

  /// Unique identifier for this history record.
  final String id;

  /// The health entry this record belongs to.
  final String entryId;

  /// When the entry was taken/administered.
  final DateTime takenAt;

  /// Additional notes for this administration.
  final String notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthHistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
