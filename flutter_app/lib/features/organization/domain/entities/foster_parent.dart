import 'organization_member.dart';

/// A foster parent in the org directory — either an app member (admin/foster)
/// or an external contact without an account.
class FosterParent {
  const FosterParent({
    required this.id,
    required this.kind,
    this.userId,
    required this.displayName,
    this.email,
    this.phone,
    this.notes = '',
    this.role,
    this.photoUrl,
    this.activePetCount = 0,
  });

  final String id;
  final FosterParentKind kind;
  final String? userId;
  final String displayName;
  final String? email;
  final String? phone;
  final String notes;
  final OrgMemberRole? role;
  final String? photoUrl;
  final int activePetCount;

  bool get isMember => kind == FosterParentKind.member;
  bool get isExternal => kind == FosterParentKind.external;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory FosterParent.fromJson(Map<String, dynamic> json) {
    final roleWire = json['role']?.toString();
    return FosterParent(
      id: json['id']?.toString() ?? '',
      kind: FosterParentKind.fromWire(json['kind']?.toString() ?? 'member'),
      userId: json['user_id']?.toString(),
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      notes: json['notes']?.toString() ?? '',
      role: roleWire != null && roleWire.isNotEmpty
          ? OrgMemberRole.fromWire(roleWire)
          : null,
      photoUrl: json['photo_url']?.toString(),
      activePetCount: json['active_pet_count'] is int
          ? json['active_pet_count'] as int
          : int.tryParse(json['active_pet_count']?.toString() ?? '') ?? 0,
    );
  }
}

enum FosterParentKind {
  member,
  external;

  static FosterParentKind fromWire(String value) {
    switch (value) {
      case 'external':
        return FosterParentKind.external;
      default:
        return FosterParentKind.member;
    }
  }

  String toWire() => name;
}
