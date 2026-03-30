import '../../domain/entities/archived_pet.dart';

class ArchivedPetModel extends ArchivedPet {
  const ArchivedPetModel({
    required super.id,
    super.organizationId,
    super.userId,
    required super.petId,
    required super.petName,
    super.species,
    super.pdfData,
    super.transferType,
    super.transferredToUserId,
    super.transferredToOrgId,
    super.notes,
    super.archivedAt,
    super.createdAt,
  });

  factory ArchivedPetModel.fromJson(Map<String, dynamic> json) {
    return ArchivedPetModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      userId: json['user_id']?.toString(),
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name']?.toString() ?? '',
      species: json['species']?.toString() ?? '',
      pdfData: json['pdf_data']?.toString() ?? '',
      transferType: json['transfer_type']?.toString() ?? '',
      transferredToUserId: json['transferred_to_user_id']?.toString(),
      transferredToOrgId: json['transferred_to_org_id']?.toString(),
      notes: json['notes']?.toString() ?? '',
      archivedAt: json['archived_at'] != null ? DateTime.tryParse(json['archived_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (userId != null) 'user_id': userId,
      'pet_id': petId,
      'pet_name': petName,
      'species': species,
      'pdf_data': pdfData,
      'transfer_type': transferType,
      if (transferredToUserId != null) 'transferred_to_user_id': transferredToUserId,
      if (transferredToOrgId != null) 'transferred_to_org_id': transferredToOrgId,
      'notes': notes,
      if (archivedAt != null) 'archived_at': archivedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
