/// Summary of an adjacent occurrence on the Care date timeline (CARE-ITEM-R-020).
class OccurrenceNeighborSummary {
  const OccurrenceNeighborSummary({
    required this.id,
    required this.scheduledDate,
    this.scheduledTime,
    required this.occurrenceStatus,
    this.completedOn,
    this.performedByName,
  });

  final String id;
  final DateTime scheduledDate;
  final String? scheduledTime;

  /// Wire `occurrence_status` (due, overdue, done, skipped, …).
  final String occurrenceStatus;
  final DateTime? completedOn;
  final String? performedByName;
}
