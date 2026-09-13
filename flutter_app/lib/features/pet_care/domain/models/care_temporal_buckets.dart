import '../../../health_tracking/domain/entities/health_entry.dart';
import '../care_temporal_group.dart';

/// Grouped open care entries for one pet or a dashboard pet set.
class CareTemporalBuckets {
  const CareTemporalBuckets({
    required this.needsAttention,
    required this.today,
    required this.upcoming,
  });

  static const empty = CareTemporalBuckets(
    needsAttention: [],
    today: [],
    upcoming: [],
  );

  final List<HealthEntry> needsAttention;
  final List<HealthEntry> today;
  final List<HealthEntry> upcoming;

  bool get isEmpty =>
      needsAttention.isEmpty && today.isEmpty && upcoming.isEmpty;

  int get attentionCount => needsAttention.length + today.length;

  /// All visible care items, ordered needs-attention → today → upcoming, then by due date.
  List<HealthEntry> get all {
    final combined = [...needsAttention, ...today, ...upcoming];
    return List<HealthEntry>.unmodifiable(combined);
  }

  /// Entries in [group], stable-sorted by due date then id.
  List<HealthEntry> entriesIn(CareTemporalGroup group) {
    return switch (group) {
      CareTemporalGroup.needsAttention => needsAttention,
      CareTemporalGroup.today => today,
      CareTemporalGroup.upcoming => upcoming,
    };
  }

  /// The temporal group for [entryId], or null when not in any bucket.
  CareTemporalGroup? groupForEntryId(String entryId) {
    if (needsAttention.any((e) => e.id == entryId)) {
      return CareTemporalGroup.needsAttention;
    }
    if (today.any((e) => e.id == entryId)) {
      return CareTemporalGroup.today;
    }
    if (upcoming.any((e) => e.id == entryId)) {
      return CareTemporalGroup.upcoming;
    }
    return null;
  }
}
