/// All care list grouping: **Today** (no separate Due soon) and **Upcoming**.
library;

import 'care_agenda.dart';
import 'care_item_schedule.dart';
import 'care_occurrence.dart';
import 'occurrence_status.dart';
import 'stack_rule.dart';

class CareListPartition<T> {
  const CareListPartition({required this.today, required this.upcoming});

  final List<T> today;
  final List<T> upcoming;

  bool get isEmpty => today.isEmpty && upcoming.isEmpty;
}

/// Splits active planned items into Today and Upcoming (due soon merges into
/// Upcoming on global All care — CARE-ITEM-R-024).
CareListPartition<T> partitionCareList<T>(
  Iterable<T> items,
  CareItemSchedule? Function(T item) scheduleOf, {
  Duration elapsed = Duration.zero,
}) {
  final agenda = buildCareAgenda(items, scheduleOf, elapsed: elapsed);
  final today = <T>[];
  final seenToday = <String>{};

  void takeToday(Iterable<CareAgendaRow<T>> rows) {
    for (final row in rows) {
      if (seenToday.add(row.schedule.entryId)) {
        today.add(row.item);
      }
    }
  }

  takeToday(agenda.overdue);
  if (agenda.showTimeGroupHeadings) {
    for (final group in CareTimeGroup.values) {
      takeToday(agenda.today[group] ?? const []);
    }
  } else {
    takeToday(agenda.today.values.expand((rows) => rows));
  }
  takeToday(agenda.doneToday);

  final upcoming = <T>[];
  final seenUpcoming = <String>{};

  void takeUpcoming(Iterable<CareAgendaRow<T>> rows) {
    for (final row in rows) {
      if (seenUpcoming.add(row.schedule.entryId)) {
        upcoming.add(row.item);
      }
    }
  }

  takeUpcoming(agenda.dueSoon);
  takeUpcoming(agenda.upcoming);

  return CareListPartition(today: today, upcoming: upcoming);
}

/// One open slot line on a Today card.
class CareListSlotLine {
  const CareListSlotLine({required this.occurrence, required this.status});

  final OpenOccurrence occurrence;
  final CareOccurrenceStatus status;
}

/// Structural content for a multi-line Today card (formatting stays in UI).
class CareListTodayContent {
  const CareListTodayContent({
    required this.isStack,
    required this.stackCount,
    required this.openLines,
    required this.quietDone,
    required this.showMarkDone,
  });

  final bool isStack;
  final int stackCount;
  final List<CareListSlotLine> openLines;
  final List<CompletionToday> quietDone;
  final bool showMarkDone;
}

CareListTodayContent buildCareListTodayContent(
  CareItemSchedule schedule, {
  Duration elapsed = Duration.zero,
}) {
  final now = liveAsOf(schedule.asOf, elapsed);
  final started = startedOccurrences(schedule, asOf: now);
  if (isStack(schedule, asOf: now)) {
    return CareListTodayContent(
      isStack: true,
      stackCount: started.length,
      openLines: const [],
      quietDone: schedule.completionsToday,
      showMarkDone: true,
    );
  }

  final groups = partitionOpenOccurrences(schedule, asOf: now);
  final openLines = <CareListSlotLine>[
    for (final occ in groups.started)
      CareListSlotLine(occurrence: occ, status: liveStatus(occ, now)),
    for (final occ in groups.upcoming)
      if (occ.date == now.date)
        CareListSlotLine(occurrence: occ, status: liveStatus(occ, now)),
  ];

  openLines.sort((a, b) {
    final aStarted = occurrenceHasStarted(a.occurrence, now);
    final bStarted = occurrenceHasStarted(b.occurrence, now);
    if (aStarted != bStarted) return aStarted ? -1 : 1;
    final ctx = aStarted
        ? OpenOccurrenceListContext.started
        : OpenOccurrenceListContext.upcoming;
    return compareOpenOccurrencesClosestToPresent(
      a.occurrence,
      b.occurrence,
      ctx,
    );
  });

  final hasOpen = openLines.isNotEmpty;
  return CareListTodayContent(
    isStack: false,
    stackCount: 0,
    openLines: openLines,
    quietDone: schedule.completionsToday,
    showMarkDone: hasOpen,
  );
}

/// Leading agenda row for an Upcoming card (due soon + later dates).
CareAgendaRow<T>? careListUpcomingRow<T>(
  T item,
  CareItemSchedule schedule, {
  Duration elapsed = Duration.zero,
}) {
  final agenda = buildCareAgenda([item], (_) => schedule, elapsed: elapsed);
  if (agenda.dueSoon.isNotEmpty) return agenda.dueSoon.first;
  if (agenda.upcoming.isNotEmpty) return agenda.upcoming.first;
  return null;
}
