/// Server-authored milestone moment eligible for per-user presentation (CP-4/6).
class CarePendingMoment {
  const CarePendingMoment({
    required this.petId,
    required this.bundleId,
    required this.primaryMilestoneType,
    required this.includesFirstCare,
    required this.achievedAt,
    required this.milestones,
  });

  final String petId;
  final String bundleId;
  final String primaryMilestoneType;
  final bool includesFirstCare;
  final DateTime achievedAt;
  final List<CareMilestoneSummary> milestones;
}

class CareMilestoneSummary {
  const CareMilestoneSummary({
    required this.id,
    required this.milestoneType,
    required this.careFamily,
    required this.achievedAt,
    required this.policyVersion,
    required this.bundleId,
  });

  final String id;
  final String milestoneType;
  final String? careFamily;
  final DateTime achievedAt;
  final String policyVersion;
  final String? bundleId;
}

class CarePendingMomentsResponse {
  const CarePendingMomentsResponse({
    required this.moments,
    required this.throttled,
  });

  final List<CarePendingMoment> moments;
  final bool throttled;
}
