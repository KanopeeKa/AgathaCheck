import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';

void main() {
  group('OrgMemberRole.fromWire', () {
    test('maps current API roles', () {
      expect(OrgMemberRole.fromWire('super_admin'), OrgMemberRole.superAdmin);
      expect(OrgMemberRole.fromWire('admin'), OrgMemberRole.admin);
      expect(OrgMemberRole.fromWire('associate'), OrgMemberRole.associate);
    });

    test('maps legacy foster wire to associate', () {
      expect(OrgMemberRole.fromWire('foster'), OrgMemberRole.associate);
      expect(
        OrgMemberRole.fromWire('pending_foster'),
        OrgMemberRole.pendingAssociate,
      );
    });

    test('maps legacy roles', () {
      expect(OrgMemberRole.fromWire('super_user'), OrgMemberRole.superAdmin);
      expect(OrgMemberRole.fromWire('member'), OrgMemberRole.admin);
    });

    test('round-trips wire values', () {
      expect(OrgMemberRole.superAdmin.toWire(), 'super_admin');
      expect(OrgMemberRole.admin.toWire(), 'admin');
      expect(OrgMemberRole.associate.toWire(), 'associate');
      expect(OrgMemberRole.foster.toWire(), 'associate');
    });
  });
}
