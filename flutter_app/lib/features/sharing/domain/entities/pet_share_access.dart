import 'pet_access.dart';
import 'share_invite.dart';

/// Access list and pending invites for a single pet.
class PetShareAccess {
  const PetShareAccess({
    required this.petId,
    this.access = const [],
    this.pendingInvites = const [],
  });

  final String petId;
  final List<PetAccess> access;
  final List<ShareInvite> pendingInvites;

  factory PetShareAccess.fromJson(Map<String, dynamic> json) {
    final accessJson = json['access'];
    final invitesJson = json['pending_invites'];

    return PetShareAccess(
      petId: json['pet_id']?.toString() ?? '',
      access: accessJson is List
          ? accessJson.whereType<Map<String, dynamic>>().map((row) {
              // Aggregate API nests user under `user`; map to PetAccessModel shape.
              return PetAccess(
                id: row['id']?.toString() ?? '',
                petId:
                    row['pet_id']?.toString() ??
                    json['pet_id']?.toString() ??
                    '',
                userId: row['user_id']?.toString() ?? '',
                role: PetAccessRoleWire.fromWire(row['role']?.toString()),
                invitedBy: row['invited_by']?.toString(),
                createdAt:
                    DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                    DateTime.now(),
                user: row['user'] is Map<String, dynamic>
                    ? PetAccessUser(
                        firstName: row['user']['first_name']?.toString() ?? '',
                        lastName: row['user']['last_name']?.toString() ?? '',
                        category:
                            row['user']['category']?.toString() ?? 'pet_carer',
                        bio: row['user']['bio']?.toString() ?? '',
                        photoUrl: row['user']['photo_url']?.toString() ?? '',
                      )
                    : null,
              );
            }).toList()
          : const [],
      pendingInvites: invitesJson is List
          ? invitesJson
                .whereType<Map<String, dynamic>>()
                .map(ShareInvite.fromJson)
                .toList()
          : const [],
    );
  }
}

class CreateShareInviteResult {
  const CreateShareInviteResult({
    required this.inviteId,
    required this.code,
    this.includedPetIds = const [],
    this.excluded = const [],
  });

  final String inviteId;
  final String code;
  final List<String> includedPetIds;
  final List<Map<String, dynamic>> excluded;

  factory CreateShareInviteResult.fromJson(Map<String, dynamic> json) {
    return CreateShareInviteResult(
      inviteId: json['invite_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      includedPetIds:
          (json['included_pet_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      excluded:
          (json['excluded'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
    );
  }
}

class AcceptShareInviteResult {
  const AcceptShareInviteResult({
    required this.inviteId,
    required this.status,
    this.accessRole,
    this.petIds = const [],
  });

  final String inviteId;
  final String status;
  final PetAccessRole? accessRole;
  final List<String> petIds;

  factory AcceptShareInviteResult.fromJson(Map<String, dynamic> json) {
    return AcceptShareInviteResult(
      inviteId: json['invite_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      accessRole: json['access_role'] != null
          ? PetAccessRoleWire.fromWire(json['access_role']?.toString())
          : null,
      petIds:
          (json['pet_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
