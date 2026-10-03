/// Occurrence values as the server sends them (D-CIE-028, §18.7.1).
///
/// Status and "today" come from the server in the pet's home timezone; the
/// app never derives them from the device clock.
library;

/// Open: coming up, due, overdue, not recorded. Closed (occurrence screen):
/// done, skipped, not recorded.
enum CareOccurrenceStatus {
  comingUp,
  due,
  overdue,
  notRecorded,
  done,
  skipped,
  unknown,
}

CareOccurrenceStatus careOccurrenceStatusFromApi(String? value) {
  switch (value) {
    case 'coming_up':
      return CareOccurrenceStatus.comingUp;
    case 'due':
      return CareOccurrenceStatus.due;
    case 'overdue':
      return CareOccurrenceStatus.overdue;
    case 'not_recorded':
      return CareOccurrenceStatus.notRecorded;
    case 'done':
      return CareOccurrenceStatus.done;
    case 'skipped':
      return CareOccurrenceStatus.skipped;
    default:
      return CareOccurrenceStatus.unknown;
  }
}

/// Where an open date came from: the Fixed-schedule series, the After-it's-done
/// rule, or a person.
enum CareOccurrenceOrigin { schedule, computed, planned }

CareOccurrenceOrigin careOccurrenceOriginFromApi(String? value) {
  switch (value) {
    case 'schedule':
      return CareOccurrenceOrigin.schedule;
    case 'planned':
      return CareOccurrenceOrigin.planned;
    case 'computed':
    default:
      return CareOccurrenceOrigin.computed;
  }
}

/// Minutes since midnight for `HH:mm`, or null when absent or malformed.
int? clockMinutes(String? hhmm) {
  if (hhmm == null || hhmm.length < 5) return null;
  final hour = int.tryParse(hhmm.substring(0, 2));
  final minute = int.tryParse(hhmm.substring(3, 5));
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

/// The pet-home clock the server used for a response.
class CareAsOf {
  const CareAsOf({
    required this.date,
    required this.time,
    required this.timezone,
  });

  /// Calendar day (local midnight).
  final DateTime date;

  /// `HH:mm`.
  final String time;

  final String timezone;

  int get minutes => clockMinutes(time) ?? 0;
}

/// One open occurrence of a care item.
class OpenOccurrence implements Comparable<OpenOccurrence> {
  const OpenOccurrence({
    required this.id,
    required this.date,
    required this.status,
    required this.origin,
    this.time,
  });

  final String id;

  /// Calendar day (local midnight).
  final DateTime date;

  /// `HH:mm`, or null for a date without a time.
  final String? time;

  final CareOccurrenceStatus status;
  final CareOccurrenceOrigin origin;

  /// Date, then time (a date without a time sorts first on its day).
  @override
  int compareTo(OpenOccurrence other) {
    final byDate = date.compareTo(other.date);
    if (byDate != 0) return byDate;
    return (clockMinutes(time) ?? -1).compareTo(clockMinutes(other.time) ?? -1);
  }
}

/// Display-only "Estimated next" for an overdue After-it's-done item.
class EstimatedNext {
  const EstimatedNext({required this.date, required this.basis});

  final DateTime date;
  final String basis;
}
