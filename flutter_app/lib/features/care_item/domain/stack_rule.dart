import 'care_item_schedule.dart';
import 'care_occurrence.dart';
import 'occurrence_status.dart';

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

/// Attention vs upcoming groups for the Care Item Needs attention module.
class OpenOccurrenceGroups {
  const OpenOccurrenceGroups({
    required this.started,
    required this.upcoming,
  });

  final List<OpenOccurrence> started;
  final List<OpenOccurrence> upcoming;
}

/// Splits [schedule.openOccurrences] by [occurrenceHasStarted] (care-item-bulk-scope-spec §4).
OpenOccurrenceGroups partitionOpenOccurrences(
  CareItemSchedule schedule, {
  CareAsOf? asOf,
}) {
  final clock = asOf ?? schedule.asOf;
  final started = <OpenOccurrence>[];
  final upcoming = <OpenOccurrence>[];
  for (final o in schedule.openOccurrences) {
    if (occurrenceHasStarted(o, clock)) {
      started.add(o);
    } else {
      upcoming.add(o);
    }
  }
  return OpenOccurrenceGroups(started: started, upcoming: upcoming);
}

/// Upcoming row on the same calendar day as [asOf] whose time has not passed.
bool isLaterTodayUpcoming(OpenOccurrence occurrence, CareAsOf asOf) {
  if (occurrenceHasStarted(occurrence, asOf)) return false;
  if (occurrence.date != asOf.date) return false;
  return liveStatus(occurrence, asOf) == CareOccurrenceStatus.due;
}
