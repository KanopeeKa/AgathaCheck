import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';

import 'care_item_test_data.dart';

CareItemSchedule item(
  String name,
  List<OpenOccurrence> open, {
  CareAsOf? at,
  bool fixed = true,
  bool daily = false,
  String status = 'active',
  LastDone? lastDone,
}) => CareItemSchedule(
  entryId: name,
  petId: 'pet-1',
  name: name,
  isFixedSchedule: fixed,
  status: status,
  openOccurrences: open,
  asOf: at ?? asOf(10, '10:00'),
  repeatsDailyOrMore: daily,
  lastDone: lastDone,
);

CareAgenda<CareItemSchedule> agenda(
  List<CareItemSchedule> items, {
  Duration elapsed = Duration.zero,
}) => buildCareAgenda(items, (s) => s, elapsed: elapsed);

List<String> names(List<CareAgendaRow<CareItemSchedule>> rows) =>
    rows.map((r) => r.schedule.name).toList();

void main() {
  test('AG overdue first, then today by time group, due soon, upcoming', () {
    final a = agenda([
      item('Flea', [occ('f', 5, CareOccurrenceStatus.overdue)], fixed: false),
      item('Morning pill', [
        occ('m', 10, CareOccurrenceStatus.due, time: '11:00'),
      ]),
      item('Evening pill', [
        occ('e', 10, CareOccurrenceStatus.due, time: '19:00'),
      ]),
      item('Brush', [occ('b', 10, CareOccurrenceStatus.due)]),
      item('Groom', [occ('g', 15, CareOccurrenceStatus.comingUp)]),
      item('Vaccine', [occ('v', 1, CareOccurrenceStatus.comingUp, month: 9)]),
    ]);
    expect(names(a.overdue), ['Flea']);
    expect(a.today.keys, [
      CareTimeGroup.morning,
      CareTimeGroup.evening,
      CareTimeGroup.anytime,
    ]);
    expect(a.showTimeGroupHeadings, isTrue);
    expect(names(a.dueSoon), ['Groom']);
    expect(names(a.upcoming), ['Vaccine']);
    expect(a.overdueCount, 1);
    expect(a.dueTodayCount, 3);
  });

  test('one time group → one "Today\'s list" heading', () {
    final a = agenda([
      item('A', [occ('a', 10, CareOccurrenceStatus.due)]),
      item('B', [occ('b', 10, CareOccurrenceStatus.due)]),
    ]);
    expect(a.showTimeGroupHeadings, isFalse);
  });

  test('a stack is one overdue row with its count (DN-1b)', () {
    final a = agenda([
      item('Pill', [
        occ('y', 9, CareOccurrenceStatus.notRecorded),
        occ('t', 10, CareOccurrenceStatus.due),
      ]),
    ]);
    expect(a.overdue.single.isStack, isTrue);
    expect(a.overdue.single.stackCount, 2);
    expect(a.overdue.single.occurrence?.id, 'y');
    expect(a.today, isEmpty);
  });

  test('daily care appears only in Today', () {
    final a = agenda([
      item('Chew', [occ('c', 11, CareOccurrenceStatus.comingUp)], daily: true),
    ]);
    expect(a.isEmpty, isTrue);
  });

  test('the reminder window never hides care: 200 days away is Upcoming', () {
    final a = agenda([
      item('Rabies', [occ('r', 28, CareOccurrenceStatus.comingUp, month: 12)]),
    ]);
    expect(names(a.upcoming), ['Rabies']);
  });

  test('paused and ended items are left out', () {
    final a = agenda([
      item('P', [occ('p', 5, CareOccurrenceStatus.overdue)], status: 'paused'),
      item('E', [
        occ('e', 5, CareOccurrenceStatus.overdue),
      ], status: 'completed'),
    ]);
    expect(a.isEmpty, isTrue);
  });

  test('done today stays at the end of Today, quiet', () {
    final a = agenda([
      item(
        'Pill',
        [occ('n', 11, CareOccurrenceStatus.comingUp)],
        daily: true,
        lastDone: LastDone(
          occurrenceId: 'x',
          completedOn: DateTime(2026, 6, 10),
          time: '08:12',
        ),
      ),
    ]);
    expect(names(a.doneToday), ['Pill']);
    expect(a.doneToday.single.occurrence, isNull);
    expect(a.hasToday, isTrue);
  });

  test('a timed due turns overdue as minutes pass (D-CIE-028)', () {
    final pill = item('Pill', [
      occ('m', 10, CareOccurrenceStatus.due, time: '10:30'),
    ], at: asOf(10, '10:00'));
    expect(agenda([pill]).today.isNotEmpty, isTrue);
    final later = agenda([pill], elapsed: const Duration(minutes: 45));
    expect(names(later.overdue), ['Pill']);
    expect(later.overdue.single.status, CareOccurrenceStatus.overdue);
  });

  test('liveAsOf stays on the same day', () {
    final at = liveAsOf(asOf(10, '23:30'), const Duration(hours: 2));
    expect(at.time, '23:59');
    expect(at.date, DateTime(2026, 6, 10));
  });

  test('time groups split at 12:00 and 18:00', () {
    expect(timeGroupFor('11:59'), CareTimeGroup.morning);
    expect(timeGroupFor('12:00'), CareTimeGroup.afternoon);
    expect(timeGroupFor('18:00'), CareTimeGroup.evening);
    expect(timeGroupFor(null), CareTimeGroup.anytime);
  });
}
