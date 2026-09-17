import 'pet_access.dart';

/// A pending email invitation to share one or more pets.
class ShareInvite {
  const ShareInvite({
    required this.id,
    required this.inviteeEmail,
    this.inviteeUserId,
    required this.role,
    required this.code,
    required this.status,
    this.createdAt,
    this.expiresAt,
    this.petId,
  });

  final String id;
  final String inviteeEmail;
  final String? inviteeUserId;
  final PetAccessRole role;
  final String code;
  final String status;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  /// When loaded from aggregate access API, the invite is scoped to one pet.
  final String? petId;

  bool get isPending => status == 'pending';

  factory ShareInvite.fromJson(Map<String, dynamic> json) {
    return ShareInvite(
      id: json['id']?.toString() ?? '',
      inviteeEmail: json['invitee_email']?.toString() ?? '',
      inviteeUserId: json['invitee_user_id']?.toString(),
      role: PetAccessRoleWire.fromWire(json['role']?.toString()),
      code: json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      petId: json['pet_id']?.toString(),
    );
  }
}
