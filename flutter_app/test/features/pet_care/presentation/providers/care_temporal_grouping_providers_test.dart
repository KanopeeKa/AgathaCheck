import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_care/domain/care_temporal_group.dart';
import 'package:pet_profile_app/features/pet_care/domain/services/care_temporal_grouping_service.dart';
import 'package:pet_profile_app/features/pet_care/presentation/providers/care_temporal_grouping_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_status.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_status_service.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);
  final List<HealthEntry> _entries;
  @override
  Future<List<HealthEntry>> build() async => _entries;
}

HealthEntry _entry({
  required String id,
  required String petId,
  required DateTime nextDue,
  int remindDaysBefore = 3,
}) {
  return HealthEntry(
    id: id,
    petId: petId,
    name: id,
    type: HealthEntryType.medication,
    frequency: HealthFrequency.daily,
    startDate: nextDue.subtract(const Duration(days: 1)),
    nextDueDate: nextDue,
    remindDaysBefore: remindDaysBefore,
  );
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

List<HealthEntry> _entries() {
  final today = _today();
  return [
    _entry(
      id: 'overdue-earlier',
      petId: 'pet-1',
      nextDue: today.subtract(const Duration(days: 2)),
    ),
    _entry(
      id: 'overdue-later',
      petId: 'pet-1',
      nextDue: today.subtract(const Duration(days: 1)),
    ),
    _entry(id: 'today', petId: 'pet-1', nextDue: today),
    _entry(
      id: 'upcoming',
      petId: 'pet-1',
      nextDue: today.add(const Duration(days: 1)),
    ),
    _entry(
      id: 'outside-window',
      petId: 'pet-1',
      nextDue: today.add(const Duration(days: 30)),
    ),
    _entry(
      id: 'other-pet-overdue',
      petId: 'pet-2',
      nextDue: today.subtract(const Duration(days: 1)),
    ),
  ];
}

ProviderContainer _container(List<HealthEntry> entries) {
  final container = ProviderContainer(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(
        () => _FakeHealthEntriesNotifier(entries),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _warmUp(ProviderContainer container) async {
  await container.read(healthEntriesNotifierProvider.future);
}

void main() {
  const grouping = CareTemporalGroupingService();
  const careStatus = CareStatusService();

  test('petCareTemporalBucketsProvider agrees with the service', () async {
    final entries = _entries();
    final container = _container(entries);
    await _warmUp(container);

    final buckets = container.read(petCareTemporalBucketsProvider('pet-1'));
    final serviceBuckets = grouping.bucketsForEntries(
      entries,
      petId: 'pet-1',
      now: DateTime.now(),
    );

    for (final group in CareTemporalGroup.values) {
      expect(
        buckets.entriesIn(group).map((entry) => entry.id).toList(),
        serviceBuckets.entriesIn(group).map((entry) => entry.id).toList(),
        reason: 'provider agrees on $group',
      );
    }
    expect(
      buckets.groupForEntryId('other-pet-overdue'),
      isNull,
      reason: 'pet-scoped provider excludes other pets',
    );
  });

  test('dashboardCareTemporalBucketsProvider spans all pets', () async {
    final entries = _entries();
    final container = _container(entries);
    await _warmUp(container);

    final buckets = container.read(dashboardCareTemporalBucketsProvider);
    final serviceBuckets = grouping.bucketsForEntries(
      entries,
      now: DateTime.now(),
    );

    for (final group in CareTemporalGroup.values) {
      expect(
        buckets.entriesIn(group).map((entry) => entry.id).toList(),
        serviceBuckets.entriesIn(group).map((entry) => entry.id).toList(),
        reason: 'dashboard provider agrees on $group',
      );
    }
    expect(
      buckets.groupForEntryId('other-pet-overdue'),
      CareTemporalGroup.needsAttention,
      reason: 'dashboard provider includes other pets',
    );
  });

  test('petCareStatusFromGroupingProvider matches the service', () async {
    final entries = _entries();
    final container = _container(entries);
    await _warmUp(container);

    final summary = container.read(petCareStatusFromGroupingProvider('pet-1'));
    final serviceSummary = grouping.summarizePet(
      petId: 'pet-1',
      entries: entries,
      now: DateTime.now(),
    );
    final evaluated = careStatus.evaluate(
      petId: 'pet-1',
      entries: entries,
      now: DateTime.now(),
    );

    expect(summary.status, serviceSummary.status);
    expect(summary.primaryCareEntryId, serviceSummary.primaryCareEntryId);
    expect(summary.contributingEntryIds, serviceSummary.contributingEntryIds);
    expect(summary.status, evaluated.status);
    expect(
      summary.status,
      CareStatus.timeToFollowUp,
      reason: 'needs-attention entries dominate the status',
    );
  });

  test('petCareStatusFromGroupingProvider is allSet when empty', () async {
    final container = _container(const []);
    await _warmUp(container);

    final buckets = container.read(petCareTemporalBucketsProvider('pet-1'));
    final summary = container.read(petCareStatusFromGroupingProvider('pet-1'));

    expect(buckets.isEmpty, isTrue);
    expect(summary.status, CareStatus.allSet);
    expect(summary.primaryCareEntryId, isNull);
    expect(summary.contributingEntryIds, isEmpty);
  });
}
