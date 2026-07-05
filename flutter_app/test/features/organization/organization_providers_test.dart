import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/archived_pet.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/repositories/organization_repository.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

import '../../helpers/fakes.dart';

/// Records calls so we can assert what the notifiers delegated to the repository.
class RecordingOrganizationRepository implements OrganizationRepository {
  final List<Organization> created = [];
  final List<Organization> updated = [];
  final List<String> deleted = [];
  final List<(String, String, OrgMemberRole)> roleChanges = [];

  @override
  Future<List<Organization>> getOrganizations(String token) async => [
        const Organization(id: 'org-1', name: 'Clinic', type: OrganizationType.charity),
      ];

  @override
  Future<Organization> createOrganization(Organization org, String token) async {
    created.add(org);
    return org;
  }

  @override
  Future<Organization> updateOrganization(Organization org, String token) async {
    updated.add(org);
    return org;
  }

  @override
  Future<void> deleteOrganization(String id, String token) async {
    deleted.add(id);
  }

  @override
  Future<void> updateMemberRole(
      String orgId, String userId, OrgMemberRole role, String token) async {
    roleChanges.add((orgId, userId, role));
  }

  // --- Unused-by-these-tests members: sensible defaults ---
  @override
  Future<Organization> getOrganization(String id, String token) async =>
      const Organization(id: 'x', name: 'x', type: OrganizationType.professional);
  @override
  Future<Organization> uploadPhoto(
          String id, Uint8List bytes, String filename, String token) async =>
      const Organization(id: 'x', name: 'x', type: OrganizationType.professional);
  @override
  Future<List<OrganizationMember>> getMembers(String orgId, String token) async => [];
  @override
  Future<Map<String, dynamic>> inviteByEmail(
          String orgId, String email, String role, String token) async =>
      {'success': true};
  @override
  Future<void> removeMember(String orgId, String userId, String token) async {}
  @override
  Future<void> leaveOrganization(String orgId, String token) async {}
  @override
  Future<List<Map<String, dynamic>>> getPendingInvites(String token) async => [];
  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId, String token) async =>
      {'organization_id': 'org-1'};
  @override
  Future<void> declineInvite(String inviteId, String token) async {}
  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
          String orgId, String token) async =>
      [];
  @override
  Future<Map<String, dynamic>> createOrganizationPet(
          String orgId, Map<String, dynamic> petJson, String token) async =>
      {};
  @override
  Future<void> transferPetToUser(String orgId, String petId,
      {required String recipientEmail,
      String transferType = 'adoption',
      String notes = '',
      required String token}) async {}
  @override
  Future<void> transferPetToOrg(String petId, String orgId,
      {String notes = '', required String token}) async {}
  @override
  Future<List<ArchivedPet>> getOrganizationArchivedPets(
          String orgId, String token) async =>
      [];
  @override
  Future<List<ArchivedPet>> getUserArchivedPets(String token) async => [];
  @override
  Future<List<Map<String, dynamic>>> getFamilyEvents(
          String token, String petId) async =>
      [];
  @override
  Future<Map<String, dynamic>> createFamilyEvent(
          String token, String petId, Map<String, dynamic> body) async =>
      {};
  @override
  Future<void> updateFamilyEvent(String token, String petId, String eventId,
      Map<String, dynamic> body) async {}
  @override
  Future<void> deleteFamilyEvent(
      String token, String petId, String eventId) async {}
  @override
  Future<List<FosterParent>> getFosterParents(String orgId, String token) async =>
      [];
  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async => [];
  @override
  Future<OrgPersonDetail> getPersonDetail(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String token,
  ) async =>
      OrgPersonDetail(
        id: 'member:$recordId',
        kind: kind,
        recordId: recordId,
        displayName: 'Test',
      );
  @override
  Future<OrgPersonDetail> updatePersonContact(
    String orgId,
    OrgPersonKind kind,
    String recordId, {
    String? fosterPhone,
    String? fosterAddress,
    String? adminNotes,
    String? displayName,
    String? email,
    required String token,
  }) async =>
      OrgPersonDetail(
        id: '${kind.wire}:$recordId',
        kind: kind,
        recordId: recordId,
        displayName: displayName ?? 'Test',
        fosterPhone: fosterPhone ?? '',
        fosterAddress: fosterAddress ?? '',
        adminNotes: adminNotes ?? '',
      );
  @override
  Future<FosterParent> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  }) async =>
      FosterParent(
        id: 'fp-1',
        kind: FosterParentKind.external,
        displayName: displayName,
        email: email,
      );
  @override
  Future<FosterParent> updateExternalFosterParent(
    String orgId,
    String fosterParentId, {
    required String displayName,
    String? email,
    String? phone,
    String notes = '',
    required String token,
  }) async =>
      FosterParent(
        id: fosterParentId,
        kind: FosterParentKind.external,
        displayName: displayName,
      );
  @override
  Future<void> deleteExternalFosterParent(
      String orgId, String fosterParentId, String token) async {}
  @override
  Future<PetFosterPlacementState> getPetPlacement(
          String orgId, String petId, String token) async =>
      const PetFosterPlacementState(status: 'not_in_foster');
  @override
  Future<FosterPlacement> startFosterPlacement(
    String orgId,
    String petId, {
    required String fosterUserId,
    DateTime? startDate,
    String notes = '',
    required String token,
  }) async =>
      FosterPlacement(
        id: 'fp-1',
        organizationId: orgId,
        petId: petId,
        fosterUserId: fosterUserId,
        status: 'pending',
      );
  @override
  Future<FosterPlacement> endFosterPlacement(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  }) async =>
      FosterPlacement(
        id: placementId,
        organizationId: orgId,
        petId: 'pet-1',
        fosterUserId: 'user-1',
        status: 'not_in_foster',
      );
  @override
  Future<FosterPlacement> startAdoption(
    String orgId,
    String placementId, {
    String adoptionConditions = '',
    required String token,
  }) async =>
      FosterPlacement(
        id: placementId,
        organizationId: orgId,
        petId: 'pet-1',
        fosterUserId: 'user-1',
        status: 'waiting_adoption_confirmation',
      );
  @override
  Future<FosterPlacement> completeAdoptionConditions(
    String orgId,
    String placementId, {
    required String token,
  }) async =>
      FosterPlacement(
        id: placementId,
        organizationId: orgId,
        petId: 'pet-1',
        fosterUserId: 'user-1',
        status: 'waiting_adoption_confirmation',
      );
  @override
  Future<FosterPlacement> cancelAdoption(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  }) async =>
      FosterPlacement(
        id: placementId,
        organizationId: orgId,
        petId: 'pet-1',
        fosterUserId: 'user-1',
        status: 'not_in_foster',
      );
  @override
  Future<FosterPlacement> directAdopt(
    String orgId,
    String petId, {
    required String fosterUserId,
    String adoptionConditions = '',
    String notes = '',
    required String token,
  }) async =>
      FosterPlacement(
        id: 'fp-direct',
        organizationId: orgId,
        petId: petId,
        fosterUserId: fosterUserId,
        status: 'waiting_adoption_confirmation',
      );
  @override
  Future<List<FosterPlacement>> getPetFosterHistory(
      String orgId, String petId, String token) async =>
      [];
}

