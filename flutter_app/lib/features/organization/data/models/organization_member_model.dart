import '../../domain/entities/organization_member.dart';

class OrganizationMemberModel extends OrganizationMember {
  const OrganizationMemberModel({
    required super.id,
    required super.organizationId,
    required super.userId,
    required super.role,
    super.invitedBy,
    super.inviteCode,
    super.inviteExpiresAt,
    super.firstName,
    super.lastName,
    super.email,
    super.photoUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory OrganizationMemberModel.fromJson(Map<String, dynamic> json) {
    return OrganizationMemberModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: OrgMemberRole.fromWire(json['role']?.toString() ?? 'admin'),
      invitedBy: json['invited_by']?.toString(),
      inviteCode: json['invite_code']?.toString(),
      inviteExpiresAt: json['invite_expires_at'] != null
          ? DateTime.tryParse(json['invite_expires_at'].toString())
          : null,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'role': role.toWire(),
      if (invitedBy != null) 'invited_by': invitedBy,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (inviteExpiresAt != null)
        'invite_expires_at': inviteExpiresAt!.toIso8601String(),
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
