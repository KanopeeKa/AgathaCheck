/// Pet-level care-management status (not a health diagnosis).
enum CareStatus {
  allSet,
  worthACheck,
  timeToFollowUp,
}

/// Deterministic evaluation result for a pet's tracked care.
class CareStatusSummary {
  const CareStatusSummary({
    required this.status,
    required this.evaluatedAt,
    this.primaryCareEntryId,
    this.contributingEntryIds = const [],
  });

  final CareStatus status;
  final String? primaryCareEntryId;
  final List<String> contributingEntryIds;
  final DateTime evaluatedAt;
}
