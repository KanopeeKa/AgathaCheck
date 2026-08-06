import 'organization_member.dart';
import 'foster_placement.dart';
import 'foster_onboarding_step.dart';

/// Summary row in the organisation people directory.
class OrgPersonSummary {
  const OrgPersonSummary({
    required this.id,
    required this.kind,
    required this.recordId,
    this.userId,
    required this.displayName,
    this.email,
    this.role,
    this.photoUrl,
    this.isPending = false,
    this.activeFosterCount = 0,
    this.categoryRank = 3,
    this.fosterApprovalState,
    this.fosterNeedsAttention = false,
  });

  final String id;
  final OrgPersonKind kind;
  final String recordId;
  final String? userId;
  final String displayName;
  final String? email;
  final OrgMemberRole? role;
  final String? photoUrl;
  final bool isPending;
  final int activeFosterCount;
  final int categoryRank;
  final String? fosterApprovalState;
  final bool fosterNeedsAttention;

  bool get isExternal => kind == OrgPersonKind.external;
  bool get isMember => kind == OrgPersonKind.member;
  bool get isActiveFoster => activeFosterCount > 0;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String detailPath(String orgId) =>
      '/o/orgs/$orgId/people/${kind.wire}/$recordId';

  factory OrgPersonSummary.fromJson(Map<String, dynamic> json) {
    final roleWire = json['role']?.toString();
    return OrgPersonSummary(
      id: json['id']?.toString() ?? '',
      kind: OrgPersonKind.fromWire(json['kind']?.toString() ?? 'member'),
      recordId: json['record_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString(),
      role: roleWire != null && roleWire.isNotEmpty
          ? OrgMemberRole.fromWire(roleWire)
          : null,
      photoUrl: json['photo_url']?.toString(),
      isPending: json['is_pending'] == true,
      activeFosterCount: json['active_foster_count'] is int
          ? json['active_foster_count'] as int
          : int.tryParse(json['active_foster_count']?.toString() ?? '') ?? 0,
      categoryRank: json['category_rank'] is int
          ? json['category_rank'] as int
          : int.tryParse(json['category_rank']?.toString() ?? '') ?? 3,
      fosterApprovalState: json['foster_approval_state']?.toString(),
      fosterNeedsAttention: json['foster_needs_attention'] == true,
    );
  }
}

class OrgPersonPlacementPet {
  const OrgPersonPlacementPet({required this.placement, this.outcome});

  final FosterPlacement placement;
  final String? outcome;
}

/// Full person profile for the detail screen.
class OrgPersonDetail extends OrgPersonSummary {
  const OrgPersonDetail({
    required super.id,
    required super.kind,
    required super.recordId,
    super.userId,
    required super.displayName,
    super.email,
    super.role,
    super.photoUrl,
    super.isPending,
    super.activeFosterCount,
    super.categoryRank,
    super.fosterApprovalState,
    super.fosterNeedsAttention,
    this.fosterPhone = '',
    this.fosterAddress = '',
    this.adminNotes = '',
    this.currentPlacements = const [],
    this.pastPlacements = const [],
    this.fosterOnboarding,
  });

  final String fosterPhone;
  final String fosterAddress;
  final String adminNotes;
  final List<FosterPlacement> currentPlacements;
  final List<OrgPersonPlacementPet> pastPlacements;
  final FosterOnboardingStatus? fosterOnboarding;

  bool get hasFosterRelationship =>
      isExternal || fosterApprovalState != null || fosterNeedsAttention ||
      activeFosterCount > 0 || fosterOnboarding != null;

  factory OrgPersonDetail.fromJson(Map<String, dynamic> json) {
    final summary = OrgPersonSummary.fromJson(json);
    final current = (json['current_placements'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => FosterPlacement.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final past = (json['past_placements'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) {
          final map = Map<String, dynamic>.from(e);
          return OrgPersonPlacementPet(
            placement: FosterPlacement.fromJson(map),
            outcome: map['outcome']?.toString(),
          );
        })
        .toList();
    final fosterOnboardingJson = json['foster_onboarding'];
    final fosterOnboarding = fosterOnboardingJson is Map
        ? FosterOnboardingStatus.fromJson(Map<String, dynamic>.from(fosterOnboardingJson))
        : null;

    return OrgPersonDetail(
      id: summary.id,
      kind: summary.kind,
      recordId: summary.recordId,
      userId: summary.userId,
      displayName: summary.displayName,
      email: summary.email,
      role: summary.role,
      photoUrl: summary.photoUrl,
      isPending: summary.isPending,
      activeFosterCount: summary.activeFosterCount,
      categoryRank: summary.categoryRank,
      fosterApprovalState: summary.fosterApprovalState,
      fosterNeedsAttention: summary.fosterNeedsAttention,
      fosterPhone: json['foster_phone']?.toString() ?? '',
      fosterAddress: json['foster_address']?.toString() ?? '',
      adminNotes: json['admin_notes']?.toString() ?? '',
      currentPlacements: current,
      pastPlacements: past,
      fosterOnboarding: fosterOnboarding,
    );
  }
}

enum OrgPersonKind {
  member,
  external;

  String get wire => name;

  static OrgPersonKind fromWire(String value) {
    switch (value) {
      case 'external':
        return OrgPersonKind.external;
      default:
        return OrgPersonKind.member;
    }
  }
}
