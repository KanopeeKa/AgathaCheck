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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      organizationId: json['organization_id'] != null
          ? (json['organization_id'] is int ? json['organization_id'] as int : int.tryParse(json['organization_id'].toString()))
          : null,
      userId: json['user_id'] != null
          ? (json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id'].toString()))
          : null,
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name']?.toString() ?? '',
      species: json['species']?.toString() ?? '',
      pdfData: json['pdf_data']?.toString() ?? '',
      transferType: json['transfer_type']?.toString() ?? '',
      transferredToUserId: json['transferred_to_user_id'] != null
          ? (json['transferred_to_user_id'] is int
              ? json['transferred_to_user_id'] as int
              : int.tryParse(json['transferred_to_user_id'].toString()))
          : null,
      transferredToOrgId: json['transferred_to_org_id'] != null
          ? (json['transferred_to_org_id'] is int
              ? json['transferred_to_org_id'] as int
              : int.tryParse(json['transferred_to_org_id'].toString()))
          : null,
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
