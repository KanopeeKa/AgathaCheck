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

  final String id;
  final String organizationId;
  final String userId;
  final OrgMemberRole role;
  final String? invitedBy;
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
      other is OrganizationMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum OrgMemberRole {
  superAdmin,
  admin,
  foster,
  associate,
  pendingSuperAdmin,
  pendingAdmin,
  pendingFoster,
  pendingAssociate;

  bool get isPending =>
      this == OrgMemberRole.pendingSuperAdmin ||
      this == OrgMemberRole.pendingAdmin ||
      this == OrgMemberRole.pendingFoster ||
      this == OrgMemberRole.pendingAssociate;

  bool get isSuperAdmin => this == OrgMemberRole.superAdmin;

  bool get isOrgAdmin =>
      this == OrgMemberRole.superAdmin || this == OrgMemberRole.admin;

  bool get isFoster => this == OrgMemberRole.foster;

  bool get isAssociate => this == OrgMemberRole.associate;

  /// API wire value for confirmed roles (not pending).
  String toWire() {
    switch (this) {
      case OrgMemberRole.superAdmin:
      case OrgMemberRole.pendingSuperAdmin:
        return 'super_admin';
      case OrgMemberRole.admin:
      case OrgMemberRole.pendingAdmin:
        return 'admin';
      case OrgMemberRole.foster:
      case OrgMemberRole.pendingFoster:
        return 'foster';
      case OrgMemberRole.associate:
      case OrgMemberRole.pendingAssociate:
        return 'associate';
    }
  }

  static OrgMemberRole fromWire(String value) {
    switch (value) {
      case 'super_admin':
      case 'super_user':
        return OrgMemberRole.superAdmin;
      case 'admin':
      case 'member':
        return OrgMemberRole.admin;
      case 'foster':
        return OrgMemberRole.foster;
      case 'associate':
        return OrgMemberRole.associate;
      case 'pending_super_admin':
      case 'pending_super_user':
        return OrgMemberRole.pendingSuperAdmin;
      case 'pending_admin':
      case 'pending_member':
        return OrgMemberRole.pendingAdmin;
      case 'pending_foster':
        return OrgMemberRole.pendingFoster;
      case 'pending_associate':
        return OrgMemberRole.pendingAssociate;
      default:
        return OrgMemberRole.admin;
    }
  }
}
