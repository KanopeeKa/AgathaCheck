import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';

void main() {
  group('OrgMemberRole.fromWire', () {
    test('maps current API roles', () {
      expect(OrgMemberRole.fromWire('super_admin'), OrgMemberRole.superAdmin);
      expect(OrgMemberRole.fromWire('admin'), OrgMemberRole.admin);
      expect(OrgMemberRole.fromWire('foster'), OrgMemberRole.foster);
    });

    test('maps legacy roles', () {
      expect(OrgMemberRole.fromWire('super_user'), OrgMemberRole.superAdmin);
      expect(OrgMemberRole.fromWire('member'), OrgMemberRole.admin);
    });

    test('round-trips wire values', () {
      expect(OrgMemberRole.superAdmin.toWire(), 'super_admin');
      expect(OrgMemberRole.admin.toWire(), 'admin');
      expect(OrgMemberRole.foster.toWire(), 'foster');
    });
  });
}
