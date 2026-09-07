import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_status.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_status_service.dart';

HealthEntry _entry({
  required String id,
  required String petId,
  required DateTime nextDue,
  int remindDaysBefore = 1,
}) {
  return HealthEntry(
    id: id,
    petId: petId,
    name: 'Test',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.monthly,
    startDate: nextDue,
    nextDueDate: nextDue,
    remindDaysBefore: remindDaysBefore,
  );
}

void main() {
  const service = CareStatusService();
  const petId = 'pet-1';
  final now = DateTime(2026, 9, 7);

  test('no entries returns All Set', () {
    final summary = service.evaluate(petId: petId, entries: [], now: now);
    expect(summary.status, CareStatus.allSet);
    expect(summary.contributingEntryIds, isEmpty);
  });

  test('overdue entry returns Time to Follow Up', () {
    final summary = service.evaluate(
      petId: petId,
      entries: [
        _entry(id: 'e1', petId: petId, nextDue: DateTime(2026, 9, 1)),
      ],
      now: now,
    );
    expect(summary.status, CareStatus.timeToFollowUp);
    expect(summary.primaryCareEntryId, 'e1');
  });

  test('due today returns Worth a Check', () {
    final summary = service.evaluate(
      petId: petId,
      entries: [
        _entry(id: 'e1', petId: petId, nextDue: DateTime(2026, 9, 7)),
      ],
      now: now,
    );
    expect(summary.status, CareStatus.worthACheck);
  });

  test('upcoming within remind window returns Worth a Check', () {
    final summary = service.evaluate(
      petId: petId,
      entries: [
        _entry(
          id: 'e1',
          petId: petId,
          nextDue: DateTime(2026, 9, 9),
          remindDaysBefore: 3,
        ),
      ],
      now: now,
    );
    expect(summary.status, CareStatus.worthACheck);
  });

  test('future entry outside window returns All Set', () {
    final summary = service.evaluate(
      petId: petId,
      entries: [
        _entry(
          id: 'e1',
          petId: petId,
          nextDue: DateTime(2026, 10, 1),
          remindDaysBefore: 1,
        ),
      ],
      now: now,
    );
    expect(summary.status, CareStatus.allSet);
  });

  test('overdue wins over upcoming for same pet', () {
    final summary = service.evaluate(
      petId: petId,
      entries: [
        _entry(id: 'e1', petId: petId, nextDue: DateTime(2026, 9, 9)),
        _entry(id: 'e2', petId: petId, nextDue: DateTime(2026, 9, 1)),
      ],
      now: now,
    );
    expect(summary.status, CareStatus.timeToFollowUp);
    expect(summary.contributingEntryIds, contains('e2'));
  });
}
