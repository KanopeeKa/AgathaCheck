import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/services/org_permissions.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_roles_permissions/staged_permissions_controller.dart';

void main() {
  group('StagedPermissionsController', () {
    MemberPermissionBaseline baselineFor(OrgMemberRole role, Set<String> effective) {
      return MemberPermissionBaseline(
        role: role,
        effective: effective,
        overrides: effective,
      );
    }

    test('aggregateState returns indeterminate when users disagree', () {
      final controller = StagedPermissionsController(
        baselines: {
          'user-a': baselineFor(OrgMemberRole.associate, {'manage_pets'}),
          'user-b': baselineFor(OrgMemberRole.associate, {}),
        },
      );

      expect(
        controller.aggregateState('manage_pets', ['user-a', 'user-b']),
        TriState.indeterminate,
      );
    });

    test('applyRolePreset stages associate tier keys', () {
      final controller = StagedPermissionsController(
        baselines: {
          'user-a': baselineFor(
            OrgMemberRole.admin,
            g0PermissionKeysForRole(OrgMemberRole.admin),
          ),
        },
      );

      final next = controller.applyRolePreset(
        OrgMemberRole.associate,
        ['user-a'],
      );

      expect(
        next.effectiveForUser('user-a', 'manage_pets'),
        isFalse,
      );
      expect(
        next.effectiveForUser('user-a', 'view_org_pets'),
        isTrue,
      );
    });

    test('buildSaveChanges emits grant for staged on', () {
      final controller = StagedPermissionsController(
        baselines: {
          'user-a': baselineFor(OrgMemberRole.associate, {'view_org_pets'}),
        },
        staged: {'user-a|manage_pets': true},
      );

      final changes = controller.buildSaveChanges();
      expect(changes, hasLength(1));
      expect(changes.first['permission_key'], 'manage_pets');
      expect(changes.first['granted'], isTrue);
    });
  });
}
