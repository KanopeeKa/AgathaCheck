import 'health_occurrence.dart';

/// Result of POST …/occurrences/ensure-open (D-CSM-018).
class EnsureOpenOccurrenceResult {
  const EnsureOpenOccurrenceResult({
    required this.occurrences,
    required this.created,
    this.nextDueDate,
    this.headDate,
  });

  final List<HealthOccurrence> occurrences;
  final bool created;
  final DateTime? nextDueDate;

  /// Canonical open head (`YYYY-MM-DD` wire).
  final DateTime? headDate;
}
