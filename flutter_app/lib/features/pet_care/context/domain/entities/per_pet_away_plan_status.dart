/// One-line status for an away plan pill or pet-page row (server §6).
class PerPetAwayPlanStatus {
  const PerPetAwayPlanStatus({
    required this.priority,
    required this.carerState,
    required this.reviewCareItemCount,
    this.copyKey,
    this.copyParams = const {},
  });

  final String priority;
  final String carerState;
  final int reviewCareItemCount;
  final String? copyKey;
  final Map<String, Object?> copyParams;
}
