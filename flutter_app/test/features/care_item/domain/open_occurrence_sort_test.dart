import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/domain/care_occurrence.dart';

void main() {
  test('openOccurrencesNewestFirst sorts latest date and time first', () {
    final items = [
      OpenOccurrence(
        id: 'old',
        date: DateTime(2026, 10, 3),
        time: '09:00',
        status: CareOccurrenceStatus.notRecorded,
        origin: CareOccurrenceOrigin.schedule,
      ),
      OpenOccurrence(
        id: 'new',
        date: DateTime(2026, 10, 6),
        time: '09:00',
        status: CareOccurrenceStatus.overdue,
        origin: CareOccurrenceOrigin.schedule,
      ),
      OpenOccurrence(
        id: 'same-day-later',
        date: DateTime(2026, 10, 5),
        time: '20:00',
        status: CareOccurrenceStatus.overdue,
        origin: CareOccurrenceOrigin.schedule,
      ),
      OpenOccurrence(
        id: 'same-day-earlier',
        date: DateTime(2026, 10, 5),
        time: '08:00',
        status: CareOccurrenceStatus.overdue,
        origin: CareOccurrenceOrigin.schedule,
      ),
    ];

    final sorted = openOccurrencesNewestFirst(items);
    expect(sorted.map((o) => o.id), [
      'new',
      'same-day-later',
      'same-day-earlier',
      'old',
    ]);
  });

  test('sortUpcomingOpenOccurrences sorts earliest date and time first', () {
    final items = [
      OpenOccurrence(
        id: 'far',
        date: DateTime(2026, 10, 16),
        time: '20:00',
        status: CareOccurrenceStatus.comingUp,
        origin: CareOccurrenceOrigin.schedule,
      ),
      OpenOccurrence(
        id: 'soon',
        date: DateTime(2026, 10, 9),
        time: '20:00',
        status: CareOccurrenceStatus.due,
        origin: CareOccurrenceOrigin.schedule,
      ),
      OpenOccurrence(
        id: 'mid',
        date: DateTime(2026, 10, 16),
        time: '08:00',
        status: CareOccurrenceStatus.comingUp,
        origin: CareOccurrenceOrigin.schedule,
      ),
    ];

    final sorted = sortUpcomingOpenOccurrences(items);
    expect(sorted.map((o) => o.id), ['soon', 'mid', 'far']);
  });
}
