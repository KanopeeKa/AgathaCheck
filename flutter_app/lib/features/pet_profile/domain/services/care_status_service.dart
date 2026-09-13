import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../pet_care/domain/services/care_temporal_grouping_service.dart';
import '../entities/care_status.dart';

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
