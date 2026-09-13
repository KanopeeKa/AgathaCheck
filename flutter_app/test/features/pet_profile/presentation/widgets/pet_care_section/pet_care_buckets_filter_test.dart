import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_care/domain/models/care_temporal_buckets.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_care_section/pet_care_buckets_filter.dart';

HealthEntry _entry(String id) {
  return HealthEntry(
    id: id,
    petId: 'pet-1',
    name: id,
    type: HealthEntryType.other,
    frequency: HealthFrequency.once,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 1, 2),
  );
}

void main() {
  test('filterOptimisticallyCompletedBuckets removes completed ids', () {
    final buckets = CareTemporalBuckets(
      needsAttention: [_entry('a')],
      today: [_entry('b'), _entry('c')],
      upcoming: [_entry('d')],
    );

    final filtered = filterOptimisticallyCompletedBuckets(buckets, {'b', 'd'});

    expect(filtered.needsAttention.map((e) => e.id), ['a']);
    expect(filtered.today.map((e) => e.id), ['c']);
    expect(filtered.upcoming, isEmpty);
  });
}
