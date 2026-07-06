import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  group('orgMembersProvider', () {
    test('updateMemberRole maps the role string to the domain enum', () async {
      final repo = RecordingOrganizationRepository();
      final container = makeOrgProviderTestContainer(repo);
      addTearDown(container.dispose);

      await container.read(orgMembersProvider('org-1').future);
      await container
          .read(orgMembersProvider('org-1').notifier)
          .updateMemberRole('user-9', 'super_admin');

      expect(repo.roleChanges, hasLength(1));
      expect(repo.roleChanges.single.$1, 'org-1');
      expect(repo.roleChanges.single.$2, 'user-9');
      expect(repo.roleChanges.single.$3, OrgMemberRole.superAdmin);
    });
  });
}
