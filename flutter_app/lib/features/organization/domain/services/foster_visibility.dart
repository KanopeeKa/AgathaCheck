import '../entities/foster_parent.dart';
import '../entities/foster_self_prefs.dart';
import '../entities/organization_member.dart';
import 'org_permissions.dart';

bool viewerHasFosterSelfCard(FosterParent parent, String? viewerUserId) {
  if (viewerUserId == null || parent.userId != viewerUserId) return false;
  return parent.isMember;
}

String fosterSortKey(FosterParent parent) {
  final parts = parent.displayName.trim().split(RegExp(r'\s+'));
  if (parts.length <= 1) return parts.first.toLowerCase();
  return parts.last.toLowerCase();
}

List<FosterParent> sortFosterParentsForViewer({
  required List<FosterParent> parents,
  required String? viewerUserId,
}) {
  FosterParent? self;
  final others = <FosterParent>[];

  for (final parent in parents) {
    if (viewerHasFosterSelfCard(parent, viewerUserId)) {
      self = parent;
    } else {
      others.add(parent);
    }
  }

  others.sort((a, b) {
    final last = fosterSortKey(a).compareTo(fosterSortKey(b));
    if (last != 0) return last;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  if (self == null) return others;
  return [self, ...others];
}

bool canManageFosters(OrgMemberRole? role, String orgId) {
  if (role == null) return false;
  return hasPermission(role, orgId, 'manage_fosters');
}

bool canManageFosteringSessions(OrgMemberRole? role, String orgId) {
  if (role == null) return false;
  return hasPermission(role, orgId, 'manage_fostering_sessions');
}

bool canManageOrgPets(OrgMemberRole? role, String orgId) {
  if (role == null) return false;
  return hasPermission(role, orgId, 'manage_pets');
}

String formatAddressForViewer(
  String address,
  FosterAddressVisibility visibility,
) {
  final raw = address.trim();
  if (raw.isEmpty || visibility == FosterAddressVisibility.hidden) return '';
  if (visibility == FosterAddressVisibility.full) return raw;
  final parts = raw.split(RegExp(r'[,\n]'));
  return parts.isNotEmpty ? parts.last.trim() : raw;
}
