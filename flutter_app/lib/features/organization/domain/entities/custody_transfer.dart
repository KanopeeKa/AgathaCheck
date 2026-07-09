class CustodyTransfer {
  const CustodyTransfer({
    required this.id,
    required this.petId,
    this.petName,
    required this.transferKind,
    required this.status,
    this.fromOrgId,
    this.fromUserId,
    this.toOrgId,
    this.toUserId,
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String petId;
  final String? petName;
  final String transferKind;
  final String status;
  final String? fromOrgId;
  final String? fromUserId;
  final String? toOrgId;
  final String? toUserId;
  final String notes;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  bool get isIndividualGuardianship =>
      transferKind == 'individual_guardianship';

  bool get isOrgToOrg => transferKind == 'org_to_org';

  bool get isReturnToOrg => transferKind == 'return_to_org';
}
