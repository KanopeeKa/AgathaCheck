import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_care/domain/care_temporal_group.dart';
import 'package:pet_profile_app/features/pet_care/domain/services/care_temporal_grouping_service.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_status_service.dart';

HealthEntry _entry(String id, String petId, DateTime dueDate) => HealthEntry(
  id: id,
  petId: petId,
  name: id,
  type: HealthEntryType.other,
  frequency: HealthFrequency.daily,
  startDate: dueDate.subtract(const Duration(days: 1)),
  nextDueDate: dueDate,
  remindDaysBefore: 2,
);

void main() {
  const grouping = CareTemporalGroupingService();
  const careStatus = CareStatusService();
  final now = DateTime(2030, 5, 10, 14);
  const pet = Pet(id: 'pet-1', name: 'Buddy', species: 'Dog', breed: '');
  final entries = [
    _entry('overdue-earlier', pet.id, DateTime(2030, 5, 7)),
    _entry('overdue-later', pet.id, DateTime(2030, 5, 9)),
    _entry('today', pet.id, DateTime(2030, 5, 10)),
    _entry('upcoming-soon', pet.id, DateTime(2030, 5, 11)),
    _entry('upcoming-later', pet.id, DateTime(2030, 5, 12)),
    _entry('outside-window', pet.id, DateTime(2030, 5, 20)),
  ];

  CareTemporalGroup? profileGroupFor(String entryId) {
    final entry = entries.firstWhere((e) => e.id == entryId);
    return grouping.groupForEntry(entry, now);
  }

  CareTemporalGroup? dashboardGroupFor(String entryId) {
    final priorities = PetCareTodayCarePriorities.forPets(
      entries: entries,
      pets: [pet],
      now: now,
      grouping: grouping,
    );
    if (priorities.overdue.any((e) => e.id == entryId)) {
      return CareTemporalGroup.needsAttention;
    }
    if (priorities.dueToday.any((e) => e.id == entryId)) {
      return CareTemporalGroup.today;
    }
    if (priorities.upcoming.any((e) => e.id == entryId)) {
      return CareTemporalGroup.upcoming;
    }
    return null;
  }

  CareTemporalGroup? allCareGroupFor(String entryId) {
    final buckets = grouping.bucketsForEntries(
      entries,
      petId: pet.id,
      now: now,
    );
    return buckets.groupForEntryId(entryId);
  }

  test('profile, dashboard, and All-care surfaces agree on temporal grouping', () {
    for (final entry in entries) {
      final profile = profileGroupFor(entry.id);
      final dashboard = dashboardGroupFor(entry.id);
      final allCare = allCareGroupFor(entry.id);

      expect(dashboard, profile, reason: 'dashboard vs profile for ${entry.id}');
      expect(allCare, profile, reason: 'all-care vs profile for ${entry.id}');
    }
  });

  test('profile care status matches dashboard flags from the same buckets', () {
    final buckets = grouping.bucketsForEntries(
      entries,
      petId: pet.id,
      now: now,
    );
    final summary = careStatus.evaluate(
      petId: pet.id,
      entries: entries,
      now: now,
    );
    final dashboardSummary = PetCareTodayCareSummary.forPets(
      entries: entries,
      pets: [pet],
      now: now,
    );

    expect(
      petCareStatusFor(pet, dashboardSummary, grouping: grouping),
      summary.status,
    );
    expect(summary.status, grouping.careStatusFromBuckets(buckets));
  });
}
