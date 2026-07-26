import '../../domain/entities/org_primary_contact.dart';
import '../../domain/entities/organization.dart';

class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.type,
    super.email,
    super.phone,
    super.address,
    super.website,
    super.bio,
    super.photoUrl,
    super.logoUrl,
    super.town,
    super.administrativeArea,
    super.description,
    super.isDiscoverable,
    super.legalIdentifier1,
    super.legalIdentifier2,
    super.legalIdentifier3,
    super.publicProfileMetadata,
    super.createdBy,
    super.role,
    super.memberCount,
    super.externalCount,
    super.petCount,
    super.primaryContact,
    super.createdAt,
    super.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: _parseType(json['type']?.toString() ?? 'professional'),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
      town: json['town']?.toString() ?? '',
      administrativeArea: json['administrative_area']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isDiscoverable: json['is_discoverable'] != false,
      legalIdentifier1: json['legal_identifier_1']?.toString() ?? '',
      legalIdentifier2: json['legal_identifier_2']?.toString() ?? '',
      legalIdentifier3: json['legal_identifier_3']?.toString() ?? '',
      publicProfileMetadata: json['public_profile_metadata'] is Map
          ? Map<String, dynamic>.from(json['public_profile_metadata'] as Map)
          : const {},
      createdBy: json['created_by']?.toString(),
      role: json['role']?.toString() ?? 'member',
      memberCount: (json['member_count'] is int)
          ? json['member_count'] as int
          : int.tryParse(json['member_count']?.toString() ?? '0') ?? 0,
      externalCount: (json['external_count'] is int)
          ? json['external_count'] as int
          : int.tryParse(json['external_count']?.toString() ?? '0') ?? 0,
      petCount: (json['pet_count'] is int)
          ? json['pet_count'] as int
          : int.tryParse(json['pet_count']?.toString() ?? '0') ?? 0,
      primaryContact: json['primary_contact'] is Map
          ? OrgPrimaryContact.fromJson(
              Map<String, dynamic>.from(json['primary_contact'] as Map),
            )
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  factory OrganizationModel.fromEntity(Organization org) {
    return OrganizationModel(
      id: org.id,
      name: org.name,
      type: org.type,
      email: org.email,
      phone: org.phone,
      address: org.address,
      website: org.website,
      bio: org.bio,
      photoUrl: org.photoUrl,
      logoUrl: org.logoUrl,
      town: org.town,
      administrativeArea: org.administrativeArea,
      description: org.description,
      isDiscoverable: org.isDiscoverable,
      legalIdentifier1: org.legalIdentifier1,
      legalIdentifier2: org.legalIdentifier2,
      legalIdentifier3: org.legalIdentifier3,
      publicProfileMetadata: org.publicProfileMetadata,
      createdBy: org.createdBy,
      role: org.role,
      memberCount: org.memberCount,
      externalCount: org.externalCount,
      petCount: org.petCount,
      primaryContact: org.primaryContact,
      createdAt: org.createdAt,
      updatedAt: org.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type == OrganizationType.charity ? 'charity' : 'professional',
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'bio': bio,
      'photo_url': photoUrl,
      'logo_url': logoUrl,
      if (town.isNotEmpty) 'town': town,
      if (administrativeArea.isNotEmpty)
        'administrative_area': administrativeArea,
      if (description.isNotEmpty) 'description': description,
      'is_discoverable': isDiscoverable,
      if (legalIdentifier1.isNotEmpty) 'legal_identifier_1': legalIdentifier1,
      if (legalIdentifier2.isNotEmpty) 'legal_identifier_2': legalIdentifier2,
      if (legalIdentifier3.isNotEmpty) 'legal_identifier_3': legalIdentifier3,
      if (publicProfileMetadata.isNotEmpty)
        'public_profile_metadata': publicProfileMetadata,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  static OrganizationType _parseType(String value) {
    switch (value) {
      case 'charity':
        return OrganizationType.charity;
      case 'professional':
      default:
        return OrganizationType.professional;
    }
  }
}
