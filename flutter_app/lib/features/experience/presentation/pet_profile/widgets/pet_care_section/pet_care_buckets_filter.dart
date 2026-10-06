import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

/// Removes optimistically completed items from temporal buckets for display.
CareTemporalBuckets filterOptimisticallyCompletedBuckets(
  CareTemporalBuckets buckets,
  Set<String> completedEntryIds,
) {
  if (completedEntryIds.isEmpty) return buckets;

  List<HealthEntry> filter(List<HealthEntry> entries) =>
      entries.where((entry) => !completedEntryIds.contains(entry.id)).toList();

  return CareTemporalBuckets(
    needsAttention: filter(buckets.needsAttention),
    today: filter(buckets.today),
    upcoming: filter(buckets.upcoming),
  );
}
