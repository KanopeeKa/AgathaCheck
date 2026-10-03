import 'care_item_schedule.dart';
import 'care_occurrence.dart';
import 'stack_rule.dart';

/// The occurrence a row represents (§18.5): the most urgent started one
/// (overdue, not recorded, due), otherwise the next one to come.
///
/// Started occurrences are ordered earliest first, so the earliest started
/// one is the most urgent.
OpenOccurrence? leadingOccurrence(CareItemSchedule schedule, {CareAsOf? asOf}) {
  if (schedule.openOccurrences.isEmpty) return null;
  final started = startedOccurrences(schedule, asOf: asOf);
  if (started.isNotEmpty) return started.first;
  return schedule.openOccurrences.first;
}

/// After it's done: an earlier open date than [occurrence] (DN-1c). Done on
/// the later one opens the Care Item view instead of completing.
bool hasEarlierOpenDate(CareItemSchedule schedule, OpenOccurrence occurrence) {
  if (schedule.isFixedSchedule) return false;
  return schedule.openOccurrences.any((o) => o.compareTo(occurrence) < 0);
}
