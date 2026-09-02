/// A single scheduled dose instant for a [HealthEntry] series.
class HealthOccurrence {
  const HealthOccurrence({
    required this.id,
    required this.entryId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.completedOn,
    this.markedAt,
    this.markedByUserId,
    this.markedByName,
    this.notes = '',
    this.missed = false,
  });

  final String id;
  final String entryId;

  /// Calendar day (`YYYY-MM-DD` wire).
  final DateTime scheduledDate;

  /// Local wall-clock `HH:mm`, or null for all-day.
  final String? scheduledTime;

  /// `pending`, `completed`, or `skipped`.
  final String status;

  final DateTime? completedOn;
  final DateTime? markedAt;
  final String? markedByUserId;
  final String? markedByName;
  final String notes;

  /// Server hint; client recomputes with device local clock when displaying.
  final bool missed;

  bool get isPending => status == 'pending';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthOccurrence &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
