import '../../domain/entities/health_occurrence.dart';

/// Resolved past rows for History inline and pop-up (newest first on wire).
List<HealthOccurrence> resolvedPastOccurrences(List<HealthOccurrence> past) {
  return past
      .where(
        (o) =>
            o.status == 'completed' ||
            o.status == 'skipped' ||
            o.status == 'not_recorded',
      )
      .toList();
}

bool occurrenceIsNotRecorded(HealthOccurrence o) {
  return o.status == 'not_recorded' || o.outcome == 'not_recorded';
}

bool occurrenceIsSkipped(HealthOccurrence o) => o.status == 'skipped';

bool occurrenceIsDone(HealthOccurrence o) => o.status == 'completed';
