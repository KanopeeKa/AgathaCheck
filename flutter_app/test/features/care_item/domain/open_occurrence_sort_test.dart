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
}
