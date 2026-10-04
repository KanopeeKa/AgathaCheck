import 'care_item_schedule.dart';
import 'care_occurrence.dart';

/// Whether an open occurrence has started at [asOf] (D-CIE-034).
///
/// Overdue and not recorded have started. Due has started once its time is
/// reached; a date without a time has started from the beginning of its day.
/// Coming up never has.
bool occurrenceHasStarted(OpenOccurrence occurrence, CareAsOf asOf) {
  switch (occurrence.status) {
    case CareOccurrenceStatus.overdue:
    case CareOccurrenceStatus.notRecorded:
      return true;
    case CareOccurrenceStatus.due:
      final at = clockMinutes(occurrence.time);
      return at == null || at <= asOf.minutes;
    case CareOccurrenceStatus.comingUp:
    case CareOccurrenceStatus.done:
    case CareOccurrenceStatus.skipped:
    case CareOccurrenceStatus.unknown:
      return false;
  }
}

/// Open occurrences that have started, earliest first.
List<OpenOccurrence> startedOccurrences(
  CareItemSchedule schedule, {
  CareAsOf? asOf,
}) {
  final clock = asOf ?? schedule.asOf;
  return schedule.openOccurrences
      .where((o) => occurrenceHasStarted(o, clock))
      .toList(growable: false);
}

/// A stack: two or more started open slots of one Fixed-schedule item
/// (D-CIE-034). Done on a stack opens the Care Item view (DN-1).
bool isStack(CareItemSchedule schedule, {CareAsOf? asOf}) {
  if (!schedule.isFixedSchedule) return false;
  return startedOccurrences(schedule, asOf: asOf).length >= 2;
}
