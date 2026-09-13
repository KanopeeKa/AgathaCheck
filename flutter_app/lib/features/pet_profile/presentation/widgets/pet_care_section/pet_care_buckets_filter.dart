import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../pet_care/domain/models/care_temporal_buckets.dart';

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
