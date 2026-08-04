import '../entities/member_privacy_settings.dart';
import '../entities/organization_member.dart';

List<CardVisibility> cardVisibilityOptionsForRole(OrgMemberRole? role) {
  final values = CardVisibility.values.toList();
  if (role == OrgMemberRole.admin || role == OrgMemberRole.superAdmin) {
    return values.where((v) => v != CardVisibility.named).toList();
  }
  return values;
}

List<ContactVisibility> phoneVisibilityOptionsForRole(OrgMemberRole? role) {
  if (role == OrgMemberRole.foster) {
    return ContactVisibility.values.toList();
  }
  return ContactVisibility.values
      .where((v) => v != ContactVisibility.adminsAndFosterManagers)
      .toList();
}

List<ContactVisibility> emailVisibilityOptionsForRole(OrgMemberRole? role) =>
    phoneVisibilityOptionsForRole(role);

List<AddressVisibility> addressVisibilityOptionsForRole(OrgMemberRole? role) =>
    AddressVisibility.values.toList();

MemberPrivacySettings defaultPrivacyForRole(OrgMemberRole? role) {
  final foster = role == OrgMemberRole.foster;
  return MemberPrivacySettings(
    phoneVisibility: foster
        ? ContactVisibility.adminsAndFosterManagers
        : ContactVisibility.adminsOrNamed,
    emailVisibility: foster
        ? ContactVisibility.adminsAndFosterManagers
        : ContactVisibility.adminsOrNamed,
  );
}
