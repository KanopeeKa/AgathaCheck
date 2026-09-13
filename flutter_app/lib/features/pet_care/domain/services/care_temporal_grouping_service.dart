import '../../../../core/utils/calendar_date.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../../../health_tracking/domain/entities/health_occurrence.dart';
import '../../../health_tracking/domain/occurrence_missed.dart';
import '../../../pet_profile/domain/entities/care_status.dart';
import '../care_temporal_group.dart';
import '../models/care_temporal_buckets.dart';

/// Single authority for care temporal grouping across profile, All care, and dashboard.
///
/// Entry grouping uses [HealthEntry.nextDueDate] and [HealthEntry.remindDaysBefore]
/// (server-shaped list data). Occurrence grouping uses open-occurrence calendar fields
/// and the shared missed predicate.
class CareTemporalGroupingService {
  const CareTemporalGroupingService();

  /// Returns null when the entry is completed, has no due date, or is outside the
  /// reminder horizon.
  CareTemporalGroup? groupForEntry(HealthEntry entry, DateTime now) {
    if (!_entryAffectsGrouping(entry, now)) return null;

    final today = calendarDateOnly(now);
    final dueDay = calendarDateOnly(entry.nextDueDate!);
    if (dueDay.isBefore(today)) return CareTemporalGroup.needsAttention;
    if (dueDay == today) return CareTemporalGroup.today;

    final daysUntilDue = dueDay.difference(today).inDays;
    if (daysUntilDue <= entry.remindDaysBefore) {
      return CareTemporalGroup.upcoming;
    }
    return null;
  }

  /// Pending occurrences only. Future non-today occurrences map to [CareTemporalGroup.upcoming].
  CareTemporalGroup? groupForOccurrence(HealthOccurrence occ, DateTime now) {
    if (!occ.isPending) return null;
    if (isOccurrenceMissed(occ, now)) return CareTemporalGroup.needsAttention;

    final today = calendarDateOnly(now);
    final dueDay = calendarDateOnly(occ.scheduledDate);
    if (dueDay == today) return CareTemporalGroup.today;
    return CareTemporalGroup.upcoming;
  }

  CareTemporalBuckets bucketsForEntries(
    List<HealthEntry> entries, {
    String? petId,
    Set<String>? petIds,
    required DateTime now,
  }) {
    final filtered = entries.where((entry) {
      if (petId != null && entry.petId != petId) return false;
      if (petIds != null && !petIds.contains(entry.petId)) return false;
      return true;
    });

    final needsAttention = <HealthEntry>[];
    final today = <HealthEntry>[];
    final upcoming = <HealthEntry>[];

    for (final entry in filtered) {
      final group = groupForEntry(entry, now);
      if (group == null) continue;
      switch (group) {
        case CareTemporalGroup.needsAttention:
          needsAttention.add(entry);
        case CareTemporalGroup.today:
          today.add(entry);
        case CareTemporalGroup.upcoming:
          upcoming.add(entry);
      }
    }

    void sortBucket(List<HealthEntry> bucket) {
      bucket.sort((a, b) {
        final ad = a.nextDueDate ?? DateTime(9999);
        final bd = b.nextDueDate ?? DateTime(9999);
        final byDate = ad.compareTo(bd);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    }

    sortBucket(needsAttention);
    sortBucket(today);
    sortBucket(upcoming);

    return CareTemporalBuckets(
      needsAttention: List<HealthEntry>.unmodifiable(needsAttention),
      today: List<HealthEntry>.unmodifiable(today),
      upcoming: List<HealthEntry>.unmodifiable(upcoming),
    );
  }

  CareStatus careStatusFromBuckets(CareTemporalBuckets buckets) {
    return careStatusFromFlags(
      hasNeedsAttention: buckets.needsAttention.isNotEmpty,
      hasToday: buckets.today.isNotEmpty,
      hasUpcoming: buckets.upcoming.isNotEmpty,
    );
  }

  CareStatus careStatusFromFlags({
    required bool hasNeedsAttention,
    required bool hasToday,
    required bool hasUpcoming,
  }) {
    if (hasNeedsAttention) return CareStatus.timeToFollowUp;
    if (hasToday || hasUpcoming) return CareStatus.worthACheck;
    return CareStatus.allSet;
  }

  CareStatusSummary summarizePet({
    required String petId,
    required List<HealthEntry> entries,
    required DateTime now,
  }) {
    final buckets = bucketsForEntries(entries, petId: petId, now: now);
    final status = careStatusFromBuckets(buckets);
    final contributing = switch (status) {
      CareStatus.timeToFollowUp =>
        buckets.needsAttention.map((entry) => entry.id).toList(),
      CareStatus.worthACheck => [
        ...buckets.today.map((entry) => entry.id),
        ...buckets.upcoming.map((entry) => entry.id),
      ],
      CareStatus.allSet => <String>[],
    };
    return CareStatusSummary(
      status: status,
      primaryCareEntryId: contributing.isEmpty ? null : contributing.first,
      contributingEntryIds: contributing,
      evaluatedAt: now,
    );
  }

  bool _entryAffectsGrouping(HealthEntry entry, DateTime now) {
    if (entry.status == 'completed') return false;
    if (entry.isCompleted) return false;
    if (isHealthEntrySeriesClosedAt(entry, now)) return false;
    if (entry.nextDueDate == null) return false;
    return true;
  }
}
