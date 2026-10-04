/// The agenda (D-CIE-025): one rule for the dashboard, the pet profile and
/// All care. Generic over the caller's item type so this module imports no
/// other feature.
library;

import 'care_item_schedule.dart';
import 'care_occurrence.dart';
import 'leading_occurrence.dart';
import 'occurrence_status.dart';
import 'stack_rule.dart';

enum CareAgendaSection { overdue, today, doneToday, dueSoon, upcoming }

/// Today's time groups, in each pet's local time (UIR-16).
enum CareTimeGroup { morning, afternoon, evening, anytime }

CareTimeGroup timeGroupFor(String? time) {
  final minutes = clockMinutes(time);
  if (minutes == null) return CareTimeGroup.anytime;
  if (minutes < 12 * 60) return CareTimeGroup.morning;
  if (minutes < 18 * 60) return CareTimeGroup.afternoon;
  return CareTimeGroup.evening;
}

/// Due soon = the next seven days after today.
const kDueSoonDays = 7;

class CareAgendaRow<T> {
  const CareAgendaRow({
    required this.item,
    required this.schedule,
    required this.section,
    this.occurrence,
    this.status,
    this.stackCount = 0,
    this.timeGroup,
  });

  final T item;
  final CareItemSchedule schedule;
  final CareAgendaSection section;

  /// The leading occurrence (§18.5); null for a done-today row.
  final OpenOccurrence? occurrence;

  /// Live status of [occurrence].
  final CareOccurrenceStatus? status;

  /// Started slots when this row is a stack (D-CIE-034), else 0.
  final int stackCount;

  final CareTimeGroup? timeGroup;

  bool get isStack => stackCount >= 2;
}

class CareAgenda<T> {
  const CareAgenda({
    this.overdue = const [],
    this.today = const {},
    this.doneToday = const [],
    this.dueSoon = const [],
    this.upcoming = const [],
  });

  /// Overdue and not recorded, stacks included; earliest first.
  final List<CareAgendaRow<T>> overdue;

  /// Due today by time group (only non-empty groups).
  final Map<CareTimeGroup, List<CareAgendaRow<T>>> today;

  /// Done today, quiet, at the end of Today.
  final List<CareAgendaRow<T>> doneToday;

  final List<CareAgendaRow<T>> dueSoon;

  /// Later dates (collapsed on screen).
  final List<CareAgendaRow<T>> upcoming;

  int get overdueCount => overdue.length;
  int get dueTodayCount => today.values.fold(0, (n, rows) => n + rows.length);

  /// Group headings show only when two or more groups have care; otherwise
  /// one "Today's list" heading.
  bool get showTimeGroupHeadings => today.length >= 2;

  bool get hasToday =>
      overdue.isNotEmpty || today.isNotEmpty || doneToday.isNotEmpty;

  bool get isEmpty => !hasToday && dueSoon.isEmpty && upcoming.isEmpty;

  /// Every row, in screen order.
  List<CareAgendaRow<T>> get rows => [
    ...overdue,
    for (final group in CareTimeGroup.values) ...?today[group],
    ...doneToday,
    ...dueSoon,
    ...upcoming,
  ];
}

/// Build the agenda for [items]. Items without a schedule, paused or ended
/// items are left out (INV-4). [elapsed] advances each read's clock (live
/// status between reads).
CareAgenda<T> buildCareAgenda<T>(
  Iterable<T> items,
  CareItemSchedule? Function(T item) scheduleOf, {
  Duration elapsed = Duration.zero,
}) {
  final overdue = <CareAgendaRow<T>>[];
  final today = <CareTimeGroup, List<CareAgendaRow<T>>>{};
  final doneToday = <CareAgendaRow<T>>[];
  final dueSoon = <CareAgendaRow<T>>[];
  final upcoming = <CareAgendaRow<T>>[];

  for (final item in items) {
    final schedule = scheduleOf(item);
    if (schedule == null || !schedule.isActive) continue;
    final now = liveAsOf(schedule.asOf, elapsed);

    if (schedule.doneToday) {
      doneToday.add(
        CareAgendaRow(
          item: item,
          schedule: schedule,
          section: CareAgendaSection.doneToday,
        ),
      );
    }

    final leading = leadingOccurrence(schedule, asOf: now);
    if (leading == null) continue;
    final status = liveStatus(leading, now);
    final started = isStack(schedule, asOf: now)
        ? startedOccurrences(schedule, asOf: now).length
        : 0;

    CareAgendaRow<T> row(CareAgendaSection section, {CareTimeGroup? group}) =>
        CareAgendaRow(
          item: item,
          schedule: schedule,
          section: section,
          occurrence: leading,
          status: status,
          stackCount: started,
          timeGroup: group,
        );

    if (started >= 2 || isPastDue(status)) {
      overdue.add(row(CareAgendaSection.overdue));
    } else if (leading.date == now.date) {
      final group = timeGroupFor(leading.time);
      today
          .putIfAbsent(group, () => [])
          .add(row(CareAgendaSection.today, group: group));
    } else if (!schedule.repeatsDailyOrMore) {
      final days = leading.date.difference(now.date).inDays;
      if (days <= kDueSoonDays) {
        dueSoon.add(row(CareAgendaSection.dueSoon));
      } else {
        upcoming.add(row(CareAgendaSection.upcoming));
      }
    }
  }

  int byOccurrence(CareAgendaRow<T> a, CareAgendaRow<T> b) {
    final c = a.occurrence!.compareTo(b.occurrence!);
    return c != 0 ? c : a.schedule.name.compareTo(b.schedule.name);
  }

  overdue.sort(byOccurrence);
  for (final rows in today.values) {
    rows.sort(byOccurrence);
  }
  dueSoon.sort(byOccurrence);
  upcoming.sort(byOccurrence);
  doneToday.sort(
    (a, b) => (a.schedule.lastDone?.time ?? '').compareTo(
      b.schedule.lastDone?.time ?? '',
    ),
  );

  return CareAgenda(
    overdue: overdue,
    today: {
      for (final group in CareTimeGroup.values)
        if (today[group] != null) group: today[group]!,
    },
    doneToday: doneToday,
    dueSoon: dueSoon,
    upcoming: upcoming,
  );
}
