import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';

import 'care_item_test_data.dart';

class _PetRef {
  const _PetRef(this.id);
  final String id;
}

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
  test('overdue rows sort closest to present first', () {
    final a = agenda([
      item('Older', [occ('o', 5, CareOccurrenceStatus.overdue)], fixed: false),
      item('Recent', [occ('r', 8, CareOccurrenceStatus.overdue)], fixed: false),
    ]);
    expect(names(a.overdue), ['Recent', 'Older']);
  });

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

  test('AG-1 only anytime items → one group, no sub-headings', () {
    final a = agenda([
      item('A', [occ('a', 10, CareOccurrenceStatus.due)]),
      item('B', [occ('b', 10, CareOccurrenceStatus.due)]),
    ]);
    expect(a.showTimeGroupHeadings, isFalse);
    expect(a.today.keys, [CareTimeGroup.anytime]);
  });

  test('AG-2 morning and anytime → two headings', () {
    final a = agenda([
      item('Morning pill', [
        occ('m', 10, CareOccurrenceStatus.due, time: '11:00'),
      ]),
      item('Brush', [occ('b', 10, CareOccurrenceStatus.due)]),
    ]);
    expect(a.showTimeGroupHeadings, isTrue);
    expect(a.today.keys, [CareTimeGroup.morning, CareTimeGroup.anytime]);
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

  test('AG-9 yearly vaccine 200 days away is Upcoming', () {
    final a = agenda([
      item('Rabies', [occ('r', 28, CareOccurrenceStatus.comingUp, month: 12)]),
    ]);
    expect(names(a.upcoming), ['Rabies']);
    expect(a.dueSoon, isEmpty);
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

  test(
    'AG-4 daily med done today stays in Today, not Due soon or Upcoming',
    () {
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
      expect(a.dueSoon, isEmpty);
      expect(a.upcoming, isEmpty);
    },
  );

  test('AG-5 weekly due in 3 days is Due soon; 20 days is Upcoming', () {
    final a = agenda([
      item('Soon', [occ('s', 13, CareOccurrenceStatus.comingUp)], fixed: false),
      item('Later', [
        occ('l', 30, CareOccurrenceStatus.comingUp),
      ], fixed: false),
    ]);
    expect(names(a.dueSoon), ['Soon']);
    expect(names(a.upcoming), ['Later']);
  });

  test('AG-6 every-3-days due tomorrow is Due soon', () {
    final a = agenda([
      item('Rhythm', [
        occ('r', 11, CareOccurrenceStatus.comingUp),
      ], fixed: false),
    ]);
    expect(names(a.dueSoon), ['Rhythm']);
    expect(a.upcoming, isEmpty);
  });

  test('AG-10 no overdue or due today still lists Due soon and Upcoming', () {
    final a = agenda([
      item('Groom', [
        occ('g', 15, CareOccurrenceStatus.comingUp),
      ], fixed: false),
      item('Yearly', [
        occ('y', 40, CareOccurrenceStatus.comingUp, month: 7),
      ], fixed: false),
    ]);
    expect(a.overdue, isEmpty);
    expect(a.today, isEmpty);
    expect(names(a.dueSoon), ['Groom']);
    expect(names(a.upcoming), ['Yearly']);
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

  test('coordination banner when two pets share a due day', () {
    CareAgendaRow<_PetRef> row(String petId, String name, int day) {
      final schedule = item(name, [
        occ(name, day, CareOccurrenceStatus.comingUp),
      ]);
      final leading = leadingOccurrence(schedule);
      return CareAgendaRow(
        item: _PetRef(petId),
        schedule: schedule,
        section: CareAgendaSection.dueSoon,
        occurrence: leading,
        status: liveStatus(leading!, schedule.asOf),
      );
    }

    final groups = groupAgendaRowsByDueDate([
      row('pet-a', 'Alpha', 13),
      row('pet-b', 'Beta', 13),
    ]);
    expect(showCoordinationBanner(groups.single, (p) => p.id), isTrue);
    expect(coordinationPetIds(groups.single, (p) => p.id), ['pet-a', 'pet-b']);
  });

  test('due soon groups share a same-day date header when two items match', () {
    final rows = agenda([
      item('Alpha', [occ('a', 13, CareOccurrenceStatus.comingUp)]),
      item('Beta', [occ('b', 13, CareOccurrenceStatus.comingUp)]),
      item('Gamma', [occ('g', 15, CareOccurrenceStatus.comingUp)]),
    ]).dueSoon;
    final groups = groupAgendaRowsByDueDate(rows);
    expect(groups.length, 2);
    expect(groups.first.rows.length, 2);
    expect(showSameDayDateHeader(groups.first), isTrue);
    expect(showSameDayDateHeader(groups.last), isFalse);
  });
}
