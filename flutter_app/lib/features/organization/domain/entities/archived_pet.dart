class ArchivedPet {
  const ArchivedPet({
    required this.id,
    this.organizationId,
    this.userId,
    required this.petId,
    required this.petName,
    this.species = '',
    this.pdfData = '',
    this.transferType = '',
    this.transferredToUserId,
    this.transferredToOrgId,
    this.notes = '',
    this.archivedAt,
    this.createdAt,
  });

  final int id;
  final int? organizationId;
  final int? userId;
  final String petId;
  final String petName;
  final String species;
  final String pdfData;
  final String transferType;
  final int? transferredToUserId;
  final int? transferredToOrgId;
  final String notes;
  final DateTime? archivedAt;
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchivedPet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
