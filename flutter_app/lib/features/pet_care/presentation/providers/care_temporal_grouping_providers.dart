import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../pet_profile/domain/entities/care_status.dart';
import '../../domain/models/care_temporal_buckets.dart';
import '../../domain/services/care_temporal_grouping_service.dart';

final careTemporalGroupingServiceProvider =
    Provider<CareTemporalGroupingService>(
      (ref) => const CareTemporalGroupingService(),
    );

/// Current instant for care temporal grouping. Injectable so tests can pin
/// one instant across fixture, providers, and service expectations.
final careNowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Pet-scoped temporal buckets for the profile and All-care surfaces.
final petCareTemporalBucketsProvider =
    Provider.family<CareTemporalBuckets, String>((ref, petId) {
      final grouping = ref.watch(careTemporalGroupingServiceProvider);
      final entries =
          ref.watch(healthEntriesNotifierProvider).valueOrNull ?? const [];
      return grouping.bucketsForEntries(
        entries,
        petId: petId,
        now: ref.watch(careNowProvider),
      );
    });

/// Cross-pet temporal buckets for the Pet Care dashboard.
final dashboardCareTemporalBucketsProvider = Provider<CareTemporalBuckets>((
  ref,
) {
  final grouping = ref.watch(careTemporalGroupingServiceProvider);
  final entries =
      ref.watch(healthEntriesNotifierProvider).valueOrNull ?? const [];
  return grouping.bucketsForEntries(entries, now: ref.watch(careNowProvider));
});

/// Profile care-status summary derived from [petCareTemporalBucketsProvider].
final petCareStatusFromGroupingProvider =
    Provider.family<CareStatusSummary, String>((ref, petId) {
      final buckets = ref.watch(petCareTemporalBucketsProvider(petId));
      final grouping = ref.watch(careTemporalGroupingServiceProvider);
      final now = ref.watch(careNowProvider);
      final status = grouping.careStatusFromBuckets(buckets);
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
    });
