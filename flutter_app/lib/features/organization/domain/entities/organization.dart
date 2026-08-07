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
    this.town = '',
    this.administrativeArea = '',
    this.description = '',
    this.isDiscoverable = true,
    this.legalIdentifier1 = '',
    this.legalIdentifier2 = '',
    this.legalIdentifier3 = '',
    this.publicProfileMetadata = const {},
    this.createdBy,
    this.role = 'admin',
    this.isFosterParent = false,
    this.memberCount = 0,
    this.externalCount = 0,
    this.petCount = 0,
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
  final String town;
  final String administrativeArea;
  final String description;
  final bool isDiscoverable;
  final String legalIdentifier1;
  final String legalIdentifier2;
  final String legalIdentifier3;
  final Map<String, dynamic> publicProfileMetadata;
  final String? createdBy;
  final String role;
  final bool isFosterParent;
  final int memberCount;
  final int externalCount;
  final int petCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSuperUser => role == 'super_admin' || role == 'super_user';

  bool get isOrgAdmin => isSuperUser || role == 'admin';

  bool get isFoster => role == 'foster' || isFosterParent;

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
    String? town,
    String? administrativeArea,
    String? description,
    bool? isDiscoverable,
    String? legalIdentifier1,
    String? legalIdentifier2,
    String? legalIdentifier3,
    Map<String, dynamic>? publicProfileMetadata,
    String? createdBy,
    String? role,
    bool? isFosterParent,
    int? memberCount,
    int? externalCount,
    int? petCount,
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
      town: town ?? this.town,
      administrativeArea: administrativeArea ?? this.administrativeArea,
      description: description ?? this.description,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      legalIdentifier1: legalIdentifier1 ?? this.legalIdentifier1,
      legalIdentifier2: legalIdentifier2 ?? this.legalIdentifier2,
      legalIdentifier3: legalIdentifier3 ?? this.legalIdentifier3,
      publicProfileMetadata:
          publicProfileMetadata ?? this.publicProfileMetadata,
      createdBy: createdBy ?? this.createdBy,
      role: role ?? this.role,
      isFosterParent: isFosterParent ?? this.isFosterParent,
      memberCount: memberCount ?? this.memberCount,
      externalCount: externalCount ?? this.externalCount,
      petCount: petCount ?? this.petCount,
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
