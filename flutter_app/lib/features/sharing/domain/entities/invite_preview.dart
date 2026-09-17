import 'pet_access.dart';

class InvitePreviewPet {
  const InvitePreviewPet({required this.petId, required this.petName});

  final String petId;
  final String petName;

  factory InvitePreviewPet.fromJson(Map<String, dynamic> json) {
    return InvitePreviewPet(
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name']?.toString() ?? '',
    );
  }
}

/// Public preview of a share invite (landing screen).
class InvitePreview {
  const InvitePreview({
    required this.inviteId,
    required this.code,
    required this.role,
    required this.status,
    this.expiresAt,
    this.inviterName = 'Someone',
    this.pets = const [],
  });

  final String inviteId;
  final String code;
  final PetAccessRole role;
  final String status;
  final String? expiresAt;
  final String inviterName;
  final List<InvitePreviewPet> pets;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  String get petNamesDisplay {
    final names = pets.map((p) => p.petName).where((n) => n.isNotEmpty);
    if (names.isEmpty) return '';
    return names.join(', ');
  }

  factory InvitePreview.fromJson(Map<String, dynamic> json) {
    final petsJson = json['pets'];
    final pets = petsJson is List
        ? petsJson
              .whereType<Map<String, dynamic>>()
              .map(InvitePreviewPet.fromJson)
              .toList()
        : <InvitePreviewPet>[];

    return InvitePreview(
      inviteId: json['invite_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      role: PetAccessRoleWire.fromWire(json['role']?.toString()),
      status: json['status']?.toString() ?? 'pending',
      expiresAt: json['expires_at']?.toString(),
      inviterName: json['inviter_name']?.toString() ?? 'Someone',
      pets: pets,
    );
  }
}

class InvitePreviewExpiredException implements Exception {}

class InvitePreviewNotFoundException implements Exception {}
