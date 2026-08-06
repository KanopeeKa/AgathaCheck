import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/services/org_people.dart';

void main() {
  group('sortOrgPeople', () {
    const self = OrgPersonSummary(
      id: 'member:self',
      kind: OrgPersonKind.member,
      recordId: 'self',
      userId: 'viewer',
      displayName: 'Zoe Foster',
      role: OrgMemberRole.foster,
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
      displayName: 'Bob Foster',
      role: OrgMemberRole.foster,
    );

    test('pins self first and sorts others by last name', () {
      final sorted = sortOrgPeople(
        people: [beta, self, alpha],
        viewerUserId: 'viewer',
      );

      expect(sorted.map((p) => p.recordId).toList(), ['self', 'a', 'b']);
    });
  });

  group('filterOrgPeopleByRoute', () {
    const admin = OrgPersonSummary(
      id: 'member:a',
      kind: OrgPersonKind.member,
      recordId: 'a',
      userId: 'a',
      displayName: 'Anna Admin',
      role: OrgMemberRole.admin,
    );
    const foster = OrgPersonSummary(
      id: 'member:f',
      kind: OrgPersonKind.member,
      recordId: 'f',
      userId: 'f',
      displayName: 'Frank Foster',
      role: OrgMemberRole.foster,
    );

    test('filter=admins keeps only admin wire roles', () {
      final filtered = filterOrgPeopleByRoute(
        [admin, foster],
        filter: 'admins',
      );

      expect(filtered, [admin]);
    });
  });

  group('filterOrgPeopleByName', () {
    const anna = OrgPersonSummary(
      id: 'member:a',
      kind: OrgPersonKind.member,
      recordId: 'a',
      displayName: 'Anna Admin',
      role: OrgMemberRole.admin,
    );
    const bob = OrgPersonSummary(
      id: 'member:b',
      kind: OrgPersonKind.member,
      recordId: 'b',
      displayName: 'Bob Foster',
      role: OrgMemberRole.foster,
    );

    test('matches display name case-insensitively', () {
      final filtered = filterOrgPeopleByName([anna, bob], 'anna');

      expect(filtered, [anna]);
    });
  });
}
