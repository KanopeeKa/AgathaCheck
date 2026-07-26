import '../entities/admin_contact_self_prefs.dart';
import '../entities/org_person.dart';
import '../entities/organization_member.dart';
import 'org_permissions.dart';

/// Members listed in the admin contacts directory (admins + super admins).
bool isAdminDirectoryContact(OrgPersonSummary person) {
  if (person.isExternal || person.isPending) return false;
  final role = person.role;
  return role != null && role.isOrgAdmin;
}

/// Viewer qualifies for a pinned self-card (admin/associate with a card).
bool viewerHasAdminSelfCard(OrgPersonSummary person, String? viewerUserId) {
  if (viewerUserId == null || person.userId != viewerUserId) return false;
  if (person.isExternal || person.isPending) return false;
  final role = person.role;
  if (role == null) return false;
  if (role.isOrgAdmin) return true;
  return role.isAssociate &&
      ((person.email?.isNotEmpty ?? false) || person.photoUrl != null);
}

String adminContactSortKey(OrgPersonSummary person) {
  final parts = person.displayName.trim().split(RegExp(r'\s+'));
  if (parts.length <= 1) {
    return parts.first.toLowerCase();
  }
  return parts.last.toLowerCase();
}

List<OrgPersonSummary> sortAdminContacts({
  required List<OrgPersonSummary> contacts,
  required String? viewerUserId,
}) {
  final admins = contacts.where(isAdminDirectoryContact).toList();
  OrgPersonSummary? self;
  final others = <OrgPersonSummary>[];

  for (final person in admins) {
    if (viewerHasAdminSelfCard(person, viewerUserId)) {
      self = person;
    } else {
      others.add(person);
    }
  }

  others.sort((a, b) {
    final last = adminContactSortKey(a).compareTo(adminContactSortKey(b));
    if (last != 0) return last;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  if (self == null) return others;
  return [self, ...others];
}

bool canViewerSeeAdminPhone({
  required OrgMemberRole? viewerRole,
  required OrgPersonSummary contact,
  required String? viewerUserId,
  required AdminPhoneVisibility phoneVisibility,
  required String phone,
}) {
  if (phone.trim().isEmpty) return false;
  if (contact.userId == viewerUserId) return true;
  if (phoneVisibility == AdminPhoneVisibility.nobody) return false;
  if (phoneVisibility == AdminPhoneVisibility.all) return true;
  if (phoneVisibility == AdminPhoneVisibility.admins) {
    return viewerRole?.isOrgAdmin ?? false;
  }
  if (phoneVisibility == AdminPhoneVisibility.fosters) {
    return viewerRole?.isFoster == true || (viewerRole?.isOrgAdmin ?? false);
  }
  return false;
}

bool canViewerMessageAdminContact({
  required OrgPersonSummary contact,
  required String? viewerUserId,
}) {
  if (contact.userId == viewerUserId) return false;
  if (contact.isPending) return false;
  return contact.email?.isNotEmpty ?? false;
}

bool canViewerCallAdminContact({
  required OrgMemberRole? viewerRole,
  required OrgPersonSummary contact,
  required String? viewerUserId,
  required AdminPhoneVisibility phoneVisibility,
  required String phone,
}) {
  return canViewerSeeAdminPhone(
    viewerRole: viewerRole,
    contact: contact,
    viewerUserId: viewerUserId,
    phoneVisibility: phoneVisibility,
    phone: phone,
  );
}

bool canManageAdminContacts(OrgMemberRole? role, String orgId) {
  if (role == null) return false;
  return hasPermission(role, orgId, 'manage_admin_contacts');
}

bool canEditOtherAdminContact(OrgMemberRole? role, String orgId) {
  if (role == null) return false;
  return hasPermission(role, orgId, 'manage_permissions');
}
