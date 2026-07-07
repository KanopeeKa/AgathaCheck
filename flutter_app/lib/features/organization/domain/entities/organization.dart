import 'org_primary_contact.dart';

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.type,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.website = '',
    this.bio = '',
    this.photoUrl = '',
    this.logoUrl = '',
    this.createdBy,
    this.role = 'admin',
    this.memberCount = 0,
    this.externalCount = 0,
    this.petCount = 0,
    this.primaryContact,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final OrganizationType type;
  final String email;
  final String phone;
  final String address;
  final String website;
  final String bio;
  final String photoUrl;
  final String logoUrl;
  final String? createdBy;
  final String role;
  final int memberCount;
  final int externalCount;
  final int petCount;
  final OrgPrimaryContact? primaryContact;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSuperUser => role == 'super_admin' || role == 'super_user';

  bool get isOrgAdmin => isSuperUser || role == 'admin';

  bool get isFoster => role == 'foster';

  Organization copyWith({
    String? id,
    String? name,
    OrganizationType? type,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? bio,
    String? photoUrl,
    String? logoUrl,
    String? createdBy,
    String? role,
    int? memberCount,
    int? externalCount,
    int? petCount,
    OrgPrimaryContact? primaryContact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      createdBy: createdBy ?? this.createdBy,
      role: role ?? this.role,
      memberCount: memberCount ?? this.memberCount,
      externalCount: externalCount ?? this.externalCount,
      petCount: petCount ?? this.petCount,
      primaryContact: primaryContact ?? this.primaryContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum OrganizationType {
  professional,
  charity;

  String get label {
    switch (this) {
      case OrganizationType.professional:
        return 'Professional';
      case OrganizationType.charity:
        return 'Charity';
    }
  }
}
