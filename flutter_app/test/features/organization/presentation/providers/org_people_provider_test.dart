import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  group('orgPeopleProvider', () {
    test('createExternal delegates to repository', () async {
      final repo = FosterTrackingOrganizationRepository();
      final container = makeOrgProviderTestContainer(repo);
      addTearDown(container.dispose);

      await container.read(orgPeopleProvider('org-1').future);
      await container.read(orgPeopleProvider('org-1').notifier).createExternal(
            displayName: 'Off-app Parent',
            email: 'off@example.com',
            phone: '555',
            fosterAddress: '1 Main St',
            notes: 'Notes',
            lawfulBasisConfirmed: true,
          );

      expect(repo.createExternalCalls, hasLength(1));
      expect(repo.createExternalCalls.single['displayName'], 'Off-app Parent');
      expect(repo.createExternalCalls.single['email'], 'off@example.com');
    });

    test('deleteExternal delegates to repository', () async {
      final repo = FosterTrackingOrganizationRepository();
      final container = makeOrgProviderTestContainer(repo);
      addTearDown(container.dispose);

      await container.read(orgPeopleProvider('org-1').future);
      await container
          .read(orgPeopleProvider('org-1').notifier)
          .deleteExternal('fp-1');

      expect(repo.deletedIds, ['fp-1']);
    });
  });

  group('orgFosterParentsProvider', () {
    test('createExternal invalidates people provider', () async {
      final repo = FosterTrackingOrganizationRepository();
      final container = makeOrgProviderTestContainer(repo);
      addTearDown(container.dispose);

      await container.read(orgFosterParentsProvider('org-1').future);
      await container.read(orgPeopleProvider('org-1').future);
      repo.peopleFetchCount = 0;

      await container
          .read(orgFosterParentsProvider('org-1').notifier)
          .createExternal(
            displayName: 'Off-app Parent',
            email: 'off@example.com',
            lawfulBasisConfirmed: true,
          );

      await container.read(orgPeopleProvider('org-1').future);
      expect(repo.createExternalCalls, hasLength(1));
      expect(repo.peopleFetchCount, greaterThan(0));
    });
  });

  group('orgPersonDetailProvider', () {
    test('updateContact delegates to repository', () async {
      final repo = FosterTrackingOrganizationRepository();
      final container = makeOrgProviderTestContainer(repo);
      addTearDown(container.dispose);

      const key = (
        orgId: 'org-1',
        kind: OrgPersonKind.external,
        recordId: 'fp-1',
      );
      await container.read(orgPersonDetailProvider(key).future);
      await container.read(orgPersonDetailProvider(key).notifier).updateContact(
            fosterPhone: '555',
            fosterAddress: 'Addr',
            adminNotes: 'Notes',
            displayName: 'Updated',
            email: 'updated@example.com',
          );

      expect(repo.updateContactCalls, hasLength(1));
      expect(repo.updateContactCalls.single['displayName'], 'Updated');
      expect(repo.updateContactCalls.single['email'], 'updated@example.com');
    });
  });
}
