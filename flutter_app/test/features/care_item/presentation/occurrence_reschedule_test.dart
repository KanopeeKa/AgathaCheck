import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/domain/care_occurrence.dart';
import 'package:pet_profile_app/features/care_item/domain/occurrence_detail.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_reschedule.dart';

void main() {
  test('occurrenceShowsReschedule is false when closed not recorded', () {
    final detail = _detail(
      status: CareOccurrenceStatus.notRecorded,
      isOpen: false,
      closeReason: 'not_recorded',
    );
    expect(occurrenceShowsReschedule(detail), isFalse);
  });

  test('occurrenceShowsReschedule is false when dose is done', () {
    final detail = _detail(status: CareOccurrenceStatus.done, isOpen: false);
    expect(occurrenceShowsReschedule(detail), isFalse);
  });

  test('occurrenceShowsReschedule is true for open due dose', () {
    final detail = _detail(status: CareOccurrenceStatus.due, isOpen: true);
    expect(occurrenceShowsReschedule(detail), isTrue);
  });
}

OccurrenceDetail _detail({
  required CareOccurrenceStatus status,
  required bool isOpen,
  String? closeReason,
}) {
  return OccurrenceDetail(
    item: CareItemSummary(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Meds',
      isFixedSchedule: true,
      status: 'active',
      asOf: CareAsOf(
        date: DateTime(2026, 10, 6),
        time: '09:00',
        timezone: 'UTC',
      ),
    ),
    occurrence: CareOccurrence(
      id: 'occ-1',
      date: DateTime(2026, 10, 6),
      time: '08:00',
      status: status,
      origin: CareOccurrenceOrigin.schedule,
      isOpen: isOpen,
      closeReason: closeReason,
    ),
  );
}
