import 'organization_member.dart';

class FosterParentAssignedPet {
  const FosterParentAssignedPet({
    required this.petId,
    required this.petName,
    required this.status,
  });

  final String petId;
  final String petName;
  final String status;

  factory FosterParentAssignedPet.fromJson(Map<String, dynamic> json) {
    return FosterParentAssignedPet(
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

enum FosterApprovalState {
  underReview,
  approved,
  declined,
  archived;

  static FosterApprovalState fromWire(String value) {
    switch (value) {
      case 'under_review':
        return FosterApprovalState.underReview;
      case 'declined':
        return FosterApprovalState.declined;
      case 'archived':
        return FosterApprovalState.archived;
      case 'approved':
      default:
        return FosterApprovalState.approved;
    }
  }

  String toWire() {
    switch (this) {
      case FosterApprovalState.underReview:
        return 'under_review';
      case FosterApprovalState.declined:
        return 'declined';
      case FosterApprovalState.archived:
        return 'archived';
      case FosterApprovalState.approved:
        return 'approved';
    }
  }
}

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
    this.activePets = const [],
    this.approvalState = FosterApprovalState.approved,
    this.creationSource,
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
  final List<FosterParentAssignedPet> activePets;
  final FosterApprovalState approvalState;
  final String? creationSource;

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
      activePets: (json['active_pets'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (e) =>
                FosterParentAssignedPet.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      approvalState: FosterApprovalState.fromWire(
        json['approval_state']?.toString() ?? 'approved',
      ),
      creationSource: json['creation_source']?.toString(),
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
