class AuthUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? category;
  final String? bio;
  final String? photoUrl;
  final String? pinnedOrganizationId;
  final String? timezone;
  final String? weightUnit;
  final String? createdAt;
  final String? updatedAt;

  AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.category,
    this.bio,
    this.photoUrl,
    this.pinnedOrganizationId,
    this.timezone,
    this.weightUnit = 'kg',
    this.createdAt,
    this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      category: json['category']?.toString(),
      bio: json['bio']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      pinnedOrganizationId: json['pinned_organization_id']?.toString(),
      timezone: json['timezone']?.toString(),
      weightUnit: json['weight_unit']?.toString() ?? 'kg',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    return email;
  }

  String get initials {
    if ((firstName?.isNotEmpty ?? false) && (lastName?.isNotEmpty ?? false)) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    final dn = displayName;
    if (dn.length >= 2) return dn.substring(0, 2).toUpperCase();
    if (dn.isNotEmpty) return dn[0].toUpperCase();
    return '';
  }
}
