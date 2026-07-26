import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/services/admin_contacts.dart';

void main() {
  group('sortAdminContacts', () {
    const self = OrgPersonSummary(
      id: 'member:self',
      kind: OrgPersonKind.member,
      recordId: 'self',
      userId: 'viewer',
      displayName: 'Zoe Admin',
      role: OrgMemberRole.admin,
    );
    const alpha = OrgPersonSummary(
      id: 'member:a',
      kind: OrgPersonKind.member,
      recordId: 'a',
      userId: 'a',
      displayName: 'Anna Admin',
      role: OrgMemberRole.admin,
    );
    const beta = OrgPersonSummary(
      id: 'member:b',
      kind: OrgPersonKind.member,
      recordId: 'b',
      userId: 'b',
      displayName: 'Bob Admin',
      role: OrgMemberRole.superAdmin,
    );
    const foster = OrgPersonSummary(
      id: 'member:f',
      kind: OrgPersonKind.member,
      recordId: 'f',
      userId: 'f',
      displayName: 'Frank Foster',
      role: OrgMemberRole.foster,
    );

    test('pins self-card first and sorts others by last name', () {
      final sorted = sortAdminContacts(
        contacts: [beta, foster, self, alpha],
        viewerUserId: 'viewer',
      );

      expect(sorted.map((p) => p.recordId).toList(), ['self', 'a', 'b']);
    });

    test('isAdminDirectoryContact excludes fosters and externals', () {
      expect(isAdminDirectoryContact(alpha), isTrue);
      expect(isAdminDirectoryContact(foster), isFalse);
    });
  });

  group('canManageAdminContacts', () {
    test('admin role can manage admin contacts', () {
      expect(canManageAdminContacts(OrgMemberRole.admin, 'org-1'), isTrue);
    });

    test('foster role cannot manage admin contacts', () {
      expect(canManageAdminContacts(OrgMemberRole.foster, 'org-1'), isFalse);
    });
  });
}
