import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_care/domain/care_temporal_group.dart';
import 'package:pet_profile_app/features/pet_care/domain/services/care_temporal_grouping_service.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_status.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_status_service.dart';

HealthEntry _entry({
  required String id,
  required String petId,
  required DateTime nextDue,
  int remindDaysBefore = 2,
  String status = 'active',
  HealthFrequency frequency = HealthFrequency.daily,
}) {
  return HealthEntry(
    id: id,
    petId: petId,
    name: id,
    type: HealthEntryType.other,
    frequency: frequency,
    startDate: nextDue.subtract(const Duration(days: 1)),
    nextDueDate: nextDue,
    remindDaysBefore: remindDaysBefore,
    status: status,
  );
}

void main() {
  const grouping = CareTemporalGroupingService();
  const careStatus = CareStatusService();
  const petId = 'pet-1';
  final now = DateTime(2030, 5, 10, 14);

  test('classifies overdue, today, upcoming, and outside horizon', () {
    final overdue = _entry(id: 'overdue', petId: petId, nextDue: DateTime(2030, 5, 7));
    final today = _entry(id: 'today', petId: petId, nextDue: DateTime(2030, 5, 10));
    final upcoming = _entry(
      id: 'upcoming',
      petId: petId,
      nextDue: DateTime(2030, 5, 11),
      remindDaysBefore: 2,
    );
    final outside = _entry(
      id: 'outside',
      petId: petId,
      nextDue: DateTime(2030, 5, 20),
      remindDaysBefore: 2,
    );

    expect(grouping.groupForEntry(overdue, now), CareTemporalGroup.needsAttention);
    expect(grouping.groupForEntry(today, now), CareTemporalGroup.today);
    expect(grouping.groupForEntry(upcoming, now), CareTemporalGroup.upcoming);
    expect(grouping.groupForEntry(outside, now), isNull);
  });

  test('completed entry leaves all buckets immediately', () {
    final entry = _entry(
      id: 'done',
      petId: petId,
      nextDue: DateTime(2030, 5, 10),
      status: 'completed',
    );

    expect(grouping.groupForEntry(entry, now), isNull);
    expect(
      grouping.bucketsForEntries([entry], petId: petId, now: now).isEmpty,
      isTrue,
    );
  });

  test('buckets sort by due date within each group', () {
    final entries = [
      _entry(id: 'overdue-later', petId: petId, nextDue: DateTime(2030, 5, 9)),
      _entry(id: 'overdue-earlier', petId: petId, nextDue: DateTime(2030, 5, 7)),
      _entry(id: 'today', petId: petId, nextDue: DateTime(2030, 5, 10)),
    ];

    final buckets = grouping.bucketsForEntries(entries, petId: petId, now: now);
    expect(buckets.needsAttention.map((e) => e.id), [
      'overdue-earlier',
      'overdue-later',
    ]);
    expect(buckets.today.single.id, 'today');
  });

  test('care status summary matches bucket precedence', () {
    final entries = [
      _entry(id: 'upcoming', petId: petId, nextDue: DateTime(2030, 5, 11)),
      _entry(id: 'overdue', petId: petId, nextDue: DateTime(2030, 5, 7)),
    ];

    final summary = careStatus.evaluate(
      petId: petId,
      entries: entries,
      now: now,
    );

    expect(summary.status, CareStatus.timeToFollowUp);
    expect(summary.contributingEntryIds, ['overdue']);
  });
}
