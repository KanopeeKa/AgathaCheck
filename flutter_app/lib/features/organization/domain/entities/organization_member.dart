class OrganizationMember {
  const OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    this.invitedBy,
    this.inviteCode,
    this.inviteExpiresAt,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.photoUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int organizationId;
  final int userId;
  final OrgMemberRole role;
  final int? invitedBy;
  final String? inviteCode;
  final DateTime? inviteExpiresAt;
  final String firstName;
  final String lastName;
  final String email;
  final String photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    if (email.isNotEmpty) return email;
    return 'Unknown User';
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    final dn = displayName;
    if (dn.length >= 2) return dn.substring(0, 2).toUpperCase();
    if (dn.isNotEmpty) return dn[0].toUpperCase();
    return '?';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationMember && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum OrgMemberRole {
  superUser,
  member;

  String get label {
    switch (this) {
      case OrgMemberRole.superUser:
        return 'Super User';
      case OrgMemberRole.member:
        return 'Member';
    }
  }
}
