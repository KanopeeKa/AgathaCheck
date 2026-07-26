import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/services/org_permissions.dart';

void main() {
  group('hasPermission (G0 defaults)', () {
    test('grants G0 keys to documented roles', () {
      for (final entry in g0PermissionDefaults.entries) {
        for (final role in entry.value) {
          expect(hasPermission(role, null, entry.key), isTrue);
        }
      }
    });

    test('manage_document_templates is super_admin only', () {
      expect(
        hasPermission(
          OrgMemberRole.superAdmin,
          null,
          'manage_document_templates',
        ),
        isTrue,
      );
      expect(
        hasPermission(OrgMemberRole.admin, null, 'manage_document_templates'),
        isFalse,
      );
    });

    test('returns false for unknown keys', () {
      expect(hasPermission(OrgMemberRole.admin, null, 'unknown_key'), isFalse);
    });
  });
}
