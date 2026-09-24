import 'health_occurrence.dart';

/// Result of POST …/occurrences/:id/reschedule (D-ACP-009).
class RescheduleOccurrenceResult {
  const RescheduleOccurrenceResult({
    required this.occurrence,
    required this.warnings,
    this.nextDueDate,
  });

  final HealthOccurrence occurrence;
  final List<Map<String, dynamic>> warnings;
  final DateTime? nextDueDate;
}
