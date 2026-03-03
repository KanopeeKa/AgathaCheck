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
    this.createdBy,
    this.role = 'member',
    this.memberCount = 0,
    this.petCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final OrganizationType type;
  final String email;
  final String phone;
  final String address;
  final String website;
  final String bio;
  final String photoUrl;
  final int? createdBy;
  final String role;
  final int memberCount;
  final int petCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSuperUser => role == 'super_user';

  Organization copyWith({
    int? id,
    String? name,
    OrganizationType? type,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? bio,
    String? photoUrl,
    int? createdBy,
    String? role,
    int? memberCount,
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
      createdBy: createdBy ?? this.createdBy,
      role: role ?? this.role,
      memberCount: memberCount ?? this.memberCount,
      petCount: petCount ?? this.petCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization && runtimeType == other.runtimeType && id == other.id;

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
