/// Server-authored guardian safeguard for a pet (Phase E).
class CareSafeguard {
  const CareSafeguard({
    required this.id,
    required this.petId,
    required this.safeguardType,
    required this.safeguardKey,
    required this.status,
    required this.policyVersion,
    required this.copyKey,
    required this.evidence,
    this.dismissedAt,
  });

  final String id;
  final String petId;
  final String safeguardType;
  final String safeguardKey;
  final String status;
  final String policyVersion;
  final String copyKey;
  final Map<String, dynamic> evidence;
  final DateTime? dismissedAt;

  bool get isActive => status == 'active';
}
