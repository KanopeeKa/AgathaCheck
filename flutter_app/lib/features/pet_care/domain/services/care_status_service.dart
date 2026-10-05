import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

/// Deterministic pet-level Care Status from tracked health entries.
class CareStatusService {
  const CareStatusService({CareTemporalGroupingService? grouping})
    : _grouping = grouping ?? const CareTemporalGroupingService();

  final CareTemporalGroupingService _grouping;

  CareStatusSummary evaluate({
    required String petId,
    required List<HealthEntry> entries,
    required DateTime now,
  }) {
    return _grouping.summarizePet(petId: petId, entries: entries, now: now);
  }
}

/// Maps legacy four-bucket urgency to three-state Care Status.
CareStatus careStatusFromLegacyUrgency({
  required bool hasOverdue,
  required bool hasDueToday,
  required bool hasUpcoming,
}) {
  return const CareTemporalGroupingService().careStatusFromFlags(
    hasNeedsAttention: hasOverdue,
    hasToday: hasDueToday,
    hasUpcoming: hasUpcoming,
  );
}