ProviderContainer makeContainer(RecordingOrganizationRepository repo) {
  return ProviderContainer(overrides: [
    authProvider.overrideWith((ref) => FakeAuthNotifier()),
    organizationRepositoryProvider.overrideWithValue(repo),
  ]);
}

void main() {
  test('organizationListProvider reads through the repository', () async {
    final repo = RecordingOrganizationRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    final orgs = await container.read(organizationListProvider.future);
    expect(orgs, hasLength(1));
    expect(orgs.single.name, 'Clinic');
  });

  test('createOrganization converts the form map to a domain entity', () async {
    final repo = RecordingOrganizationRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(organizationListProvider.future);
    await container.read(organizationListProvider.notifier).createOrganization(
        {'name': 'New Clinic', 'type': 'charity'});

    expect(repo.created, hasLength(1));
    expect(repo.created.single.name, 'New Clinic');
    expect(repo.created.single.type, OrganizationType.charity);
  });

  test('updateMemberRole maps the role string to the domain enum', () async {
    final repo = RecordingOrganizationRepository();
    final container = makeContainer(repo);
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

  test('orgPeopleProvider.createExternal delegates to repository', () async {
    final repo = _FosterTrackingRepository();
    final container = makeContainer(repo);
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

  test('orgPeopleProvider.deleteExternal delegates to repository', () async {
    final repo = _FosterTrackingRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(orgPeopleProvider('org-1').future);
    await container
        .read(orgPeopleProvider('org-1').notifier)
        .deleteExternal('fp-1');

    expect(repo.deletedIds, ['fp-1']);
  });

  test('orgFosterParentsProvider.createExternal invalidates people provider', () async {
    final repo = _FosterTrackingRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(orgFosterParentsProvider('org-1').future);
    await container.read(orgPeopleProvider('org-1').future);
    repo.peopleFetchCount = 0;

    await container.read(orgFosterParentsProvider('org-1').notifier).createExternal(
          displayName: 'Off-app Parent',
          email: 'off@example.com',
          lawfulBasisConfirmed: true,
        );

    await container.read(orgPeopleProvider('org-1').future);
    expect(repo.createExternalCalls, hasLength(1));
    expect(repo.peopleFetchCount, greaterThan(0));
  });

  test('orgPersonDetailNotifier.updateContact delegates to repository', () async {
    final repo = _FosterTrackingRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    const key = (orgId: 'org-1', kind: OrgPersonKind.external, recordId: 'fp-1');
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
}

class _FosterTrackingRepository extends RecordingOrganizationRepository {
  final List<Map<String, dynamic>> createExternalCalls = [];
  final List<String> deletedIds = [];
  final List<Map<String, dynamic>> updateContactCalls = [];
  int peopleFetchCount = 0;

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async {
    peopleFetchCount += 1;
    return const [];
  }

  @override
  Future<FosterParent> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  }) async {
    createExternalCalls.add({
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'fosterAddress': fosterAddress,
      'notes': notes,
      'lawfulBasisConfirmed': lawfulBasisConfirmed,
    });
    return FosterParent(
      id: 'fp-new',
      kind: FosterParentKind.external,
      displayName: displayName,
      email: email,
    );
  }

  @override
  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    deletedIds.add(fosterParentId);
  }

  @override
  Future<OrgPersonDetail> updatePersonContact(
    String orgId,
    OrgPersonKind kind,
    String recordId, {
    String? fosterPhone,
    String? fosterAddress,
    String? adminNotes,
    String? displayName,
    String? email,
    required String token,
  }) async {
    updateContactCalls.add({
      'displayName': displayName,
      'email': email,
      'fosterPhone': fosterPhone,
      'fosterAddress': fosterAddress,
      'adminNotes': adminNotes,
    });
    return OrgPersonDetail(
      id: '${kind.wire}:$recordId',
      kind: kind,
      recordId: recordId,
      displayName: displayName ?? 'Updated',
      email: email,
      fosterPhone: fosterPhone ?? '',
      fosterAddress: fosterAddress ?? '',
      adminNotes: adminNotes ?? '',
    );
  }
}
