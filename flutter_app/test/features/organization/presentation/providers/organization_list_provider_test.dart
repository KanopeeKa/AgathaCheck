import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  group('organizationListProvider', () {
    test('reads through the repository', () async {
      final repo = RecordingOrganizationRepository();
      final container = makeOrgProviderTestContainer(repo);
      addTearDown(container.dispose);

      final orgs = await container.read(organizationListProvider.future);
      expect(orgs, hasLength(1));
      expect(orgs.single.name, 'Clinic');
    });

    test(
      'createOrganization converts the form map to a domain entity',
      () async {
        final repo = RecordingOrganizationRepository();
        final container = makeOrgProviderTestContainer(repo);
        addTearDown(container.dispose);

        await container.read(organizationListProvider.future);
        await container
            .read(organizationListProvider.notifier)
            .createOrganization({'name': 'New Clinic', 'type': 'charity'});

        expect(repo.created, hasLength(1));
        expect(repo.created.single.name, 'New Clinic');
        expect(repo.created.single.type, OrganizationType.charity);
      },
    );
  });
}
