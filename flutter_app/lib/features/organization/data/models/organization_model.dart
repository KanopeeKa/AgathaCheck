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
    super.createdBy,
    super.role,
    super.memberCount,
    super.petCount,
    super.createdAt,
    super.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      type: _parseType(json['type']?.toString() ?? 'professional'),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      createdBy: json['created_by'] != null
          ? (json['created_by'] is int ? json['created_by'] as int : int.tryParse(json['created_by'].toString()))
          : null,
      role: json['role']?.toString() ?? 'member',
      memberCount: json['member_count'] is int ? json['member_count'] as int : int.tryParse(json['member_count']?.toString() ?? '0') ?? 0,
      petCount: json['pet_count'] is int ? json['pet_count'] as int : int.tryParse(json['pet_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
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
      createdBy: org.createdBy,
      role: org.role,
      memberCount: org.memberCount,
      petCount: org.petCount,
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
