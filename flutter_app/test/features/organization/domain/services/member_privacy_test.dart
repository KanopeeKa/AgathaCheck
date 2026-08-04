import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/member_privacy_settings.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/services/member_privacy.dart';

void main() {
  group('member_privacy service', () {
    test('foster role gets foster-manager phone default', () {
      final defaults = defaultPrivacyForRole(OrgMemberRole.foster);
      expect(
        defaults.phoneVisibility,
        ContactVisibility.adminsAndFosterManagers,
      );
    });

    test('admin card options exclude named floor violation', () {
      final options = cardVisibilityOptionsForRole(OrgMemberRole.admin);
      expect(options, contains(CardVisibility.admins));
      expect(options, isNot(contains(CardVisibility.named)));
    });

    test('settings round-trip wire json', () {
      const settings = MemberPrivacySettings(
        cardVisibility: CardVisibility.admins,
        grants: MemberPrivacyGrants(phone: ['user-2']),
      );
      final parsed = MemberPrivacySettings.fromJson(settings.toJson());
      expect(parsed.cardVisibility, CardVisibility.admins);
      expect(parsed.grants.phone, ['user-2']);
    });
  });
}
